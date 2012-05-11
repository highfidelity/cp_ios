//
//  CheckinChatEntry.h
//  candpiosapp
//
//  Created by Stephen Birarda on 5/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "VenueChatEntry.h"

#define CHECKIN_SYSTEM_CHAT_TYPE @"checkin"

@interface CheckinChatEntry : VenueChatEntry

- (CheckinChatEntry *)initFromJSON:(NSDictionary *)json 
                  dateFormatter:(NSDateFormatter *)dateFormatter;

@end
