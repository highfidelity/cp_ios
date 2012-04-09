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

@interface MapDataSet()
-(id)initFromJson:(NSDictionary*)json;
@end
@implementation MapDataSet
@synthesize annotations = _annotations;
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
        MKMapPoint neMapPoint = MKMapPointMake(mapRect.origin.x + mapRect.size.width, mapRect.origin.y);
        MKMapPoint swMapPoint = MKMapPointMake(mapRect.origin.x, mapRect.origin.y + mapRect.size.height);
        CLLocationCoordinate2D swCoord = MKCoordinateForMapPoint(swMapPoint);
        CLLocationCoordinate2D neCoord = MKCoordinateForMapPoint(neMapPoint);
        
        
        CGFloat numberOfDays = 7.0;
        
        [CPapi getVenuesWithCheckinsWithinSWCoordinate:swCoord 
                                          NECoordinate:neCoord 
                                          userLocation:[CPAppDelegate settings].lastKnownLocation.coordinate
                                        checkedInSince:numberOfDays  
                                              mapQueue:sMapQueue 
                                        withCompletion:^(NSDictionary *json, NSError *error){
            
            if (!error) {
                MapDataSet *dataSet = [[MapDataSet alloc] initFromJson:json];
                dataSet.regionCovered = mapRect;
                dataSet.dateLoaded = [NSDate date];
                
                if (completion) {
                    completion(dataSet, nil);
                }
            } else {
                if (completion) {
                    completion(nil, error);
                }
            }
        }];
	}
	else
	{
		if(completion)
			completion(nil, [NSError errorWithDomain:@"Busy" code:999 userInfo:nil]);
	}
	
}

- (NSMutableArray *)annotations
{
    if (!_annotations) {
        _annotations = [NSMutableArray array];
    }
    return _annotations;
}

-(id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

-(id)initFromJson:(NSDictionary*)json
{
	if((self = [super init]))
	{		
        // get the places that came back and make an annotation for each of them
        NSArray *placesArray = [[json objectForKey:@"payload"] objectForKey:@"venues"];

        if (![placesArray isKindOfClass:[NSNull class]]) {
#if DEBUG
            NSLog(@"Got %d places.", [placesArray count]);
#endif
            for(NSDictionary *placeDict in placesArray)
            {
                CPPlace *place = [[CPPlace alloc] initFromDictionary:placeDict];
                
                // add (or update) the new pin
                [self.annotations addObject:place];
                
                // post a notification with this venue if there's currently a venue shown by a VenueInfoViewController
                if ([CPAppDelegate tabBarController].currentVenueID) {
                    if ([[CPAppDelegate tabBarController].currentVenueID isEqualToString:place.foursquareID]) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshVenueAfterCheckin" object:place];
                    }                    
                }
                
            }
            
        }

        // get the users that came back and setup the activeUsers array on the Map
        
        NSArray *usersArray = [[json objectForKey:@"payload"] objectForKey:@"users"];

        if (![usersArray isKindOfClass:[NSNull class]]) {
#if DEBUG
            NSLog(@"Got %d users.", [usersArray count]);
#endif
            for (NSDictionary *userDict in usersArray) {
                User *user = [[User alloc] initFromDictionary:userDict];
                
                // add the user to the MapTabController activeUsers array
                [[CPAppDelegate settingsMenuController].mapTabController.activeUsers setObject:user forKey:[NSString stringWithFormat:@"%d", user.userID]];
            }
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
