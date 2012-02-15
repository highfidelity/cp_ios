//
//  LoginSequenceBase.h
//  candpiosapp
//
//  Created by David Mojdehi on 1/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@class AFHTTPClient;

@interface LoginSequenceBase : NSObject
@property (nonatomic, strong)   AFHTTPClient        *httpClient;
@property (nonatomic, weak)     UIViewController    *mapViewController;

-(void)handleEmailCreate:(NSString*)username 
				password:(NSString*)password
				nickname:(NSString*)nickname
			  completion:(void (^)(NSError *error, id JSON))completion;

-(void)finishLogin;

@end
