//
//  VenueCell.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 21.3.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "VenueCell.h"
#import "CPUIHelper.h"

@implementation VenueCell

- (void)awakeFromNib
{    
    [CPUIHelper addShadowToView:self.venuePicture color:[UIColor blackColor] offset:CGSizeMake(1, 1) radius:0.5 opacity:1.0];

    [CPUIHelper changeFontForLabel:self.venueName toLeagueGothicOfSize:24];
    [CPUIHelper changeFontForLabel:self.venueAddress toLeagueGothicOfSize:24];
    [CPUIHelper changeFontForLabel:self.venueCheckins toLeagueGothicOfSize:18];
}
@end
