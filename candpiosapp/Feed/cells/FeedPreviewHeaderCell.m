//
//  FeedPreviewHeaderCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 7/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "FeedPreviewHeaderCell.h"


@implementation FeedPreviewHeaderCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.removeButton addTarget:self
                          action:@selector(removeButtonAction)
                forControlEvents:UIControlEventTouchUpInside];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.delegate = nil;

    // reset the frame of the venue name label
    self.venueNameLabel.frame = CGRectMake(self.venueNameLabel.frame.origin.x, 
                                           self.venueNameLabel.frame.origin.y, 235, 
                                           self.venueNameLabel.frame.size.height);
}

#pragma mark - actions

- (void)removeButtonAction {
    [self.delegate removeButtonPressed:self];
}

@end
