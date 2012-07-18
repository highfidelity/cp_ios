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

@interface FeedViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, CPUserActionCellDelegate>

@property (nonatomic, assign) IBOutlet UITableView *tableView;
@property (nonatomic, strong) CPVenueFeed *selectedVenueFeed;
@property (nonatomic, strong) NSMutableArray *venueFeedPreviews;
@property (nonatomic, strong) NSMutableArray *postableVenueFeeds;
@property (nonatomic, assign) BOOL newPostAfterLoad;
@property (nonatomic, strong) NSMutableDictionary *postPlussingUserIds;

- (void)newPost;
- (void)showOnlyPostableFeeds;

+ (UIView *)timelineViewWithHeight:(CGFloat)height;

@end
