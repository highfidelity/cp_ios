//
//  MapTabController.h
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>


@interface MapTabController : UIViewController< MKMapViewDelegate, UINavigationControllerDelegate >
{
	bool hasUpdatedUserLocation;
	bool hasShownLoadingScreen;
}

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, readonly, strong) NSMutableArray *missions;

- (void)listButtonTapped;
- (void)refreshLocations;

@end
