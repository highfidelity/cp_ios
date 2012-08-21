//
//  AutoCheckinCell.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 5/8/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "AutoCheckinCell.h"
#import "CPGeofenceHandler.h"

@implementation AutoCheckinCell

- (IBAction)venueSwitchChanged:(UISwitch *)sender
{
    if (!sender.on) {
        self.venue.autoCheckin = NO;
        [[CPGeofenceHandler sharedHandler] stopMonitoringVenue:self.venue];
    }
    else {
        self.venue.autoCheckin = YES;
        [[CPGeofenceHandler sharedHandler] startMonitoringVenue:self.venue];
    }

    // Save the changes to pastVenues
    [[CPGeofenceHandler sharedHandler] updatePastVenue:self.venue];
}

@end
