//
//  AutoCheckinCell.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 5/8/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "AutoCheckinCell.h"

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
    NSLog(@"switch changed: %d for venue id %i: %@", sender.on, venue.venueID, venue.name);

    if (!sender.on) {
        [CPAppDelegate stopMonitoringVenue:venue];
    }
    else {
        [CPAppDelegate startMonitoringVenue:venue];
    }
}

@end
