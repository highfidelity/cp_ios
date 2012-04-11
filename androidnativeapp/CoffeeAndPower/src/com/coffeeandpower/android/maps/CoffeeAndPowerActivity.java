package com.coffeeandpower.android.maps;

import java.util.HashSet;
import java.util.Set;

import android.database.Cursor;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.LoaderManager;
import android.support.v4.content.CursorLoader;
import android.support.v4.content.Loader;
import android.util.Log;

import com.google.android.maps.GeoPoint;
import com.google.android.maps.MapController;
import com.google.android.maps.OverlayItem;

/**
 * The main map GUI.
 * Android Activity objects represent individual "screens" that users interact with.
 * The system maintains a stack of these as users move to new activities and return from them.
 * 
 * @author Melinda Green
 */
public class CoffeeAndPowerActivity extends FragmentActivity implements 
LoaderManager.LoaderCallbacks<Cursor> {
	private final static int CITY_LEVEL = 14;
	private MapAnnotations mAnnotations; // All glyphs and other overlays.
	private CPMapView mMapView;
	private Set<int[]> mVisiblePointsSet;
	private static String sUriString = 
			"content://com.coffeeandpower.android.maps.provider/";
	Uri sVisiblePointsUri = Uri.parse(sUriString + "visible");
	
	// Just a static array of predefined annotations for prototyping.
	// This will grow into a dynamically managed list.
	private static OverlayItem mOverlayItems[] = {
		new OverlayItem(GeoPointUtils.getGeoPoint("1825+Market+Street+San+Francisco"), "Headquarters", "Coffee & Power"),
		//        new OverlayItem(GeoPointUtils.getGeoPoint("2340+Francisco+Street+San+Francisco"), "Developer", "Melinda Green"),
		//        new OverlayItem(GeoPointUtils.getGeoPoint("481+York+Street+San+Francisco"), "Developer", "Charity Majors"),
	};

	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);
		mVisiblePointsSet = new HashSet<int[]>();
		Drawable drawableMarker = getResources().getDrawable(R.drawable.androidmarker);
		mAnnotations = new MapAnnotations(drawableMarker, this);

		// Add all the initial annotations.
		for(OverlayItem item : mOverlayItems)
		{
			addAnnotation(item);
		}

		mMapView = (CPMapView) findViewById(R.id.mapview); // From main.xml
		mMapView.setBuiltInZoomControls(true); // Shows the +/- controls as user interacts with the map.
		mMapView.getOverlays().add(mAnnotations); // Populates the map with all annotations.
		MapController controller = mMapView.getController(); // For programmatically driving the map.
		controller.setCenter(mOverlayItems[0].getPoint()); // Center the map on the C&P headquarters.
		controller.setZoom(CITY_LEVEL); // Initial zoom level. Users pinch-to-zoom from there.
		getSupportLoaderManager().initLoader(0, null, this);
	}

	@Override
	protected void onPause() {
		// TODO Auto-generated method stub
		super.onPause();
	}

	@Override
	protected void onResume() {
		// TODO Auto-generated method stub
		super.onResume();
	}

	private void addAnnotation(OverlayItem annotation) {
		mAnnotations.addOverlay(annotation);
	}

	// Required by base class.
	@Override
	protected boolean isRouteDisplayed() {
		// TODO Auto-generated method stub
		return false;
	}

	@Override
	public Loader<Cursor> onCreateLoader(int arg0, Bundle arg1) {
		String[] visiblePointsProjection = { "p.lat", "p.lon" };
		String visiblePointsSelection = " visible = ? ";
		String[] visiblePointsArgs = { "1" };

		Log.i("onCreateLoader","about to create CursorLoader");

		return new CursorLoader(this, 
				sVisiblePointsUri, 
				visiblePointsProjection, 
				visiblePointsSelection, 
				visiblePointsArgs, null);
	}

	@Override
	public void onLoadFinished(Loader<Cursor> arg0, Cursor visiblePointsCursor) {

//		Log.i("onLoadFinished", "cursor created read it");
		Set<int[]> newPoints = new HashSet<int[]>();
		while(visiblePointsCursor !=null && visiblePointsCursor.moveToNext())
		{
//			Log.i("onLoadFinished","cursor dereferenced");
			int lat = visiblePointsCursor.getInt(visiblePointsCursor.getColumnIndex("lat"));
			int lon = visiblePointsCursor.getInt(visiblePointsCursor.getColumnIndex("lon"));
			newPoints.add(new int[]{lat,lon});
		}
		if(mVisiblePointsSet.isEmpty() || !mVisiblePointsSet.equals(newPoints))
		{
			mVisiblePointsSet = newPoints;
//			Log.i("points","recreating points");
			mAnnotations.clear();
			for(int[] point : newPoints){
//				Log.i("onLoadFinished","creating point");
				OverlayItem item = new OverlayItem(new GeoPoint(point[0],point[1]), "p", "point");
				addAnnotation(item);
			}
		}
	}

	@Override
	public void onLoaderReset(Loader<Cursor> arg0) {
		// TODO Auto-generated method stub

	}

}