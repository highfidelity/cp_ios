//
//  LoveChatEntry.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/9/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LoveChatEntry.h"

@implementation LoveChatEntry

@synthesize recipient = _reciever;
@synthesize reviewID = _reviewID;
@synthesize plusOnes = _plusOnes;

- (NSMutableDictionary *)plusOnes{
    if (!_plusOnes) {
        _plusOnes = [[NSMutableDictionary alloc] init];
    }
    return _plusOnes;
}

- (LoveChatEntry *)initFromJSON:(NSDictionary *)json 
                  dateFormatter:(NSDateFormatter *)dateFormatter
{
    if (self = [super initFromJSON:json dateFormatter:dateFormatter]) {
        // the user for this chat entry should be the sender of love
        self.user = [super userFromDictionaryOrActiveUsers:[json valueForKeyPath:@"system_data.sender"]];
        // set our recipient property
        self.recipient = [super userFromDictionaryOrActiveUsers:[json valueForKeyPath:@"system_data.recipient"]];
        
        // grab the array of +1s from the response
        NSDictionary *plusOneResp = [json valueForKeyPath:@"system_data.plus_one"];
        
        // iterate through the +1s and add each of the users to our dict of plusOnes
        for (NSString *userID in plusOneResp) {
            User *p1User = [super userFromDictionaryOrActiveUsers:[plusOneResp objectForKey:userID]];
            [self.plusOnes setObject:p1User forKey:userID];
        }
        
        self.reviewID = [[json valueForKeyPath:@"system_data.review_id"] intValue];
    }
    return self;
}

@end
