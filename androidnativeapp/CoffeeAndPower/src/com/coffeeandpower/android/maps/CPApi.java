package com.coffeeandpower.android.maps;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.zip.GZIPInputStream;

import org.apache.http.Header;
import org.apache.http.HeaderElement;
import org.apache.http.HttpEntity;
import org.apache.http.HttpException;
import org.apache.http.HttpRequest;
import org.apache.http.HttpRequestInterceptor;
import org.apache.http.HttpResponse;
import org.apache.http.HttpResponseInterceptor;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.entity.HttpEntityWrapper;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.protocol.HttpContext;

import android.content.ContentValues;
import android.content.Context;
import android.net.Uri;
import android.util.Log;

import com.google.android.maps.GeoPoint;
import com.google.gson.stream.JsonReader;
import com.google.gson.stream.JsonToken;

public class CPApi {
	public static final String sApiUrlString = "http://coffeeandpower.com/api.php";
//TODO put this in just one class or in res/strings
	public static String sUriString = 
			"content://com.coffeeandpower.android.maps.provider/";

	public static void
	getCheckedInBoundsOverTime(Context context, GeoPoint sw, GeoPoint ne)
	{
		double sw_lat = sw.getLatitudeE6()/1000000.0;
		double sw_lon = sw.getLongitudeE6()/1000000.0;
		double ne_lat = ne.getLatitudeE6()/1000000.0;
		double ne_lon = ne.getLongitudeE6()/1000000.0;
		String urlString = sApiUrlString + 
				"?action=getCheckedInBoundsOverTime" +
				"&group_users=1&version=0.1" +
				"&sw_lat=" + sw_lat +
				"&sw_lng=" + sw_lon +
				"&ne_lat=" + ne_lat +
				"&ne_lng=" + ne_lon +
				"&checked_in_since=" + "1329441438.795357"
				//FIXME get time range working
				//				String.valueOf(
				//				(System.currentTimeMillis() - (86400000 * 7))
				//				)
				;
		Log.i("url","url:" + urlString);
		DefaultHttpClient client = new DefaultHttpClient();
		client.addRequestInterceptor(new HttpRequestInterceptor(){
			@Override
			public void process(HttpRequest request, HttpContext context)
					throws HttpException, IOException {
				if(!request.containsHeader("Accept-Encoding"))
				{
					request.addHeader("Accept-Encoding", "gzip");
				}
			}	
		});
		client.addResponseInterceptor(new HttpResponseInterceptor(){
			@Override
			public void process(HttpResponse response, HttpContext context)
					throws HttpException, IOException {
				HttpEntity entity = response.getEntity();
				Header header = entity.getContentEncoding();
				if(header != null){
					for(HeaderElement element : header.getElements())
					{
						if(element.getName().equals("gzip"))
						{
							response.setEntity(new GzipEntity(entity));
							return;
						}
					}
				}
			}
			
		});
		//TODO check for background network setting
		HttpUriRequest request = new HttpGet(urlString);
		try
		{
			HttpEntity httpEntity = client.execute(request).getEntity();
			if(httpEntity != null)
			{
				InputStream inputStream = httpEntity.getContent();
				InputStreamReader inputStreamReader = new InputStreamReader(inputStream);
				BufferedReader br = new BufferedReader(inputStreamReader);
				Log.i("netresponse", br.toString());
				JsonReader reader = new JsonReader(br);
				reader.beginObject();
				while(reader.hasNext())
				{
					String node = reader.nextName();
					Log.i("json", "node:" + node);
					if(node.equals("error"))
					{
						boolean status = reader.nextBoolean();
						Log.i("json", "status:" + String.valueOf(status));
					}
					else if( node.equals("payload"))
					{
						Log.i("json","beginArray");
						reader.beginArray();
						while(reader.hasNext())
						{
							Log.i("json","beginObject");
							reader.beginObject();
							CPCheckin checkin = new CPCheckin();
							while(reader.hasNext())
							{
								String key = reader.nextName();
								Log.i("json", "key:" + key);
								if(key.equals("checkin_id"))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.checkin_id = 0; }
									else
									{ checkin.checkin_id = reader.nextInt(); }
								else if(key.equals("id"))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.id = 0; }
									else
									{ checkin.id = reader.nextInt(); }
								else if(key.equals("nickname"))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.nickname = "";}
									else
									{ checkin.nickname = reader.nextString(); }
								else if(key.equals("status_text"))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.status_text = ""; }
									else
									{ checkin.status_text = reader.nextString(); }
								else if(key.equals("photo"))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.photo = 0; }
									else
									{ checkin.photo = reader.nextInt(); }
								else if(key.equals("major_job_category"))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.major_job_category = "";}
									else
									{ checkin.major_job_category = reader.nextString(); }
								else if(key.equals( "minor_job_category" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.minor_job_category = "";}
									else
									{ checkin.minor_job_category = reader.nextString(); }
								else if(key.equals( "headline" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.headline = "";}
									else
									{ checkin.headline = reader.nextString(); }
								else if(key.equals( "filename" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.filename = "";}
									else
									{ checkin.filename = reader.nextString(); }
								else if(key.equals( "lat" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.lat = 0.0; }
									else
									{ checkin.lat = reader.nextDouble(); }
								else if(key.equals( "lng" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.lon = 0.0; }
									else
									{ checkin.lon = reader.nextDouble(); }
								else if(key.equals( "checked_in" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.checked_in = 0; }
									else
									{ checkin.checked_in = reader.nextInt(); }
								else if(key.equals( "foursquare" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.foursquare = ""; }
									else
									{ checkin.foursquare = reader.nextString(); }
								else if(key.equals( "venue_name" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.venue_name = ""; }
									else
									{ checkin.venue_name = reader.nextString(); }
								else if(key.equals( "checkin_count" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.checkin_count = 0;}
									else
									{ checkin.checkin_count = reader.nextInt(); }
								else if(key.equals( "skills" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull(); checkin.skills = ""; }
									else
									{ checkin.skills = reader.nextString(); }
								else
								{
									Log.i("json_unknown","key:" + key);
									reader.skipValue();
								}
							}
							GeoPoint checkinPoint = new GeoPoint((int)(checkin.lat * 1000000.0),
									(int)(checkin.lon * 1000000.0));
							CPQuadTree quadTree = new CPQuadTree(checkinPoint);
							Log.i("checkin","parsed checkin;" + checkin.toString());
							ContentValues insertValues = new ContentValues();
							insertValues.put("quad_index", quadTree.getIndex());
							insertValues.put("lat", checkinPoint.getLatitudeE6());
							insertValues.put("lon", checkinPoint.getLongitudeE6());
							Uri MapPointsUri = Uri.parse(sUriString + "points");
							context.getContentResolver().insert(MapPointsUri, insertValues);
						}
					}
					else
					{
						String value = reader.nextString();
						Log.i("json","node:" + node + " value:" + value);
					}
				}
			}
		}catch (ClientProtocolException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	private static class GzipEntity extends HttpEntityWrapper 
	{

		public GzipEntity(HttpEntity wrapped) {
			super(wrapped);			
		}

		@Override
		public InputStream getContent() throws IOException {
			return new GZIPInputStream(wrappedEntity.getContent());
		}

		@Override
		public long getContentLength() {
			return -1;
		}
		
	}
}
