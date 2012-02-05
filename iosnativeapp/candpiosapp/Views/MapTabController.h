//
//  MapTabController.h
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "OCMapView.h"

@class MapDataSet;

@interface MapTabController : UIViewController< MKMapViewDelegate, UINavigationControllerDelegate >
{
    OCMapView *mapView;
	bool hasUpdatedUserLocation;
	bool hasShownLoadingScreen;
}

@property (nonatomic, retain) IBOutlet OCMapView *mapView;
@property (nonatomic, readonly, strong) MapDataSet *dataset;

// State to prevent querying userlist (with bad region) before the map has appeared
// Although there is a delegate method, mapViewDidFinishLoadingMap:, this is not
// called if the map tiles have been cached (as of iOS 4).
@property (nonatomic) BOOL mapHasLoaded;

- (void)refreshLocations;
- (IBAction)refreshButtonClicked:(id)sender;
- (IBAction)locateMe:(id)sender;


@end

