//
//  CPChatHelper.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/23.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPChatHelper.h"
#import "OneOnOneChatViewController.h"
#import "CPAlertView.h"
#import "GTMNSString+HTML.h"

#define kChatAlertTag 8001

@implementation CPChatHelper

static CPChatHelper *sharedHelper;

+ (void)initialize
{
    if (!sharedHelper) {
        sharedHelper = [[self alloc] init];
    }
}

+ (CPChatHelper *)sharedHelper
{
    return sharedHelper;
}

+ (void)respondToIncomingChatNotification:(NSString *)message
                             fromNickname:(NSString *)nickname
                               fromUserId:(NSInteger)userId
{

    NSString *unescapedMessage = [message gtm_stringByUnescapingFromHTML];
    
    if ([sharedHelper activeChatViewController].user.userID == userId) {
        
        // If the person is in the chat window AND is talking with the user that
        // sent the chat send the message straight to the chat window
        
        [[sharedHelper activeChatViewController] receiveChatText:unescapedMessage];
    } else {
        // Otherwise send the message as a popup alert
        
        NSString *alertMessage = [NSString stringWithFormat:@"%@: %@",
                                  nickname,
                                  unescapedMessage];
        CPAlertView *alert = [[CPAlertView alloc]
                              initWithTitle:@"Incoming Chat"
                              message:alertMessage
                              delegate:self
                              cancelButtonTitle:@"Ignore"
                              otherButtonTitles: @"View", nil];
        alert.tag = kChatAlertTag;
        
        NSDictionary *chatInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  unescapedMessage, @"message",
                                  [NSString stringWithFormat:@"%d", userId], @"userid",
                                  nickname, @"nickname",
                                  nil];
        alert.delegate = self;
        alert.context = chatInfo;
        
        [alert show];
    }
}

#pragma mark - CPAlertView Delegate Functions

// This must be a class method (+) if being delegated by class methods.
+ (void)alertView:(CPAlertView *)alertView 
didDismissWithButtonIndex:(NSInteger)buttonIndex
{    
    if (alertView.tag == kChatAlertTag) {
        if (buttonIndex == 1) {
            NSString *userId   = [alertView.context objectForKey:@"userid"];
            NSString *nickname = [alertView.context objectForKey:@"nickname"];
            
            OneOnOneChatViewController *oneOnOneChat = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"OneOnOneChatView"];
            
            UINavigationController *chatNavController = [[UINavigationController alloc] initWithRootViewController:oneOnOneChat];
            
            oneOnOneChat.user = [[User alloc] init];
            oneOnOneChat.user.userID = [userId intValue];
            oneOnOneChat.user.nickname = nickname;

            // Set up the view
            [oneOnOneChat addCloseButton];
            
            [[CPAppDelegate tabBarController] presentViewController:chatNavController
                                             animated:YES
                                           completion:nil];
        }
    }
}


@end
