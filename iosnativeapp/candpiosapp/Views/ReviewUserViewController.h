//
//  ReviewUserViewController.h
//  candpiosapp
//
//  Created by liffeeyum on 29/03/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReviewUserViewController : UIViewController <UITextFieldDelegate>
{
    IBOutlet UITextField *description;
    IBOutlet UILabel *charsLeft;
    IBOutlet UILabel *receiverNickname;
    __weak IBOutlet UIButton *cancelButton;
    __weak IBOutlet UIButton *sendButton;
    __weak IBOutlet UIView *descriptionView;
    __weak IBOutlet UIImageView *receiverImage;
}

@property (weak) User *user;

- (IBAction)sendReview:(id)sender;
- (IBAction)descriptionChanged:(id)sender;
- (IBAction)closeView:(UIButton *)sender;

@end
