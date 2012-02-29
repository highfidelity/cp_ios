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
-(void)pushAliasUpdate;

@end
