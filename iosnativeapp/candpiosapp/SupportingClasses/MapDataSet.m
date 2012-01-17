//
//  MapDataSet.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "MapDataSet.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"
#import "UserAnnotation.h"

@interface MapDataSet()
-(id)initFromJson:(NSDictionary*)json;
@end
@implementation MapDataSet
@synthesize annotations;
@synthesize dateLoaded;
@synthesize regionCovered;


+(void)beginLoadingNewDataset:(MKMapRect)mapRect
					 completion:(void (^)(MapDataSet *set, NSError *error))completion
{
	// get the center of the view
	MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
	CLLocationCoordinate2D currentLocation = region.center;
	// calculate the size of the view
	CLLocation * zeroLocation = [[CLLocation alloc] initWithLatitude: 0.0 longitude:0.0];
	CLLocation * deltaAsLocation = [[CLLocation alloc] initWithLatitude:region.span.latitudeDelta longitude:region.span.longitudeDelta];
	CLLocationDistance diameter = [zeroLocation distanceFromLocation:deltaAsLocation]; // in meters

    
	NSString *urlString = [NSString stringWithFormat:@"http://www.coffeeandpower.com/api.php?action=userlist&lat=%.7f&lon=%.7f&radius=%.1f", currentLocation.latitude, currentLocation.longitude, diameter / 2.0];
#if DEBUG
	NSLog(@"Loading datapoints from: %@", urlString);
#endif
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		
		MapDataSet *dataSet = [[MapDataSet alloc]initFromJson:JSON];
		dataSet.regionCovered = mapRect;
		dataSet.dateLoaded = [NSDate date];
		//dataSet.regionCovered = [[CLRegion alloc]initCircularRegionWithCenter:currentLocation radius:radiusInKm identifier:nil];
		
		if(completion)
			completion(dataSet, nil); 
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		//int z = 99;
		if(completion)
			completion(nil, error);
	}];
	
	[[NSOperationQueue mainQueue] addOperation:operation];
}

-(id)initFromJson:(NSDictionary*)json
{
	if((self = [super init]))
	{
		annotations = [NSMutableArray array];
		NSArray *payloadArray = [json objectForKey:@"payload"];
		NSLog(@"Got %d users.", [payloadArray count]);
		for(NSDictionary *userDict in payloadArray)
		{
			//NSLog(@"Mission %d: %@", )
			UserAnnotation *user = [[UserAnnotation alloc]initFromDictionary:userDict];
			
			// add (or update) the new pin
			[annotations addObject:user];
			
		}
		
	}
	return self;
}

// called by the mapview after scrolling & zooming
// 
-(bool)isValidFor:(MKMapRect)newRegion
{
	const double kTwoMinutesAgo = - 2 * 60;
	
	// if the data is old, we need to reload anyway
	double age = [dateLoaded timeIntervalSinceNow];
	if(dateLoaded && age < kTwoMinutesAgo)
	{
		return false;
	}
	
	// 
	if(MKMapRectContainsRect(regionCovered, newRegion))
	{
		// we get here if the new region is *entirely* within our dataset
		return true;
	}
	else
	{
		return false;
	}
	
}

@end
