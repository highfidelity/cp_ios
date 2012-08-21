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
@property (strong, nonatomic) CPPost *post;
@property (strong, nonatomic) CPVenue *venue;
@property (strong, nonatomic) UIButton *pillButton;
@property (strong, nonatomic) UILabel *pillLabel;
@property (weak, nonatomic) IBOutlet UIButton *placeholderPillButton;
@property (weak, nonatomic) id<CommentCellDelegate> delegate;


- (void) updatePillButtonAnimated:(BOOL)animated;

@end
