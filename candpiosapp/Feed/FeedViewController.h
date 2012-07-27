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

@interface FeedViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, CPUserActionCellDelegate, FeedPreviewHeaderCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) CPVenueFeed *selectedVenueFeed;
@property (strong, nonatomic) NSMutableArray *venueFeedPreviews;
@property (strong, nonatomic) NSMutableArray *postableVenueFeeds;
@property (strong, nonatomic) NSMutableDictionary *postPlussingUserIds;
@property (nonatomic) CPPostType postType;
@property (nonatomic) BOOL newPostAfterLoad;

- (void)newPost:(NSIndexPath *)replyToIndexPath;
- (void)showOnlyPostableFeeds;
+ (UIView *)timelineViewWithHeight:(CGFloat)height;

@end
