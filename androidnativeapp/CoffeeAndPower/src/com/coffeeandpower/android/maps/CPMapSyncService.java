package com.coffeeandpower.android.maps;

import android.app.IntentService;
import android.content.ContentValues;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;

import com.google.android.maps.GeoPoint;

public class CPMapSyncService extends IntentService {
	private static String sUriString = 
			"content://com.coffeeandpower.android.maps.provider/";

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
		
		
		//TODO check if already have data for tile
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
				"status"
			};
		String syncMapSelection = "zoom = ? AND quad_index = ?";
		
		for(int y = 0; y < tiles.length ; y++){
			for(int x = 0; x < tiles[y].length; x++)
			{
				CPQuadTree tile = tiles[y][x];
				String[] args = 
					{
						String.valueOf(zoom),
						String.valueOf(tile.getIndex())
					};
				Cursor tileCachedCursor = getContentResolver().query(
					syncMapUri, syncMapProjection, 
					syncMapSelection, args, null);
				if(tileCachedCursor.getCount() < 1)
				{ //TODO also check if last sync too old
					ContentValues insertValues = new ContentValues();
					insertValues.put("point_type", "checkin");
					GeoPoint tileSw = tile.getPoint();
					GeoPoint tileNe = tile.getNorthEast().getPoint();
					insertValues.put("sw_lat", tileSw.getLatitudeE6());
					insertValues.put("sw_lon", tileSw.getLongitudeE6());
					insertValues.put("zoom",zoom);
					insertValues.put("quad_index", tile.getIndex());
					insertValues.put("sync_started", System.currentTimeMillis());
					getContentResolver().insert(syncMapUri, insertValues);
					CPApi.getCheckedInBoundsOverTime(tileSw, tileNe);
				}
			}
		}
		//TODO if don't have tile data mark db as fetching
		// so that we only try to fetch once and start fetch
		

	}

}
