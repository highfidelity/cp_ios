//
//  MapTabController.h
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#define qUseDataSets							1

#if qUseDataSets
@class MapDataSet;
#endif
@interface MapTabController : UIViewController< MKMapViewDelegate, UINavigationControllerDelegate >
{
	bool hasUpdatedUserLocation;
	bool hasShownLoadingScreen;
}

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
#if qUseDataSets
@property (nonatomic, readonly, strong) MapDataSet *dataset;
#else
@property (nonatomic, readonly, strong) NSMutableArray *missions;
#endif

- (void)listButtonTapped;
- (void)refreshLocations;

@end

