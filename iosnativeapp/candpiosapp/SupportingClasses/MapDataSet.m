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
#import "AppDelegate.h"

@interface MapDataSet()
-(id)initFromJson:(NSDictionary*)json;
@end
@implementation MapDataSet
@synthesize annotations;
@synthesize dateLoaded;
@synthesize regionCovered;

static NSOperationQueue *sMapQueue = nil;

+(void)beginLoadingNewDataset:(MKMapRect)mapRect
					 completion:(void (^)(MapDataSet *set, NSError *error))completion
{
	if(!sMapQueue)
	{
		sMapQueue = [[NSOperationQueue alloc]init];
		[sMapQueue setSuspended:NO];
		// serialize requests, please
		[sMapQueue setMaxConcurrentOperationCount:1];
	}
	
	// TODO:  if we're already busy, cancel the old one and issue the new one
	if([sMapQueue operationCount] == 0)
	{
        MKMapPoint neMapPoint = MKMapPointMake(mapRect.origin.x + mapRect.size.width, mapRect.origin.y + mapRect.size.height);
        MKMapPoint swMapPoint = MKMapPointMake(mapRect.origin.x, mapRect.origin.y);
        CLLocationCoordinate2D swCoord = MKCoordinateForMapPoint(swMapPoint);
        CLLocationCoordinate2D neCoord = MKCoordinateForMapPoint(neMapPoint);
        
        CGFloat numberOfDays = 31.0;
        
		NSString *urlString = [NSString stringWithFormat:@"%@api.php?action=getCheckedInBoundsOverTime&sw_lat=%f&sw_lng=%f&ne_lat=%f&ne_lng=%f&checked_in_since=%f&group_users=1", 
                               kCandPWebServiceUrl,
                               swCoord.latitude,
                               swCoord.longitude,
                               neCoord.latitude,
                               neCoord.longitude,
                               [[NSDate date] timeIntervalSince1970] - (86400 * numberOfDays)
                               ];
	#if DEBUG
		NSLog(@"Loading datapoints from: %@", urlString);
	#endif
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
		AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
			MapDataSet *dataSet = [[MapDataSet alloc]initFromJson:JSON];
			dataSet.regionCovered = mapRect;
			dataSet.dateLoaded = [NSDate date];
			
			if(completion)
				completion(dataSet, nil); 
			
		} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSLog(@"%@", error);
			if(completion)
				completion(nil, error);
		}];
		
		[sMapQueue addOperation:operation];
	}
	else
	{
		if(completion)
			completion(nil, [NSError errorWithDomain:@"Busy" code:999 userInfo:nil]);
		
	}
	
}
-(id)init {
    if (([super init])) {
        annotations = [NSMutableArray array];
    }
    return self;
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
		NSLog(@".... data was too old (%.2f seconds old)", age);
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
