//
//  LoveChatEntry.h
//  candpiosapp
//
//  Created by Stephen Birarda on 5/9/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "VenueChatEntry.h"

@interface LoveChatEntry : VenueChatEntry

@property (nonatomic, strong) User *sender;
@property (nonatomic, strong) User *recipient;

- (LoveChatEntry *)initFromJSON:(NSDictionary *)json 
                  dateFormatter:(NSDateFormatter *)dateFormatter;


@end
