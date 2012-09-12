//
//  FeedPreviewHeaderCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 7/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "PostBaseCell.h"

#define PREVIEW_HEADER_CELL_HEIGHT 38
#define PREVIEW_POST_MAX_WIDTH 266

@class FeedPreviewCell;

@protocol FeedPreviewHeaderCellDelegate <NSObject>

- (void)removeButtonPressed:(FeedPreviewCell *)cell;

@end


@interface FeedPreviewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *venueNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *relativeTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;
@property (weak, nonatomic) id<FeedPreviewHeaderCellDelegate> delegate;

- (void)setFeedPreviewFooterCell:(UITableViewCell *)feedPreviewFooterCell withHeight:(CGFloat)height;
- (void)addPostCell:(PostBaseCell *)postCell withHeight:(CGFloat)height;

@end
