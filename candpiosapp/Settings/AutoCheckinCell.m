//
//  AutoCheckinCell.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 5/8/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "AutoCheckinCell.h"

@implementation AutoCheckinCell

- (IBAction)venueSwitchChanged:(UISwitch *)sender
{
    if (!sender.on) {
        self.venue.autoCheckin = NO;
        [CPAppDelegate stopMonitoringVenue:self.venue];
    }
    else {
        self.venue.autoCheckin = YES;
        [CPAppDelegate startMonitoringVenue:self.venue];
    }

    // Save the changes to pastVenues
    [CPAppDelegate updatePastVenue:self.venue];
}

@end
