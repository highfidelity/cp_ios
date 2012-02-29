//
//  EmailLoginSequence.h
//  candpiosapp
//
//  Created by David Mojdehi on 1/10/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginSequenceBase.h"


@interface EmailLoginSequence : LoginSequenceBase< UIAlertViewDelegate >
{
 @private
    NSString *signupNickname_;
    NSString *signupEmalAddress_;
    NSString *signupPassword_;
    NSString *signupConfirmPassword_;
}

-(void)initiateLogin:(UIViewController*)mapViewControllerArg;
-(void)initiateAccountCreation:(UIViewController*)hostController;

-(void)handleEmailLogin:(NSString*)username password:(NSString*)password;
@end
