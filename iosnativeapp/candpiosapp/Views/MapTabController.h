//
//  MapTabController.h
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>


@interface MapTabController : UIViewController< MKMapViewDelegate >
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, readonly, strong) NSMutableArray *missions;
@end
