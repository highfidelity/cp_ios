//
//  MKAnnotationView+SpecialPin.h
//  candpiosapp
//
//  Created by Stephen Birarda on 9/20/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKAnnotationView (SpecialPin)

- (void)setPin:(NSInteger)number hasCheckins:(BOOL)checkins hasVirtual:(BOOL)virtual isSolar:(BOOL)solar withLabel:(BOOL)withLabel;

@end
