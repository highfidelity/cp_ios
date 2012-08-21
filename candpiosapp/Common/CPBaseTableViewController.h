//
//  CPBaseTableViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 5/18/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPUserActionCell.h"

@interface CPBaseTableViewController : UITableViewController <UIActionSheetDelegate, CPUserActionCellDelegate>

@property (strong, nonatomic) UIActivityIndicatorView *barSpinner;
@property (weak, nonatomic) id delegate;

- (void)placeSpinnerOnRightBarButtonItem;
- (void)showCorrectLoadingSpinnerForCount:(int)count;
- (void)stopAppropriateLoadingSpinner;

@end
