package com.coffeeandpower.android.maps;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.AlertDialog;
import android.content.Context;
import android.graphics.drawable.Drawable;
import android.os.Bundle;

import com.google.android.maps.GeoPoint;
import com.google.android.maps.ItemizedOverlay;
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
        MyOverlay itemizedoverlay = new MyOverlay(drawable, this);

        GeoPoint sf = new GeoPoint(37779300, -122419200);
        GeoPoint cnp = getGeoPoint("1825+Market+Street+San+Francisco");
        GeoPoint melinda = getGeoPoint("2340+Francisco+Street+San+Francisco");
        GeoPoint charity = getGeoPoint("481+York+Street+San+Francisco");

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

    class MyOverlay extends ItemizedOverlay {

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
        Context mContext;

        public MyOverlay(Drawable defaultMarker, Context context) {
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

        /*
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

    }

    //////////////////////////////////////////////////////////////////////////////

    public static GeoPoint getGeoPoint(String address) {
        JSONObject jloc = getLocationInfo(address);
        return getGeoPoint(jloc);
    }


    public static JSONObject getLocationInfo(String address) {

        HttpGet httpGet = new HttpGet("http://maps.google."
                + "com/maps/api/geocode/json?address=" + address
                + "ka&sensor=false");
        HttpClient client = new DefaultHttpClient();
        HttpResponse response;
        StringBuilder stringBuilder = new StringBuilder();

        try {
            response = client.execute(httpGet);
            HttpEntity entity = response.getEntity();
            InputStream stream = entity.getContent();
            int b;
            while((b = stream.read()) != -1) {
                stringBuilder.append((char) b);
            }
        } catch(ClientProtocolException e) {} catch(IOException e) {}

        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject = new JSONObject(stringBuilder.toString());
        } catch(JSONException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }

        return jsonObject;
    }

    public static GeoPoint getGeoPoint(JSONObject jsonObject) {

        Double lon = new Double(0);
        Double lat = new Double(0);

        try {

            lon = ((JSONArray) jsonObject.get("results")).getJSONObject(0)
                .getJSONObject("geometry").getJSONObject("location")
                .getDouble("lng");

            lat = ((JSONArray) jsonObject.get("results")).getJSONObject(0)
                .getJSONObject("geometry").getJSONObject("location")
                .getDouble("lat");

        } catch(JSONException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }

        return new GeoPoint((int) (lat * 1E6), (int) (lon * 1E6));

    }
}