//
//  VenueCell.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 21.3.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "VenueCell.h"

@implementation VenueCell
@synthesize venueDistance = _venueDistance;
@synthesize venueCheckins = _venueCheckins;
@synthesize venueAddress = _venueAddress;
@synthesize venueName = _venueName;
@synthesize venuePicture = _venuePicture;


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

- (void)awakeFromNib
{
    [self venuePicture].layer.shadowColor = [UIColor blackColor].CGColor;
    [self venuePicture].layer.shadowOffset = CGSizeMake(1, 1);
    [self venuePicture].layer.shadowOpacity = 0.5;
    [self venuePicture].layer.shadowRadius = 1.0;
}
@end
