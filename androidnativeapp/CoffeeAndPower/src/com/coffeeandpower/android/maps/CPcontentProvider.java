package com.coffeeandpower.android.maps;

import java.io.File;
import java.util.ArrayList;

import android.content.ContentProvider;
import android.content.ContentProviderOperation;
import android.content.ContentProviderResult;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.OperationApplicationException;
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
	static final int DATABASE_VERSION = 2;
	static String DATABASE_NAME = "coffeeandpower.db";

	// Map bounds might get updated 60 times a second during a map pan
	// Persist onPause instead of writing flash constantly
	// Couldn't figure out an easier way to get the data so using a
	// ram based SQLite database
	private MemoryDatabaseHelper mMOpenHelper;
	private MainDatabaseHelper   mOpenHelper;

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

	private static final String SQL_CREATE_TABLE_SYNC_MAP =
			"CREATE TABLE " +
					"sync_map " +
					"(" +
					" _ID INTEGER PRIMARY KEY, " +
					" point_type integer, " + // check in / other foreign key?
					" sw_lat INTEGER NOT NULL, " +
					" sw_lon INTEGER NOT NULL, " +
					" zoom   INTEGER NOT NULL, " +
					" quad_index  INTEGER NOT NULL, " +
					" sync_started INTEGER, " + // unix date
					" sync_completed INTEGER, " +
					" visible INTEGER, " + // a tile that overlaps the current map bounds
					" status INTEGER );";
	
	private static final String SQL_CREATE_TABLE_POINTS = 
			"CREATE TABLE " +
					"points " +
					"(" +
					" _ID INTEGER PRIMARY KEY, " +
					" quad_index INTEGER NOT NULL, " +
					" lat INTEGER NOT NULL, " +
					" lon INTEGER NOT NULL " +
					");";
					
	private static final String SQL_CREATE_TABLE_CHECKINS = 
			"CREATE TABLE " +
					"checkins " +
					"(" +
					" _ID INTEGER PRIMARY KEY, " +
					" point_id INTEGER, " +
				    " checked_in INTEGER, " +
				    " checkin_count INTEGER, " +
				    " checkin_id INTEGER, " +
				    " filename TEXT, " +
				    " foursquare TEXT, " +
				    " id INTEGER, " +
				    " major_job_category TEXT, " +
				    " minor_job_category TEXT, " +
				    " nickname TEXT, " +
				    " photo INTEGER, " +
				    " skills TEXT, " +
				    " status_text TEXT, " +
				    " venue_name TEXT, " +
					"FOREIGN KEY(point_id) REFERENCES points(_ID)" +
				    ");";
	
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
			db.execSQL("DROP TABLE IF EXISTS mapbounds;");
			onCreate(db);
		}		
	}

	private static class MainDatabaseHelper extends SQLiteOpenHelper{

		public MainDatabaseHelper(Context context, String name,
				CursorFactory factory, int version) {
			super(context, name, factory, version);
		}

		@Override
		public void onCreate(SQLiteDatabase db) {
			db.execSQL(SQL_CREATE_TABLE_SYNC_MAP);
			db.execSQL(SQL_CREATE_TABLE_POINTS);
			db.execSQL(SQL_CREATE_TABLE_CHECKINS);
		}

		@Override
		public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
			db.execSQL("DROP TABLE IF EXISTS sync_map;");
			db.execSQL("DROP TABLE IF EXISTS points;");
			db.execSQL("DROP TABLE IF EXISTS checkins;");
			onCreate(db);
		}

	}
//TODO change this stuff to be part of a contract class?
	private static final int MAPBOUNDS = 1;
	private static final int MAPBOUNDS_ID = 2;
	private static final int SYNC_MAP = 3;
	private static final int SYNC_MAP_ID = 4;
	private static final int POINTS = 5;
	private static final int POINTS_ID = 6;
	private static final int CHECKINS = 7;
	private static final int CHECKINS_ID = 8;

	private static final UriMatcher sUriMatcher = 
			new UriMatcher(UriMatcher.NO_MATCH);
	static
	{
		sUriMatcher.addURI(PROVIDER_AUTH, "mapbounds", MAPBOUNDS);
		sUriMatcher.addURI(PROVIDER_AUTH, "mapbounds/#", MAPBOUNDS_ID);
		sUriMatcher.addURI(PROVIDER_AUTH, "sync_map", SYNC_MAP);
		sUriMatcher.addURI(PROVIDER_AUTH, "sync_map/#", SYNC_MAP_ID);
		sUriMatcher.addURI(PROVIDER_AUTH, "points", POINTS);
		sUriMatcher.addURI(PROVIDER_AUTH, "points/#", POINTS_ID);
		sUriMatcher.addURI(PROVIDER_AUTH, "checkins", CHECKINS);
		sUriMatcher.addURI(PROVIDER_AUTH, "checkins/#", CHECKINS_ID);
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
		case SYNC_MAP:
			return "vnd.android.cursor.dir/sync_map";
		case SYNC_MAP_ID:
			return "vnd.android.cursor.item/sync_map";
		case POINTS:
			return "vnd.android.cursor.dir/points";
		case POINTS_ID:
			return "vnd.android.cursor.item/points";
		case CHECKINS:
			return "vnd.android.cursor.dir/checkins";
		case CHECKINS_ID:
			return "vnd.android.cursor.item/checkins";
		default:
			return null;
		}
	}

	@Override
	public Uri insert(Uri uri, ContentValues values) {
		final SQLiteDatabase memdb,db;
		String table;
		int match = sUriMatcher.match(uri);
		switch(match)
		{
		case MAPBOUNDS:
			memdb = mMOpenHelper.getReadableDatabase();
			return Uri.parse("content://" + PROVIDER_AUTH + "/mapbounds/" +
					memdb.insert("mapbounds", null, values));
		case SYNC_MAP:
			table = "sync_map";
			break;
		case POINTS:
			table = "points";
			break;
		case CHECKINS:
			table = "checkins";
			break;
		default:
			return null;
		}
		db = mOpenHelper.getWritableDatabase();
		Log.i("db","inserting values");
		return Uri.parse("content://" + PROVIDER_AUTH + "/" + table + "/" +
		db.insert(table, null, values));
	}

	@Override
	public boolean onCreate() {
		mMOpenHelper = new MemoryDatabaseHelper(getContext());
		//FIXME opening database on external storage because I couldn't get access
		// permissions to the main one from developer tools.
		File externalDir = this.getContext().getExternalFilesDir(null);
		String dbFile = externalDir.getAbsolutePath() + "/" + DATABASE_NAME;
		Log.i("db","external db location:" + dbFile);
		mOpenHelper = new MainDatabaseHelper(getContext(),dbFile,
				null,DATABASE_VERSION);
		return true;
	}

	@Override
	public Cursor query(Uri uri, String[] projection, String selection,
			String[] selectionArgs, String sortOrder) {
		final SQLiteDatabase memdb,db;
		String table;
		int match = sUriMatcher.match(uri);
		switch(match)
		{
		case MAPBOUNDS:
		case MAPBOUNDS_ID:
			memdb = mMOpenHelper.getReadableDatabase();
			return memdb.query("mapbounds", projection, 
					selection, selectionArgs, null, null, null);
		case SYNC_MAP:
			table = "sync_map";
			break;
		case SYNC_MAP_ID:
		case POINTS:
		case POINTS_ID:
		case CHECKINS:
		case CHECKINS_ID:
		default:
			return null;
		}
		db = mOpenHelper.getReadableDatabase();
//		Log.i("db", "querying database");
		return db.query(table, projection, 
				selection, selectionArgs, null, null, null);
	}

	@Override
	public int update(Uri uri, ContentValues values, String selection,
			String[] selectionArgs) {
		final SQLiteDatabase memdb, db;
		String table;
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
			memdb = mMOpenHelper.getWritableDatabase();
			int updated = memdb.update("mapbounds", values, selection, null);
			Intent mapSync = new Intent(getContext(),CPMapSyncService.class);
			this.getContext().startService(mapSync);
			return updated;
		case SYNC_MAP:
			table = "sync_map";
			break;
		case SYNC_MAP_ID:
			table = "sync_map";
			selection = selection + " _ID = " + uri.getLastPathSegment();
			break;
		case POINTS:
			table = "points";
			break;			
		case POINTS_ID:
			table = "points";
			selection = selection + " _ID = " + uri.getLastPathSegment();
			break;
		case CHECKINS:
			table = "checkins";
			break;
		case CHECKINS_ID:
			table = "checkins";
			selection = selection + " _ID = " + uri.getLastPathSegment();
			break;
		default:
			return 0;
		}
		db = mOpenHelper.getWritableDatabase();
		int updated = db.update(table, values, selection, selectionArgs);
		return updated;
	}

	@Override
	public ContentProviderResult[] applyBatch(
			ArrayList<ContentProviderOperation> operations)
			throws OperationApplicationException {
		final SQLiteDatabase db = this.mOpenHelper.getWritableDatabase();
		db.beginTransaction();
		try {
			final int opSize = operations.size();
			final ContentProviderResult[] results = new ContentProviderResult[opSize];
			for(int n = 0; n < opSize; n++)
			{
				results[n] = operations.get(n).apply(this, results, n);
			}
			db.setTransactionSuccessful();
			return results;
		}
		
		finally {
			db.endTransaction();
		}
	}

}
