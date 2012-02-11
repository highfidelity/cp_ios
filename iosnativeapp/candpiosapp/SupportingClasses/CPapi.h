//
//  CPapi.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/06.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//  
//  This is the (un)official C&P iOS API! These functions are to
//  be used to interact with the C&P web services.

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface CPapi : NSObject

@property (nonatomic, strong) AFHTTPClient *httpClient;

+(void)verifyLoginStatusWithBlock:(void(^)(void))successBlock
                     failureBlock:(void(^)(void))failureBlock;

+(void)sendOneOnOneChatMessage:(NSString *)message
                        toUser:(int) userId;

@end
