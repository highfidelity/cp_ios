//
//  FacebookLoginSequence.h
//  candpiosapp
//
//  Created by David Mojdehi on 1/4/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginSequenceBase.h"

@interface FacebookLoginSequence : LoginSequenceBase<UIAlertViewDelegate>

-(void)initiateLogin:(UIViewController*)mapViewController;
-(void)handleResponseFromFacebookLogin;

@end
