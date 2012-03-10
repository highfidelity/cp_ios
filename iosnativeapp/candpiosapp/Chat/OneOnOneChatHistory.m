//
//  OneOnOneChatHistory.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/03/09.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "OneOnOneChatHistory.h"
#import "CPapi.h"
#import "SVProgressHUD.h"

@implementation OneOnOneChatHistory

@synthesize myUser = _myUser;
@synthesize otherUser = _otherUser;

- (id)initWithMyUser:(User *)myUser
        andOtherUser:(User *)otherUser
{
    self = [super init];
    
    if (myUser == nil || otherUser == nil)
    {
        @throw [NSException exceptionWithName:@"NIL user object"
                                       reason:@"User objects must be defined."
                                     userInfo:nil];
    }
    
    self.myUser = myUser;
    self.otherUser = otherUser;
    
    return self;
}

- (void)loadChatHistory
{
    [SVProgressHUD showWithStatus:@"Loading chat..."];
    
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
            NSLog(@"Chat history dict: %@", jsonResponse);
            
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
