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
@property (nonatomic) NSMutableArray *postCellsArray;

@end


@implementation FeedPreviewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.removeButton addTarget:self
                          action:@selector(removeButtonAction)
                forControlEvents:UIControlEventTouchUpInside];
    
    self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"list-arrow-big-light-grey.png"]];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.delegate = nil;

    // reset the frame of the venue name label
    self.venueNameLabel.frame = CGRectMake(self.venueNameLabel.frame.origin.x, 
                                           self.venueNameLabel.frame.origin.y, 235, 
                                           self.venueNameLabel.frame.size.height);
    
    for (FeedPreviewCell *postCell in self.postCellsArray) {
        [postCell removeFromSuperview];
    }
    [self.postCellsArray removeAllObjects];
    
    [self.feedPreviewFooterCell removeFromSuperview];
    self.feedPreviewFooterCell = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat lastOriginY = PREVIEW_HEADER_CELL_HEIGHT;
    for (PostBaseCell *postCell in self.postCellsArray) {
        CGRect postCellFrame = postCell.frame;
        postCellFrame.origin.x = 0;
        postCellFrame.origin.y = lastOriginY;
        postCellFrame.size.width = self.frame.size.width;
        
        postCell.frame = postCellFrame;
        
        lastOriginY += postCellFrame.size.height;
        
        CGRect entryLabelFrame = postCell.entryLabel.frame;
        entryLabelFrame.size.width = PREVIEW_POST_MAX_WIDTH - entryLabelFrame.origin.x;
        postCell.entryLabel.frame = entryLabelFrame;
        
        postCell.entryLabel.lineBreakMode = UILineBreakModeTailTruncation;
    }
    
    if ([self.postCellsArray count]) {
        self.accessoryView.hidden = NO;
        self.accessoryView.frame = CGRectMake(285,
                                              roundf((self.frame.size.height - self.accessoryView.frame.size.height) / 2 - 5),
                                              self.accessoryView.frame.size.width,
                                              self.accessoryView.frame.size.height);
        [self bringSubviewToFront:self.accessoryView];
    } else {
        self.accessoryView.hidden = YES;
    }
    
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
    feedPreviewFooterCell.frame = CGRectMake(0, 0, 0, height);
    feedPreviewFooterCell.userInteractionEnabled = NO;
    [self addSubview:feedPreviewFooterCell];
    
    [self setNeedsLayout];
}

- (void)addPostCell:(PostBaseCell *)postCell withHeight:(CGFloat)height {
    if (!self.postCellsArray) {
        self.postCellsArray = [NSMutableArray arrayWithCapacity:3];
    }
    
    [self.postCellsArray addObject:postCell];
    postCell.frame = CGRectMake(0, 0, 0, height);
    postCell.userInteractionEnabled = NO;
    [self addSubview:postCell];
    [self bringSubviewToFront:postCell];
    
    [self setNeedsLayout];
}

@end
