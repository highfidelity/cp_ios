//
//  MapTabController.h
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "User.h"
#import "CPVenue.h"
#import <CoreLocation/CoreLocation.h>

#define mapTag 992

@class MapDataSet;

@interface MapTabController : UIViewController <MKMapViewDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate>
{
	bool hasUpdatedUserLocation;
	bool hasShownLoadingScreen;
}

@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (nonatomic, readonly, strong) MapDataSet *dataset;
@property (weak, nonatomic) IBOutlet UIView *mapAndButtonsView;

// State to prevent querying userlist (with bad region) before the map has appeared
// Although there is a delegate method, mapViewDidFinishLoadingMap:, this is not
// called if the map tiles have been cached (as of iOS 4).
@property (nonatomic) BOOL mapHasLoaded;

- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (void)refreshLocations;
- (void)refreshLocationsAfterDelay;
- (void)userCheckedIn:(NSNotification *)notification;
- (IBAction)refreshButtonClicked:(id)sender;
- (IBAction)locateMe:(id)sender;
- (void)loginButtonTapped;
- (void)logoutButtonTapped;

# pragma mark - Active Venue and Active User grabbing
- (User *)userFromActiveUsers:(int)userID;
- (CPVenue *)venueFromActiveVenues:(int)venueID;

@end

