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


+(void)beginLoadingNewDataset:(CLLocationCoordinate2D)currentLocation
				   radiusInKm:(double)radiusInKm
					 completion:(void (^)(MapDataSet *set, NSError *error))completion

{
    
	NSString *urlString = [NSString stringWithFormat:@"http://www.coffeeandpower.com/api.php?action=userlist&lat=%f&lon=%f", currentLocation.latitude, currentLocation.longitude];
    
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		
		// clear out all the old annotations
		// TODO: update the existing elements instead of removing them all
		// 
		
		MapDataSet *dataSet = [[MapDataSet alloc]initFromJson:JSON];
		MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(currentLocation, radiusInKm, radiusInKm);
		dataSet.regionCovered = region;
		//dataSet.regionCovered = [[CLRegion alloc]initCircularRegionWithCenter:currentLocation radius:radiusInKm identifier:nil];
		
		// for now, just remove all the old missions/users
		// TODO: handle the updates individually
		//[mapView removeAnnotations:missions];
		
		// start with a new list
//		missions = [NSMutableArray array];
//		
//		NSArray *payloadArray = [JSON objectForKey:@"payload"];
//		NSLog(@"Got %d users.", [payloadArray count]);
//		for(NSDictionary *userDict in payloadArray)
//		{
//			//NSLog(@"Mission %d: %@", )
//			UserAnnotation *user = [[UserAnnotation alloc]initFromDictionary:userDict];
//			
//			// add (or update) the new pin
//			[missions addObject:user];
//			
//		}
		// and the (potential) pin, too
//		[mapView addAnnotations:missions];
//		
//		[SVProgressHUD dismiss];
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

@end
