//
//  VenueChatEntry.h
//  candpiosapp
//
//  Created by Stephen Birarda on 4/16/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VenueChat.h"

@interface VenueChatEntry : NSObject

@property (nonatomic, assign) int entryID;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) VenueChat *delegate;

- (VenueChatEntry *)initWithJSON:(NSDictionary *)json;

@end
