//
//  ChatHelper.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/23.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ChatHelper.h"
#import "OneOnOneChatViewController.h"
#import "CPAlertView.h"
#import "AppDelegate.h"

@implementation ChatHelper

+ (void)respondToIncomingChatNotification:(NSString *)message
                             fromNickname:(NSString *)nickname
                               fromUserId:(NSInteger)userId
                             withRootView:(UIViewController *)rootView
{
    OneOnOneChatViewController *chatView = nil;

    // See if we're in a chat few or not
    if ([[rootView.childViewControllers lastObject]
         isKindOfClass:[OneOnOneChatViewController class]]) {
        
        chatView = (OneOnOneChatViewController *) [rootView.childViewControllers lastObject];
    }
    
    // If the person is in the chat window AND is talking with the user that sent the chat
    // send the message straight to the chat window    
    if (chatView != nil && chatView.user.userID == userId) {
        [chatView receiveChatMessage:message];
    }
    // Otherwise send the message as a popup alert
    else
    {
        NSString *alertMessage = [NSString stringWithFormat:@"%@: %@",
                                  nickname,
                                  message];
        CPAlertView *alert = [[CPAlertView alloc]
                              initWithTitle:@"Incoming Chat"
                              message:alertMessage
                              delegate:self
                              cancelButtonTitle:@"Ignore"
                              otherButtonTitles: @"View", nil];
        
        NSDictionary *chatInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  message, @"message",
                                  [NSString stringWithFormat:@"%d", userId], @"userid",
                                  nickname, @"nickname",
                                  nil];
        alert.delegate = self;
        alert.context = chatInfo;
        alert.rootView = rootView;
        
        [alert show];
    }
}

#pragma mark - CPAlertView Delegate Functions

// This must be a class method (+) if being delegated by class methods.
+ (void)alertView:(CPAlertView *)alertView 
didDismissWithButtonIndex:(NSInteger)buttonIndex
{    
    if (alertView.title == @"Incoming Chat") {
        if (buttonIndex == 1) {
            NSString *userId   = [alertView.context objectForKey:@"userid"];
            NSString *message  = [alertView.context objectForKey:@"message"];
            NSString *nickname = [alertView.context objectForKey:@"nickname"];
            
            OneOnOneChatViewController *oneOnOneChat = [alertView.rootView.storyboard instantiateViewControllerWithIdentifier:@"OneOnOneChatView"];
            
            /*
            [alertView.rootView presentModalViewController:oneOnOneChat
                                                  animated:YES];
             */
            [alertView.rootView presentViewController:oneOnOneChat
                                             animated:YES
                                           completion:^(void) { }];

            oneOnOneChat.user = [[User alloc] init];
            oneOnOneChat.user.userID = [userId intValue];
            oneOnOneChat.user.nickname = nickname;
            [oneOnOneChat receiveChatMessage:message];
        }
    }
}


@end
