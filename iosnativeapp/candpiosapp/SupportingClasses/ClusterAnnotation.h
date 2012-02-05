//
//  ClusterAnnotation.h
//  candpiosapp
//
//  Created by Stojce Slavkovski on 05.2.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface ClusterAnnotation : MKAnnotationView <MKAnnotation>{
    UILabel *label;   
}
- (void) setClusterText:(NSString *)text;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@end
