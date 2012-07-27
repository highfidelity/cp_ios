//
//  FeedViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPVenueFeed.h"
#import "CPUserActionCell.h"
#import "FeedPreviewHeaderCell.h"
#import "WEPopoverController.h"
#import "PostBaseCell.h"
#import "PillPopoverViewController.h"
#import "CommentCell.h"

@interface FeedViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, CPUserActionCellDelegate, FeedPreviewHeaderCellDelegate, WEPopoverControllerDelegate, PillPopoverDelegate, CommentCellDelegate>

@property (nonatomic, assign) IBOutlet UITableView *tableView;
@property (nonatomic, strong) CPVenueFeed *selectedVenueFeed;
@property (nonatomic, assign) CPPostType postType;
@property (nonatomic, strong) NSMutableArray *venueFeedPreviews;
@property (nonatomic, strong) NSMutableArray *postableVenueFeeds;
@property (nonatomic, assign) BOOL newPostAfterLoad;
@property (nonatomic, strong) NSMutableDictionary *postPlussingUserIds;
@property (nonatomic, strong) WEPopoverController *wePopoverController;
@property (nonatomic, strong) PillPopoverViewController *pillPopoverViewController;

- (void)showPillPopoverFromCell:(PostBaseCell*)cell;

- (void)newPost:(NSIndexPath *)replyToIndexPath;
- (void)showOnlyPostableFeeds;

+ (UIView *)timelineViewWithHeight:(CGFloat)height;

@end
