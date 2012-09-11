//
//  FeedPreviewHeaderCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 7/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "FeedPreviewCell.h"

@interface FeedPreviewCell ()

@property (nonatomic) UITableViewCell *feedPreviewFooterCell;

@end


@implementation FeedPreviewCell

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
    
    [self.feedPreviewFooterCell removeFromSuperview];
    self.feedPreviewFooterCell = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.feedPreviewFooterCell) {
        CGRect feedPreviewFooterCellFrame = self.feedPreviewFooterCell.frame;
        feedPreviewFooterCellFrame.origin.x = 0;
        feedPreviewFooterCellFrame.origin.y = self.frame.size.height - feedPreviewFooterCellFrame.size.height;
        feedPreviewFooterCellFrame.size.width = self.frame.size.width;
        
        self.feedPreviewFooterCell.frame = feedPreviewFooterCellFrame;
    }
}

#pragma mark - actions

- (void)removeButtonAction {
    [self.delegate removeButtonPressed:self];
}

#pragma mark - public

- (void)setFeedPreviewFooterCell:(UITableViewCell *)feedPreviewFooterCell withHeight:(CGFloat)height {
    [self.feedPreviewFooterCell removeFromSuperview];
    
    self.feedPreviewFooterCell = feedPreviewFooterCell;
    self.feedPreviewFooterCell.frame = CGRectMake(0, 0, 0, height);
    [self addSubview:self.feedPreviewFooterCell];
    
    [self setNeedsLayout];
}

@end
