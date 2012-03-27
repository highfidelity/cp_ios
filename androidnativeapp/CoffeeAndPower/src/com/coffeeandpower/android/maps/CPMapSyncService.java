package com.coffeeandpower.android.maps;

import android.app.IntentService;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;

import com.google.android.maps.GeoPoint;

public class CPMapSyncService extends IntentService {

	public CPMapSyncService() {
		super("CPMapSyncService");
	}

	@Override
	protected void onHandleIntent(Intent arg0) {
		Uri mapbounds =
		Uri.parse("content://com.coffeeandpower.android.maps.provider/mapbounds");
		
		String[] projection = 
			{
				"sw_lat",
				"sw_lon",
				"ne_lat",
				"ne_lon",
				"zoom"
			};
		String selection = null;
		String[] selectionArgs = {""};
		Cursor boundsCursor = getContentResolver().
		query(mapbounds, projection, selection, null, null);

		// TODO make sure got rows before dereferencing
		boundsCursor.moveToNext();
		long sw_lat = boundsCursor.getLong(boundsCursor.getColumnIndex("sw_lat"));
		long sw_lon = boundsCursor.getLong(boundsCursor.getColumnIndex("sw_lon"));
		long ne_lat = boundsCursor.getLong(boundsCursor.getColumnIndex("ne_lat"));
		long ne_lon = boundsCursor.getLong(boundsCursor.getColumnIndex("ne_lon"));
		int zoom = boundsCursor.getInt(boundsCursor.getColumnIndex("zoom"));
		//TODO get tile list from quadtree
		
		GeoPoint sw = new GeoPoint((int)sw_lat,(int)sw_lon);
		GeoPoint ne = new GeoPoint((int)ne_lat,(int)ne_lon);
		CPQuadTree[][] tiles = CPQuadTree.getTilesForBounds(sw, ne, zoom);
		
		//TODO check if already have data for tile
		
		//TODO if don't have tile data mark db as fetching
		// so that we only try to fetch once and start fetch
		

	}

}
