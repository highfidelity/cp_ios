//
//  MapDataSet.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "MapDataSet.h"

@interface MapDataSet()

-(id)initFromJson:(NSDictionary*)json;

@end

@implementation MapDataSet

static NSOperationQueue *sMapQueue = nil;

- (NSArray *)annotations
{
    return [self.activeVenues allValues];
}

+(void)beginLoadingNewDataset:(CLLocationCoordinate2D)mapCenter
					 completion:(void (^)(MapDataSet *set, NSError *error))completion
{
	if(!sMapQueue) {
		sMapQueue = [NSOperationQueue new];
		[sMapQueue setSuspended:NO];
		// serialize requests, please
		[sMapQueue setMaxConcurrentOperationCount:1];
	}
    
    if ([sMapQueue operationCount] > 0) {
        [sMapQueue cancelAllOperations];
        [sMapQueue waitUntilAllOperationsAreFinished];
    }
    
	
	if([sMapQueue operationCount] == 0) {
        [CPapi getNearestVenuesWithCheckinsToCoordinate:mapCenter 
                                               mapQueue:sMapQueue 
                                             completion:^(NSDictionary *json, NSError *error){
            
            if (!error) {
                MapDataSet *dataSet = [[MapDataSet alloc] initFromJson:json];
                
                // set some properties on the dataSet we'll use later to see if we need to reload it
                dataSet.previousCenter = mapCenter;
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
	} else {
        //Because cancelAllOperations is called above it should not get here, but it is does it will show busy.
		if(completion)
			completion(nil, [NSError errorWithDomain:@"Busy" code:999 userInfo:nil]);
        
        NSLog(@"MapDataSet: Busy");
	}
	
}

-(id)initFromJson:(NSDictionary*)json
{
	if((self = [super init])) {
        // get the places that came back and make an annotation for each of them
        NSArray *venuesArray = [[json objectForKey:@"payload"] objectForKey:@"venues"];
        
        // mutable data structure to hold venues 
        NSMutableDictionary *venueMutableDict = [NSMutableDictionary dictionary];
        
        if (![venuesArray isKindOfClass:[NSNull class]]) {
#if DEBUG
            NSLog(@"Got %d venues.", [venuesArray count]);
#endif
            //get the contacts of the current user
            NSArray *contactsArray = [[json objectForKey:@"payload"] objectForKey:@"contacts"];
#if DEBUG
            NSLog(@"Got %d contacts.", [contactsArray count]);
#endif
            
            MKMapRect coveredRect = MKMapRectNull;

            for(NSDictionary *venueDict in venuesArray) {
                
                CPVenue *venue = [[CPVenue alloc] initFromDictionary:venueDict];
                //See if the user can checkin at a venue because they have a contact there
                venue.hasContactAtVenue = NO;
                for(id userIDObj in venue.activeUsers) {
                    int activeUserID = [userIDObj integerValue];
                    NSDictionary *currentActiveUser = [venue.activeUsers objectForKey:userIDObj];
                    BOOL activeUserCheckedIn = [[currentActiveUser objectForKey:@"checked_in"] boolValue];
                    //Check to see if the activeUser at the venue is checkin
                    if(activeUserCheckedIn) {
                        for(NSDictionary *contactDict in contactsArray) {
                            if(activeUserID == [[contactDict objectForKey:@"other_user_id"] integerValue]) {
                                venue.hasContactAtVenue = YES;
                                break;
                            }
                        }
                    }
                }
                
                MKMapPoint venuePoint = MKMapPointForCoordinate(venue.coordinate);
                MKMapRect pointRect = MKMapRectMake(venuePoint.x, venuePoint.y, 0, 0);
                if (MKMapRectIsNull(coveredRect)) {
                    coveredRect = pointRect;
                } else {
                    coveredRect = MKMapRectUnion(coveredRect, pointRect);
                }
                
                // add (or update) the new pin in the 
                [venueMutableDict setObject:venue forKey:[NSString stringWithFormat:@"%d", venue.venueID]];
                
                // post a notification with this venue if there's currently a venue shown by a VenueInfoViewController
                if ([CPAppDelegate tabBarController].currentVenueID) {
                    if ([[CPAppDelegate tabBarController].currentVenueID isEqual:venue.foursquareID]) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshVenueAfterCheckin" object:venue];
                    }                    
                }
                
            }
            // set our regionCovered property given the southwest coordinate and northeast coordinate
            self.regionCovered = coveredRect;
        }
        
        self.activeVenues = [NSDictionary dictionaryWithDictionary:venueMutableDict];
        
        // get the users that came back and setup the activeUsers array on the Map
        
        NSArray *usersArray = [[json objectForKey:@"payload"] objectForKey:@"users"];
        
        NSMutableDictionary *userMutableDict = [NSMutableDictionary dictionary];

        if (![usersArray isKindOfClass:[NSNull class]]) {
#if DEBUG
            NSLog(@"Got %d users.", [usersArray count]);
#endif
            for (NSDictionary *userDict in usersArray) {
                User *user = [[User alloc] initFromDictionary:userDict];
                
                int venue_id = [[userDict objectForKey:@"venue_id"] integerValue];
                user.placeCheckedIn = [self.activeVenues objectForKey:[NSString stringWithFormat:@"%d", venue_id]];
    
                
                // add the user to the MapTabController activeUsers array
                [userMutableDict setObject:user forKey:[NSString stringWithFormat:@"%d", user.userID]];
            }
        } 
        self.activeUsers = [NSDictionary dictionaryWithDictionary:userMutableDict];
        userMutableDict = nil;
	}
	return self;
}

// called by the mapview after scrolling & zooming
// 
-(bool)isValidFor:(MKMapRect)newRegion
        mapCenter:(CLLocationCoordinate2D)mapCenter
{
	const double kTwoMinutesAgo = - 2 * 60;
	
	// if the data is old, we need to reload anyway
	double age = [self.dateLoaded timeIntervalSinceNow];
	if(self.dateLoaded && age < kTwoMinutesAgo) {
		NSLog(@".... data was too old (%.2f seconds old)", age);
		return false;
	}
    
    // if the center hasn't changed we don't need to reload data
    // unless it's stale which is handled above
    if(self.previousCenter.latitude == mapCenter.latitude &&
       self.previousCenter.longitude == mapCenter.longitude) {
        return true;
    }
    
	// if the new map region is contained within the region defined by the venues that are the furthest away
    // then we don't need to reload
	if(MKMapRectContainsRect(self.regionCovered, newRegion)) {
		return true;
    } else {
		return false;
	}
	
}

@end
