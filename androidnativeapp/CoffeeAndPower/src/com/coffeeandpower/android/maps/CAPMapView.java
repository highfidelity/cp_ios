package com.coffeeandpower.android.maps;

import android.content.Context;
import android.graphics.Canvas;
import android.location.Location;
import android.util.AttributeSet;
import android.util.Log;

import com.google.android.maps.GeoPoint;
import com.google.android.maps.MapView;
import com.google.android.maps.Projection;

public class CAPMapView extends MapView {

	public GeoPoint mOldSw,mOldNe,mOldC;

	public CAPMapView(Context context, AttributeSet attrs) {
		super(context, attrs);
		// TODO Auto-generated constructor stub
	}

	public CAPMapView(Context context, AttributeSet attrs, int defStyle) {
		super(context, attrs, defStyle);
		// TODO Auto-generated constructor stub
	}

	public CAPMapView(Context context, String apiKey) {
		super(context, apiKey);
		// TODO Auto-generated constructor stub
	}
	private void initialize(){
		mOldSw = new GeoPoint(0,0);
		mOldNe = new GeoPoint(0,0);
		mOldC  = new GeoPoint(0,0);
	}
	@Override
	public void dispatchDraw(Canvas canvas) {
		// TODO Auto-generated method stub
		super.dispatchDraw(canvas);
        Projection proj = getProjection();
        GeoPoint center = getMapCenter();
        GeoPoint southwest = proj.fromPixels(getLeft(), getBottom());
        GeoPoint northeast = proj.fromPixels(getRight(), getTop());
        
        if((mOldC != center) || (mOldSw != southwest) || (mOldNe != northeast) ){
        	mOldC  = center;
        	mOldSw = southwest;
        	mOldNe = northeast;
        	
            Log.i("canpmobi","Left:" + getLeft() + " Right:" + getRight()
            		+ " Top:" + getTop() + " Bottom:" + getBottom());
            double c_lat = center.getLatitudeE6()/1000000.0;
            double c_lon = center.getLongitudeE6()/1000000.0;
            double sw_lat = southwest.getLatitudeE6()/1000000.0;
            double sw_lon = southwest.getLongitudeE6()/1000000.0;
            double ne_lat = northeast.getLatitudeE6()/1000000.0;
            double ne_lon = northeast.getLongitudeE6()/1000000.0;
            float distance_sw_c[] = new float[1];
            float distance_ne_c[] = new float[1];
            Location.distanceBetween(c_lat, c_lon, sw_lat, sw_lon, distance_sw_c);
            Location.distanceBetween(c_lat, c_lon, ne_lat, ne_lon, distance_ne_c);
            String urlstring = "https://coffeeandpower.com/api.php?action=getCheckedInBoundsOverTime";
            urlstring += "&ne_lat=" + sw_lat + "&sw_lng=" + sw_lon + 
            		"&sw_lat=" + ne_lat + "&ne_lng=" + ne_lon + 
            		"&checked_in_since=1329441438.795357&group_users=1"; 
            Log.i("candpmobi","Center:" + center);
    		Log.i("candpmobi","SouthWest:" + proj.fromPixels(getLeft(), getBottom()));
    		Log.i("candpmobi","sw_lat:" + sw_lat + " sw_lon:" + sw_lon);
    		Log.i("candpmobi","sw2c:" + distance_sw_c[0] + " ne2c:" + distance_ne_c[0]);
    		Log.i("candpmobi","NorthEast:" + proj.fromPixels(getRight(), getTop()));
    		Log.i("candpmobi","ne_lat:" + ne_lat + " ne_lon:" + ne_lon);
    		Log.i("candpmobi_url",urlstring);
    		CPAsyncGet gettask = new CPAsyncGet();
    		gettask.execute(urlstring);
        	
        }
        
	}


}
