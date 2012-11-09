//
//  MKAnnotationView+SpecialPin.h
//  candpiosapp
//
//  Created by Stephen Birarda on 9/20/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKAnnotationView (SpecialPin)

- (void)setPin:(NSNumber *)number
   hasCheckins:(BOOL)checkins
   hasContacts:(BOOL)hasContacts
       isSolar:(BOOL)solar
     withLabel:(BOOL)withLabel;

@end
