package com.coffeeandpower.android.maps;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

import android.app.IntentService;
import android.content.ContentProviderOperation;
import android.content.ContentProviderOperation.Builder;
import android.content.ContentValues;
import android.content.Intent;
import android.content.OperationApplicationException;
import android.database.Cursor;
import android.net.Uri;
import android.os.RemoteException;
import android.util.Log;

import com.google.android.maps.GeoPoint;

public class CPMapSyncService extends IntentService {
	public static String sUriString = 
			"content://com.coffeeandpower.android.maps.provider/";
	static final String sAuthority = "com.coffeeandpower.android.maps.provider";
	public CPMapSyncService() {
		super("CPMapSyncService");
	}

	@Override
	protected void onHandleIntent(Intent arg0) {
		Uri mapboundsUri = Uri.parse(sUriString + "mapbounds");

		String[] mapboundsProjection = 
			{
				"sw_lat",
				"sw_lon",
				"ne_lat",
				"ne_lon",
				"zoom"
			};
		String selection = null;
		Cursor boundsCursor = getContentResolver().
				query(mapboundsUri, mapboundsProjection, selection, null, null);

		// TODO make sure got rows before dereferencing
		boundsCursor.moveToNext();
		long sw_lat = boundsCursor.getLong(boundsCursor.getColumnIndex("sw_lat"));
		long sw_lon = boundsCursor.getLong(boundsCursor.getColumnIndex("sw_lon"));
		long ne_lat = boundsCursor.getLong(boundsCursor.getColumnIndex("ne_lat"));
		long ne_lon = boundsCursor.getLong(boundsCursor.getColumnIndex("ne_lon"));
		int zoom = boundsCursor.getInt(boundsCursor.getColumnIndex("zoom"));

		GeoPoint sw = new GeoPoint((int)sw_lat,(int)sw_lon);
		GeoPoint ne = new GeoPoint((int)ne_lat,(int)ne_lon);
		CPQuadTree[][] tiles = CPQuadTree.getTilesForBounds(sw, ne, zoom);


		Uri syncMapUri = Uri.parse(sUriString + "sync_map");
		String[] syncMapProjection = 
			{
				"_ID",
				"point_type",
				"sw_lat",
				"sw_lon",
				"zoom",
				"quad_index",
				"sync_started",
				"sync_completed",
				"visible",
				"status"
			};
		String syncMapSelection = " zoom = ? AND quad_index = ? ";

		Map<Long, CPQuadTree> tilesCurrent = new HashMap<Long,CPQuadTree>();
		Map<Long, CPQuadTree> tilesOld = new HashMap<Long,CPQuadTree>();
		Map<Long, CPQuadTree> tilesNew = new HashMap<Long,CPQuadTree>();

		for(int y = 0; y < tiles.length ; y++){
			for(int x = 0; x < tiles[y].length; x++)
			{
				CPQuadTree tile = tiles[y][x];
				String tileZoom = String.valueOf(zoom);
				Long tileIndex = tile.getIndex();
				String tileIndexString = String.valueOf(tileIndex);
				tilesCurrent.put(tileIndex, tile);

				String[] args = 
					{
						tileZoom,
						tileIndexString
					};
				Cursor tileCachedCursor = getContentResolver().query(
						syncMapUri, syncMapProjection, 
						syncMapSelection, args, null);
//				Log.i("db", "cursor size:" + tileCachedCursor.getCount());
				if(tileCachedCursor.getCount() < 1)
				{ //TODO also check if last sync too old
					tilesNew.put(tileIndex, tile);
				}
				else if(tileCachedCursor.getCount() > 1)
				{
					Log.e("db","duplicate tile cache record for zoom:" + 
							String.valueOf(tileZoom) + " index:" + tileIndexString); 
				}

			}// for x
		}// for y
		//TODO create status codes for db status column

		String visibleMapSelection = "visible = ?";
		String visibleArgs[] = { String.valueOf(1) };
		Cursor oldVisible = getContentResolver().query(
				syncMapUri, syncMapProjection, 
				visibleMapSelection, visibleArgs, null);

		while(oldVisible.moveToNext())
		{
			Long visibleIndex = oldVisible.getLong(oldVisible.getColumnIndex("quad_index"));
			int visibleLat = oldVisible.getInt(oldVisible.getColumnIndex("sw_lat"));
			int visibleLon = oldVisible.getInt(oldVisible.getColumnIndex("sw_lon"));
			tilesOld.put(visibleIndex, new CPQuadTree(visibleLat,visibleLon));
		}
		Set<Long> create, updateInvisible, updateVisible;
		create = tilesNew.keySet();
		Log.i("set","setsize create:" + String.valueOf(create.size()));
		updateVisible = tilesCurrent.keySet();
		updateVisible.removeAll(tilesOld.keySet());
		Log.i("set","setsize updateVisible:" + String.valueOf(updateVisible.size()));
		updateInvisible = tilesOld.keySet();
		updateInvisible.removeAll(tilesCurrent.keySet());
		Log.i("set","setsize updateInvisible:" + String.valueOf(updateInvisible.size()));
		// db transaction list
		ArrayList<ContentProviderOperation> transOps = 
				new ArrayList<ContentProviderOperation>(
						create.size() + updateVisible.size() + updateInvisible.size());
		ArrayList<GeoPoint[]> insertTiles = new ArrayList<GeoPoint[]>();
		Iterator<Long> createItr = create.iterator();
		Iterator<Long> updateVisibleItr = updateVisible.iterator();
		Iterator<Long> updateInvisibleItr = updateInvisible.iterator();
		while(createItr.hasNext())
		{
			Builder op = ContentProviderOperation.newInsert(syncMapUri);
			Log.i("create","adding insert db opperation");
			Long createIndex = createItr.next();
			Long nextIndex = CPQuadTree.getNextTileIndex(createIndex, zoom);
			CPQuadTree newTile = tilesNew.get(createIndex);
			ContentValues insertValues = new ContentValues();
			insertValues.put("point_type", "checkin");
			GeoPoint tileSw = newTile.getPoint();
			GeoPoint tileNe = newTile.getNorthEast().getPoint();
			insertValues.put("sw_lat", tileSw.getLatitudeE6());
			insertValues.put("sw_lon", tileSw.getLongitudeE6());
			insertValues.put("zoom",zoom);
			insertValues.put("quad_index", createIndex);
			insertValues.put("next_index", nextIndex);
			insertValues.put("sync_started", System.currentTimeMillis());
			insertValues.put("visible", 1);
			insertTiles.add(new GeoPoint[]{tileSw,tileNe});
			op.withValues(insertValues);
			transOps.add(op.build());
		}
		while(updateInvisibleItr.hasNext())
		{
			Builder op = ContentProviderOperation.newUpdate(syncMapUri);
//			Log.i("update","updateInvisible");
			Long updateIndex = updateInvisibleItr.next();
			CPQuadTree updateTile = tilesOld.get(updateIndex); //TODO here only for testing
			CPQuadTree.getNextTileIndex(updateTile.getIndex(), zoom);//TODO here only for testing
			ContentValues updateValues = new ContentValues();
			String updateInvisibleSelection = " zoom = ? AND quad_index = ? ";
			String[] updateInvisibleArgs = { String.valueOf(zoom), String.valueOf(updateIndex) };
			updateValues.put("visible", 0);
			op.withSelection(updateInvisibleSelection, updateInvisibleArgs);
			op.withValues(updateValues);
			transOps.add(op.build());
		}
		while(updateVisibleItr.hasNext())
		{
			Builder op = ContentProviderOperation.newUpdate(syncMapUri);
//			Log.i("update","updateVisible");
			Long updateIndex = updateVisibleItr.next();
			ContentValues updateValues = new ContentValues();
			String updateVisibleSelection = " zoom = ? AND quad_index = ? ";
			String[] updateVisibleArgs = { String.valueOf(zoom), String.valueOf(updateIndex) };
			updateValues.put("visible", 1);
			op.withSelection(updateVisibleSelection, updateVisibleArgs);
			op.withValues(updateValues);
			transOps.add(op.build());
		}
		//TODO loop updates in a transaction too

		try {
			getContentResolver().applyBatch(sAuthority, transOps);
		} catch (RemoteException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (OperationApplicationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}


		//TODO loop fetch after tiles visible updated
		Iterator<GeoPoint[]> insertTilesItr = insertTiles.iterator();
		while(insertTilesItr.hasNext())
		{
			GeoPoint[] bounds = insertTilesItr.next();
			CPApi.getCheckedInBoundsOverTime(this,bounds[0], bounds[1]);
		}		

	}

}
