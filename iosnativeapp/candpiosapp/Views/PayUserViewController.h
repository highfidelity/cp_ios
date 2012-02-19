//
//  PayUserViewController.h
//  candpiosapp
//
//  Created by Stojce Slavkovski on 18.2.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface PayUserViewController : UIViewController 
{
    IBOutlet UITextField *paymentAmount;
    IBOutlet UITextField *paymentNote;
    IBOutlet UILabel *responseText;
    IBOutlet UILabel *charsLeft;
    IBOutlet UILabel *payTo;
    IBOutlet UIView *messageView;
    IBOutlet UIView *paymentView;    
}

@property (weak) User *user;

- (IBAction)makePayment:(id)sender;
- (IBAction)closeModal:(id)sender;
- (IBAction)descriptionChanged:(id)sender;
- (IBAction)formatAmount:(id)sender;

@end
