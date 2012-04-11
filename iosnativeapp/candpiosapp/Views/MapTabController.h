//
//  MapTabController.h
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#define mapTag 992

@class MapDataSet;

@interface MapTabController : UIViewController <MKMapViewDelegate, UINavigationControllerDelegate>
{
	bool hasUpdatedUserLocation;
	bool hasShownLoadingScreen;
}

@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (nonatomic, readonly, strong) MapDataSet *dataset;
@property (weak, nonatomic) IBOutlet UIView *mapAndButtonsView;
@property (nonatomic, readonly) NSDictionary *activeUsers;
@property (nonatomic, readonly) NSArray *activeVenues;

// State to prevent querying userlist (with bad region) before the map has appeared
// Although there is a delegate method, mapViewDidFinishLoadingMap:, this is not
// called if the map tiles have been cached (as of iOS 4).
@property (nonatomic) BOOL mapHasLoaded;

- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (void)refreshLocations;
- (void)refreshLocationsAfterDelay;
- (IBAction)refreshButtonClicked:(id)sender;
- (IBAction)locateMe:(id)sender;
- (IBAction)revealButtonPressed:(id)sender;
- (void)loginButtonTapped;
- (void)logoutButtonTapped;

@end

