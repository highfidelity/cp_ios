package com.coffeeandpower.android.maps;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import org.apache.http.HttpEntity;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.impl.client.DefaultHttpClient;

import android.util.Log;

import com.google.android.maps.GeoPoint;
import com.google.gson.stream.JsonReader;
import com.google.gson.stream.JsonToken;

public class CPApi {
	public static final String sApiUrlString = "http://coffeeandpower.com/api.php";

	public static void
	getCheckedInBoundsOverTime(GeoPoint sw, GeoPoint ne)
	{
		//TODO set to use gzip
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
		HttpClient client = new DefaultHttpClient();
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
									{ reader.nextNull();}
									else
									{ checkin.checkin_id = reader.nextInt(); }
								else if(key.equals("id"))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.id = reader.nextInt(); }
								else if(key.equals("nickname"))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.nickname = reader.nextString(); }
								else if(key.equals("status_text"))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.status_text = reader.nextString(); }
								else if(key.equals("photo"))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.photo = reader.nextInt(); }
								else if(key.equals("major_job_category"))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.major_job_category = reader.nextString(); }
								else if(key.equals( "minor_job_category" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.minor_job_category = reader.nextString(); }
								else if(key.equals( "headline" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.headline = reader.nextString(); }
								else if(key.equals( "filename" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.filename = reader.nextString(); }
								else if(key.equals( "lat" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.lat = reader.nextDouble(); }
								else if(key.equals( "lng" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.lon = reader.nextDouble(); }
								else if(key.equals( "checked_in" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.checked_in = reader.nextInt(); }
								else if(key.equals( "foursquare" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.foursquare = reader.nextString(); }
								else if(key.equals( "venue_name" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.venue_name = reader.nextString(); }
								else if(key.equals( "checkin_count" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.checkin_count = reader.nextInt(); }
								else if(key.equals( "skills" ))
									if(reader.peek() == JsonToken.NULL)
									{ reader.nextNull();}
									else
									{ checkin.skills = reader.nextString(); }
								else
								{Log.i("json_unknown","key:" + key);}
							}
							Log.i("checkin","parsed checkin;" + checkin.toString());
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
}
