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
@property (nonatomic, strong) CPPost *post;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) id<PillPopoverDelegate>delegate;
@property (weak, nonatomic) IBOutlet UIButton *plusButton;
@property (weak, nonatomic) IBOutlet UIWebView *plusWebView;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UITextField *commentTextView;
@property (weak, nonatomic) IBOutlet UIImageView *commentImageView;
- (IBAction)plusButtonPressed:(id)sender;

@end
