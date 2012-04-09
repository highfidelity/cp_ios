package com.coffeeandpower.android.maps;

import java.util.ArrayList;

import android.app.AlertDialog;
import android.content.Context;
import android.graphics.drawable.Drawable;

import com.google.android.maps.ItemizedOverlay;
import com.google.android.maps.OverlayItem;

/**
 * A drawable list of annotations with interactions.
 * 
 * @author Melinda Green
 */
public class MapAnnotations extends ItemizedOverlay<OverlayItem> {

    @Override
    protected boolean onTap(int index) {
        OverlayItem item = mOverlays.get(index);
        AlertDialog.Builder dialog = new AlertDialog.Builder(mContext);
        dialog.setTitle(item.getTitle());
        dialog.setMessage(item.getSnippet());
        dialog.show();
        return true;
    }

    private ArrayList<OverlayItem> mOverlays = new ArrayList<OverlayItem>();
    private Context mContext;

    public MapAnnotations(Drawable defaultMarker, Context context) {
        super(boundCenterBottom(defaultMarker));
        mContext = context;
    }

    @Override
    protected OverlayItem createItem(int i) {
        return mOverlays.get(i);
    }

    @Override
    public int size() {
        return mOverlays.size();
    }

    public void addOverlay(OverlayItem overlay) {
        mOverlays.add(overlay);
        populate();
    }

    public void clear()
    {
    	mOverlays.clear();
    	populate();
    }
}

/*
 * Useful code for when we want to dynamically "paint" onto the overlay.
 * 
 * @Override
 * public void draw(android.graphics.Canvas canvas, MapView mapView, boolean shadow) {
 * super.draw(canvas, mapView, shadow);
 * 
 * if(shadow == false) {
 * //cycle through all overlays
 * for(int index = 0; index < mOverlays.size(); index++) {
 * OverlayItem item = mOverlays.get(index);
 * 
 * // Converts lat/lng-Point to coordinates on the screen
 * GeoPoint point = item.getPoint();
 * Point ptScreenCoord = new Point();
 * mapView.getProjection().toPixels(point, ptScreenCoord);
 * 
 * //Paint
 * Paint paint = new Paint();
 * paint.setTextAlign(Paint.Align.CENTER);
 * paint.setTextSize(30);
 * paint.setARGB(150, 0, 0, 0); // alpha, r, g, b (Black, semi see-through)
 * 
 * //show text to the right of the icon
 * canvas.drawText(item.getTitle(), ptScreenCoord.x, ptScreenCoord.y + 30, paint);
 * }
 * }
 * }
 */
