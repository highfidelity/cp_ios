//
//  OneOnOneChatHistory.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/03/09.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "OneOnOneChatHistory.h"
#import "GTMNSString+HTML.h"

@implementation OneOnOneChatHistory

- (id)initWithMyUser:(User *)myUser
        andOtherUser:(User *)otherUser
{
    if (self = [super init]) {
        if (myUser == nil || otherUser == nil)
        {
            @throw [NSException exceptionWithName:@"NIL user object"
                                           reason:@"User objects must be defined."
                                         userInfo:nil];
        }
        
        self.myUser = myUser;
        self.otherUser = otherUser;
    }
    
    return self;
}

- (void)loadChatHistoryWithSuccessBlock:(void (^)())successfulLoading
{
    [SVProgressHUD showWithStatus:@"Loading chat"];
    
    void (^completionBlock)(NSDictionary *, NSError *) =
        ^(NSDictionary *jsonResponse, NSError *error)
    {
        /* Response will be in the format:
            { chat: [
                {id: '10656',
                user_id: '69',
                entry_text: 'What happens when I do this?',
                nickname: 'Ryan',
                date: '1299275690',
                photo_url: 'http://..../whatever.jpg',
                receiving_user_id: '268',
                offer_id: null },
                { id: '10858',
         */
        
        BOOL respError = [[jsonResponse objectForKey:@"error"] boolValue];
        
        if (!error && !respError)
        {            
            for (NSDictionary *chatDict in [jsonResponse valueForKey:@"chat"])
            {
                //NSLog(@"chatDict: %@", chatDict);
                
                // Extract chat text from json...
                NSString *messageString = [[chatDict valueForKey:@"entry_text"] gtm_stringByUnescapingFromHTML];
                
                // Extract user details from json...
                User *fromUser = nil;
                User *toUser = nil;
                int chatUserId = [[chatDict valueForKey:@"user_id"] intValue];
                if (chatUserId == self.myUser.userID)
                {
                    fromUser = self.myUser;
                    toUser = self.otherUser;
                }
                else 
                {
                    fromUser = self.otherUser;
                    toUser = self.myUser;
                }
                
                // Extract date from json...
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:
                                [[chatDict valueForKey:@"date"] doubleValue]];
                
                ChatMessage *message = [[ChatMessage alloc] initWithMessage:messageString
                                                                     toUser:toUser
                                                                   fromUser:fromUser
                                                                       date:date];
                [self insertMessage:message];
            }
            
            // Run whatever completion code we need
            (void) successfulLoading();
            [SVProgressHUD dismiss];
        }
        else
        {
            [SVProgressHUD dismissWithError:@"Error loading chat."];
        }
    };
    
    [CPapi oneOnOneChatGetHistoryWith:self.otherUser
                           completion:completionBlock];
}

@end
