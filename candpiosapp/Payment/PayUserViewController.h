//
//  PayUserViewController.h
//  candpiosapp
//
//  Created by Stojce Slavkovski on 18.2.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PayUserViewController : UIViewController <UITextFieldDelegate>
{
    IBOutlet UITextField *paymentAmount;
    IBOutlet UILabel *charsLeft;
    IBOutlet UILabel *payTo;
    __weak IBOutlet UITextField *paymentNote;
    __weak IBOutlet UIImageView *payeeImage;
    __weak IBOutlet UILabel *userBalance;
    __weak IBOutlet UIView *descriptionView;
    __weak IBOutlet UIButton *cancelButton;
    __weak IBOutlet UIButton *payButton;
}

@property (weak) User *user;

- (IBAction)makePayment:(id)sender;
- (IBAction)descriptionChanged:(id)sender;
- (IBAction)closeView:(UIButton *)sender;

@end
