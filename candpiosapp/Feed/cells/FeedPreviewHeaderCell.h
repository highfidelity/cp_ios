//
//  FeedPreviewHeaderCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 7/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//


@class FeedPreviewHeaderCell;

@protocol FeedPreviewHeaderCellDelegate <NSObject>

- (void)removeButtonPressed:(FeedPreviewHeaderCell *)cell;

@end


@interface FeedPreviewHeaderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *venueNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *relativeTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;
@property (weak, nonatomic) id<FeedPreviewHeaderCellDelegate> delegate;

@end
