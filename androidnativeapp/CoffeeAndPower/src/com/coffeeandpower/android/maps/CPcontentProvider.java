package com.coffeeandpower.android.maps;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.UriMatcher;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteDatabase.CursorFactory;
import android.database.sqlite.SQLiteOpenHelper;
import android.net.Uri;
import android.util.Log;

public class CPcontentProvider extends ContentProvider {

	static final String PROVIDER_AUTH = 
			"com.coffeeandpower.android.maps.provider";

	// Map bounds might get updated 60 times a second during a map pan
	// Persist onPause instead of writing flash constantly
	// Couldn't figure out an easier way to get the data so using a
	// ram based SQLite database
	private MemoryDatabaseHelper mMOpenHelper;
	private MainDatabaseHelper   mOpenHelper;

	private SQLiteDatabase mMdb;
	private SQLiteDatabase mDb;

	private static final String SQL_CREATE_MEMDB = 
			"CREATE TABLE " +
					"mapbounds " +
					"(" +
					" _ID INTEGER PRIMARY KEY, " +
					" sw_lat INTEGER NOT NULL, " +
					" sw_lon INTEGER NOT NULL, " +
					" ne_lat INTEGER NOT NULL, " +
					" ne_lon INTEGER NOT NULL, " +
					" zoom   INTEGER NOT NULL );";

	private static class MemoryDatabaseHelper extends SQLiteOpenHelper{

		public MemoryDatabaseHelper(Context context) {
			super(context, null, null, 1);
		}

		@Override
		public void onCreate(SQLiteDatabase db) {
			Log.i("memdb","creating database");
			db.execSQL(SQL_CREATE_MEMDB);			
		}

		@Override
		public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
			// TODO Auto-generated method stub

		}		
	}

	private static class MainDatabaseHelper extends SQLiteOpenHelper{

		public MainDatabaseHelper(Context context, String name,
				CursorFactory factory, int version) {
			super(context, name, factory, version);
			// TODO Auto-generated constructor stub
		}

		@Override
		public void onCreate(SQLiteDatabase db) {
			// TODO Auto-generated method stub

		}

		@Override
		public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
			// TODO Auto-generated method stub

		}

	}

	private static final int MAPBOUNDS = 1;
	private static final int MAPBOUNDS_ID = 2;

	private static final UriMatcher sUriMatcher = 
			new UriMatcher(UriMatcher.NO_MATCH);
	static
	{
		sUriMatcher.addURI(PROVIDER_AUTH, "mapbounds", MAPBOUNDS);
		sUriMatcher.addURI(PROVIDER_AUTH, "mapbounds/#", MAPBOUNDS_ID);
	}
	@Override
	public int delete(Uri arg0, String arg1, String[] arg2) {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public String getType(Uri uri) {
		int match = sUriMatcher.match(uri);
		switch(match)
		{
		case MAPBOUNDS:
			return "vnd.android.cursor.dir/mapbounds";
		case MAPBOUNDS_ID:
			return "vnd.android.cursor.item/mapbounds";
		default:
			return null;
		}
	}

	@Override
	public Uri insert(Uri uri, ContentValues values) {
		// TODO Auto-generated method stub
		int match = sUriMatcher.match(uri);
		switch(match)
		{
		case MAPBOUNDS:
		case MAPBOUNDS_ID:
			mMdb = mMOpenHelper.getReadableDatabase();
			return Uri.parse("content://" + PROVIDER_AUTH + "/mapbounds/" +
					mMdb.insert("mapbounds", null, values));
		default:
			return null;
		}
	}

	@Override
	public boolean onCreate() {
		// TODO create persistent db helper too
		mMOpenHelper = new MemoryDatabaseHelper(getContext());
		return true;
	}

	@Override
	public Cursor query(Uri uri, String[] projection, String selection,
			String[] selectionArgs, String sortOrder) {
		int match = sUriMatcher.match(uri);
		switch(match)
		{
		case MAPBOUNDS:
		case MAPBOUNDS_ID:
			mMdb = mMOpenHelper.getReadableDatabase();
			return mMdb.query("mapbounds", projection, 
					selection, selectionArgs, null, null, null);
		default:
			return null;
		}
	}

	@Override
	public int update(Uri uri, ContentValues values, String selection,
			String[] selectionArgs) {
		// TODO Auto-generated method stub
		int match = sUriMatcher.match(uri);
		switch(match)
		{
		case MAPBOUNDS:
		case MAPBOUNDS_ID:
//			long sw_lat = values.getAsLong("sw_lat");
//			long sw_lon = values.getAsLong("sw_lon");
//			long sw_quadindex = genQuadtreeIndexPoint(sw_lat, sw_lon);
//			long sw_quadindex = new CPQuadTree(new GeoPoint((int)sw_lat,(int)sw_lon)).getIndex();
//			CPQuadTree sw_quad = new CPQuadTree(new GeoPoint((int)sw_lat,(int)sw_lon));
//			GeoPoint sw_point = new GeoPoint((int)sw_lat,(int)sw_lon);
//			sw_quad.logZoomLevels();
//			long ne_lat = values.getAsLong("ne_lat");
//			long ne_lon = values.getAsLong("ne_lon");
//			long ne_quadindex = genQuadtreeIndexPoint(ne_lat, ne_lon);
//			GeoPoint ne_point = new GeoPoint((int)ne_lat,(int)ne_lon);
//			int zoom = values.getAsInteger("zoom");
//			CPQuadTree.getTilesForBounds(sw_point, ne_point, zoom);
//			getQuadtreeLatLon(ne_quadindex);
//			Log.i("mMdb_update","sw_lat:" + values.getAsString("sw_lat"));
//			Log.i("mMdb_update","sw_lon:" + values.getAsString("sw_lon"));
//			Log.i("mMdb_update","ne_lat:" + values.getAsString("ne_lat"));
//			Log.i("mMdb_update","ne_lon:" + values.getAsString("ne_lon"));
//			Log.i("quadtree","sw:" + String.valueOf(sw_quadindex));
//			Log.i("quadtree","ne:" + String.valueOf(ne_quadindex));
			selection = selection + " _ID = " + uri.getLastPathSegment();
			mMdb = mMOpenHelper.getWritableDatabase();
			int updated = mMdb.update("mapbounds", values, selection, null);
			Intent mapSync = new Intent(getContext(),CPMapSyncService.class);
			this.getContext().startService(mapSync);
			return updated;
		default:
			return 0;
		}
	}

}
