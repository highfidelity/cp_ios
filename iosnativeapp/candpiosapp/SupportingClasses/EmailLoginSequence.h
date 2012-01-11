//
//  EmailLoginSequence.h
//  candpiosapp
//
//  Created by David Mojdehi on 1/10/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface EmailLoginSequence : NSObject

-(void)initiateLogin:(UIViewController*)mapViewControllerArg;
-(void)initiateAccountCreation:(UIViewController*)hostController;

-(void)handleEmailCreate:(NSString*)username password:(NSString*)password nickname:(NSString*)nickname;
-(void)handleEmailLogin:(NSString*)username password:(NSString*)password;
-(void)handleForgotEmailLogin:(NSString*)username;

@end
