//
//  CommentCell.h
//  candpiosapp
//
//  Created by Andrew Hammond on 7/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CommentCell, CPVenue;

@protocol CommentCellDelegate <NSObject>
- (void) showPillPopoverFromCell:(CommentCell*)cell;
@end

@interface CommentCell : UITableViewCell
@property (nonatomic, strong) CPPost *post;
@property (nonatomic, strong) UIButton *pillButton;
@property (nonatomic, strong) IBOutlet UIButton *placeholderPillButton;
@property (nonatomic, strong) UILabel *pillLabel;
@property (nonatomic, strong) id<CommentCellDelegate> delegate;
@property (nonatomic, strong) CPVenue *venue;

- (void) updatePillButtonAnimated:(BOOL)animated;

@end
