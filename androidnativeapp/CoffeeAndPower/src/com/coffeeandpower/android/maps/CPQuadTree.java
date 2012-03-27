package com.coffeeandpower.android.maps;

import android.util.Log;

import com.google.android.maps.GeoPoint;

public class CPQuadTree {
	
	//TODO mULat, and mUlon don't have to be long refactor to int
	private long mULat; //unsigned latitude (+180 degrees)
	private long mULon; //unsigned longitude (+180 degrees)
	private int mZoom;
	private static final int sSignificantBits = 28;

	public CPQuadTree(GeoPoint location) {
		mULat = location.getLatitudeE6() + 180000000;
		mULon = location.getLongitudeE6() + 180000000;
		mZoom = 0;
	}
	public CPQuadTree(long ulat, long ulon) {
		mULat = ulat;
		mULon = ulon;
	}
	public CPQuadTree(long ulat, long ulon, int zoom)
	{
		mULat = ulat;
		mULon = ulon;
		mZoom = zoom;
	}
	public CPQuadTree(long index) {
		// mask off every other bit
		long latbits = (index & 0xAAAAAAAAAAAAAAAL); // looks like 1010
		long lonbits = (index & 0x555555555555555L); // looks like 0101
//		Log.i("quadtree","index_bits: " + Long.toBinaryString(index));
//		Log.i("quadtree","lat_bits:   " + Long.toBinaryString(latbits));
//		Log.i("quadtree","lon_bits:   " + Long.toBinaryString(lonbits));
		
		long mask = 1;
		long lat = 0;
		long lon = 0;
		latbits >>= 1;
		int bitcount = 32;
		
		for(int i = 0; i < bitcount ; i++)
		{
			lat |= ((latbits >> (i)) & mask);
			lon |= ((lonbits >> (i)) & mask);
			mask <<= 1;
		}
//		Log.i("quadtree","lat:        " + Long.toBinaryString(lat));
//		Log.i("quadtree","lon:        " + Long.toBinaryString(lon));
		mULat = lat;
		mULon = lon;
		mZoom = 0;
	}

	public long getIndex()
	{
		long lat = mULat << 1;
		long lon = mULon;
		
		long latbits = 0;
		long lonbits = 0;
		int bitcount = 32; // how many bits to iterate
		long mask = 1;
		for(int i = 0; i < bitcount ; i++){
//			Log.i("quadtree","lon_mask:   " + Long.toBinaryString(mask));
//			Log.i("quadtree","lon_shifted:" + Long.toBinaryString(lon << i));
			lonbits |= ((lon << i) & mask);
			mask <<= 1;
//			Log.i("quadtree","lat_mask: " + Long.toBinaryString(mask));
			latbits |= ((lat << i) & mask);
			mask <<= 1;
//			Log.i("quadtree","lat_shifted:" + Long.toBinaryString(lat << i));
//			Log.i("quadtree","lat_bits: " + Long.toBinaryString(latbits));
//			Log.i("quadtree","lon_bits: " + Long.toBinaryString(lonbits));
		}
		return (lonbits|latbits);
	}
	
	public GeoPoint getPoint()
	{
		long lat = mULat - 180000000;
		if(lat < -80000000)
		{
			lat = -80000000;
		}
		else if(lat > 80000000)
		{
			lat = 80000000;
		}
		long lon = mULon - 180000000;
		if(lon == -180000000){
			lon++;
		}
		return new GeoPoint((int)lat,(int)lon);
	}
	
	public static CPQuadTree[][] 
			getTilesForBounds(GeoPoint swPoint,GeoPoint nePoint, int zoom)
	{
		int tileSize =  1 << (sSignificantBits - zoom);
		CPQuadTree sw = new CPQuadTree(swPoint).getZoom(zoom);
		CPQuadTree ne = new CPQuadTree(nePoint).getZoom(zoom);
		long latSpan = ne.mULat - sw.mULat;
		long lonSpan = ne.mULon - sw.mULon;
		int latCount = (int) (latSpan/tileSize);
		int lonCount = (int) (lonSpan/tileSize);
		
		CPQuadTree[][] tiles = new CPQuadTree[latCount][lonCount];
		for(int y = 0; y < latCount; y++)
		{
			for(int x = 0; x < lonCount; x++)
			{
				long ulat = sw.mULat + y * tileSize;
				long ulon = sw.mULon + x * tileSize;
				CPQuadTree logTest = new CPQuadTree(ulat, ulon, zoom);
				GeoPoint logPoint = logTest.getPoint();
				Log.i("bounds", "x:" + String.valueOf(x) + 
						" y:" + String.valueOf(y) + 
						" lat:" + logPoint.getLatitudeE6() +
						" lon:" + logPoint.getLongitudeE6());
				tiles[y][x] = new CPQuadTree(ulat, ulon, zoom);
			}
		}
		return tiles;
	}
	
	public CPQuadTree getZoom(int zoomLevel) // zoom out to tile
	{
		//TODO check for and fix zoomlevel 0-2 weirdness
		int shiftSize = sSignificantBits - zoomLevel;
		int mask = 0xFFFFFFFF << shiftSize;
		long zoomLat = mULat & mask;
		long zoomLon = mULon & mask;
		return new CPQuadTree(zoomLat,zoomLon, zoomLevel);
	}

	// this method is only used for testing
	public void logZoomLevels()
	{
		CPQuadTree zoomedQuad;
		CPQuadTree quadNorth;
		CPQuadTree quadEast;
		CPQuadTree quadNorthEast;
		GeoPoint zoomedPoint;
		GeoPoint zoomedNorth;
		GeoPoint zoomedEast;
		GeoPoint zoomedNorthEast;
		
		for(int i = 0; i <= sSignificantBits; i++)
		{
		zoomedQuad = getZoom(i);
		quadNorth = zoomedQuad.getNorth();
		quadEast = zoomedQuad.getEast();
		quadNorthEast = zoomedQuad.getNorthEast();
		zoomedPoint = zoomedQuad.getPoint();
		zoomedNorth = quadNorth.getPoint();
		zoomedEast = quadEast.getPoint();
		zoomedNorthEast = quadNorthEast.getPoint();
		Log.i("zoomtest", "zoom         :" + String.valueOf(i) + 
				" lat:" + zoomedPoint.getLatitudeE6() + 
				" lon:" + zoomedPoint.getLongitudeE6());
//		Log.i("zoomtest", "zoomNorth    :" + String.valueOf(i) + 
//				" lat:" + zoomedNorth.getLatitudeE6() + 
//				" lon:" + zoomedNorth.getLongitudeE6());
//		Log.i("zoomtest", "zoomEast     :" + String.valueOf(i) + 
//				" lat:" + zoomedEast.getLatitudeE6() + 
//				" lon:" + zoomedEast.getLongitudeE6());
		Log.i("zoomtest", "zoomNorthEast:" + String.valueOf(i) + 
				" lat:" + zoomedNorthEast.getLatitudeE6() + 
				" lon:" + zoomedNorthEast.getLongitudeE6());
		}
	}
	public CPQuadTree getNorth()
	{
		//TODO check for edge of map edge cases (there be dragons)
		int tileSize =  1 << (sSignificantBits - mZoom);
		long lat = mULat + tileSize;
		return new CPQuadTree(lat,mULon,mZoom);
	}
	public CPQuadTree getEast()
	{
		//TODO check for edge of map edge cases (there be dragons)
		int tileSize =  1 << (sSignificantBits - mZoom);
		long lon = mULon + tileSize;
		return new CPQuadTree(mULat,lon,mZoom);
	}
	public CPQuadTree getNorthEast()
	{
		//TODO check for edge of map edge cases (there be dragons)
		int tileSize =  1 << (sSignificantBits - mZoom);
		long lat = mULat + tileSize;
		long lon = mULon + tileSize;
		return new CPQuadTree(lat,lon,mZoom);
	}
}
