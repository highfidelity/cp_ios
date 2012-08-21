//
//  PillPopoverViewController.h
//  candpiosapp
//
//  Created by Andrew Hammond on 7/25/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PillPopoverViewController;

@protocol PillPopoverDelegate
- (void) pillPopover:(PillPopoverViewController*)pillPopoverViewController commentPressedForIndexPath:(NSIndexPath*)indexPath;
- (void) pillPopover:(PillPopoverViewController*)pillPopoverViewController plusOnePressedForIndexPath:(NSIndexPath*)indexPath;
@end

@interface PillPopoverViewController : UIViewController<UITextFieldDelegate>

@property (strong, nonatomic) CPPost *post;
@property (strong, nonatomic) NSIndexPath *indexPath;
@property (weak, nonatomic) IBOutlet UIButton *plusButton;
@property (weak, nonatomic) IBOutlet UIWebView *plusWebView;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UITextField *commentTextView;
@property (weak, nonatomic) IBOutlet UIImageView *commentImageView;
@property (weak, nonatomic) id<PillPopoverDelegate>delegate;

- (IBAction)plusButtonPressed:(id)sender;

@end
