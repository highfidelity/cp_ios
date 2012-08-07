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

@synthesize venueName = _venueName;
@synthesize venueAddress = _venueAddress;
@synthesize venueSwitch = _venueSwitch;
@synthesize venue;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)venueSwitchChanged:(UISwitch *)sender
{
    if (!sender.on) {
        venue.autoCheckin = NO;
        [[CPGeofenceHandler sharedHandler] stopMonitoringVenue:venue];
    }
    else {
        venue.autoCheckin = YES;
        [[CPGeofenceHandler sharedHandler] startMonitoringVenue:venue];
    }

    // Save the changes to pastVenues
    [[CPGeofenceHandler sharedHandler] updatePastVenue:venue];
}

@end
