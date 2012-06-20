//
//  CPBaseTableViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 5/18/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CPBaseTableViewController : UITableViewController

@property (nonatomic, strong) UIActivityIndicatorView *barSpinner;
@property (nonatomic, assign) id delegate;

- (void)placeSpinnerOnRightBarButtonItem;
- (void)showCorrectLoadingSpinnerForCount:(int)count;
- (void)stopAppropriateLoadingSpinner;

@end
