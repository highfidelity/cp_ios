package com.coffeeandpower.android.maps;

import java.util.List;

import android.graphics.drawable.Drawable;
import android.os.Bundle;

import com.google.android.maps.GeoPoint;
import com.google.android.maps.MapActivity;
import com.google.android.maps.MapController;
import com.google.android.maps.MapView;
import com.google.android.maps.Overlay;
import com.google.android.maps.OverlayItem;

public class CoffeeAndPowerActivity extends MapActivity {
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        MapView mapView = (MapView) findViewById(R.id.mapview);
        mapView.setBuiltInZoomControls(true);//37.7, 122.4
        MapController controller = mapView.getController();

        List<Overlay> mapOverlays = mapView.getOverlays();
        Drawable drawable = this.getResources().getDrawable(R.drawable.androidmarker);
        MapAnnotations itemizedoverlay = new MapAnnotations(drawable, this);

        GeoPoint sf = new GeoPoint(37779300, -122419200);
        GeoPoint cnp = GeoPointUtils.getGeoPoint("1825+Market+Street+San+Francisco");
        GeoPoint melinda = GeoPointUtils.getGeoPoint("2340+Francisco+Street+San+Francisco");
        GeoPoint charity = GeoPointUtils.getGeoPoint("481+York+Street+San+Francisco");

        OverlayItem overlayitem = new OverlayItem(cnp, "Headquarters", "Coffee & Power");
        itemizedoverlay.addOverlay(overlayitem);
        mapOverlays.add(itemizedoverlay);
//        overlayitem = new OverlayItem(sf, "Location", "Downtown SF");
//        itemizedoverlay.addOverlay(overlayitem);
//        mapOverlays.add(itemizedoverlay);
        overlayitem = new OverlayItem(melinda, "Developer", "Melinda Green");
        itemizedoverlay.addOverlay(overlayitem);
        mapOverlays.add(itemizedoverlay);
        overlayitem = new OverlayItem(charity, "Developer", "Charity Majors");
        itemizedoverlay.addOverlay(overlayitem);
        mapOverlays.add(itemizedoverlay);

        controller.setCenter(cnp);
        controller.setZoom(14);
    }

    @Override
    protected boolean isRouteDisplayed() {
        // TODO Auto-generated method stub
        return false;
    }


    //////////////////////////////////////////////////////////////////////////////

}