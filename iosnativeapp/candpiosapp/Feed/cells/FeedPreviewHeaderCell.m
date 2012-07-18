//
//  FeedPreviewHeaderCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 7/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "FeedPreviewHeaderCell.h"

@implementation FeedPreviewHeaderCell

@synthesize venueNameLabel = _venueNameLabel;
@synthesize relativeTimeLabel = _relativeTimeLabel;

- (void)prepareForReuse
{
    [super prepareForReuse];
    // reset the frame of the venue name label
    self.venueNameLabel.frame = CGRectMake(self.venueNameLabel.frame.origin.x, 
                                           self.venueNameLabel.frame.origin.y, 235, 
                                           self.venueNameLabel.frame.size.height);
}

@end
