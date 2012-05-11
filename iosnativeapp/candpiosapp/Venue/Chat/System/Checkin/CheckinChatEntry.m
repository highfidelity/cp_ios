//
//  CheckinChatEntry.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CheckinChatEntry.h"

@implementation CheckinChatEntry

- (CheckinChatEntry *)initFromJSON:(NSDictionary *)json 
                  dateFormatter:(NSDateFormatter *)dateFormatter
{
    if (self = [super initFromJSON:json dateFormatter:dateFormatter]) {
        // the user for this chat entry should be the person who checked in
        self.user = [super userFromDictionaryOrActiveUsers:[json valueForKeyPath:@"system_data.user"]];
    }
    return self;
}

@end
