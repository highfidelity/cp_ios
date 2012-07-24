//
//  CPLinkedInAPI.h
//  candpiosapp
//
//  Created by Tomáš Horáček on 5/23/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "OAMutableURLRequest.h"

@interface CPLinkedInAPI : NSObject

@property (nonatomic, readonly) OAToken *token;
@property (nonatomic, readonly) OAConsumer *consumer;

+ (CPLinkedInAPI *)shared;
- (OAMutableURLRequest *)linkedInJSONAPIRequestWithRelativeURL:(NSString *)urlString;

@end
