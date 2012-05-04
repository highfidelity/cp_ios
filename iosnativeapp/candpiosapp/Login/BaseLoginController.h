//
//  BaseLoginController.h
//  candpiosapp
//
//  Created by Andrew Hammond on 2/28/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFHTTPClient.h"

@interface BaseLoginController : UIViewController

@property (nonatomic, strong) AFHTTPClient *httpClient;

+(void) pushAliasUpdate;

-(void) handleCommonCreate:(NSString*)username
                  password:(NSString*)password
                  nickname:(NSString*)nickname
                facebookId:(NSString*)facebookId
                completion:(void (^)(NSError *error, id JSON))completion;

@end
