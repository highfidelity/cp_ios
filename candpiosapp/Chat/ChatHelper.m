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
#import "GTMNSString+HTML.h"

#define kChatAlertTag 8001

@implementation ChatHelper

+ (void)respondToIncomingChatNotification:(NSString *)message
                             fromNickname:(NSString *)nickname
                               fromUserId:(NSInteger)userId
                             withRootView:(UIViewController *)rootView
{

    NSString *unescapedMessage = [message gtm_stringByUnescapingFromHTML];
    OneOnOneChatViewController *chatView = nil;
    UIViewController *lastView = [rootView.childViewControllers lastObject];

    // See if we've navigated to the chat view from a user profile
    if ([lastView isKindOfClass:[OneOnOneChatViewController class]]) {
        
        chatView = (OneOnOneChatViewController *) [rootView.childViewControllers lastObject];
    }
    // See if we have a modal chat popup
    else if ([[[[lastView modalViewController]
                childViewControllers]
               lastObject]
              isKindOfClass:[OneOnOneChatViewController class]])
    {
        chatView = (OneOnOneChatViewController *)
        [[[lastView modalViewController] childViewControllers] lastObject];
    }    
    // See if we have a  child chat view
    else if ([[[lastView
                childViewControllers]
               lastObject] 
              isKindOfClass:[OneOnOneChatViewController class]])
    {
        chatView = (OneOnOneChatViewController *)
            [[lastView childViewControllers] lastObject];
    }
    else {
        NSUInteger childViewCount = [[rootView childViewControllers] count];
        UIViewController *parentView = nil;
        if (childViewCount > 2) {
            // from people>resume
            parentView = [rootView.childViewControllers objectAtIndex:2];
            if ([[[parentView childViewControllers] lastObject] isKindOfClass:[OneOnOneChatViewController class]]) {
                chatView = [[parentView childViewControllers] lastObject];
            }

            // from feeds>resume
            parentView = [rootView.childViewControllers objectAtIndex:0];
            if ([[[parentView childViewControllers] lastObject] isKindOfClass:[OneOnOneChatViewController class]]) {
                chatView = [[parentView childViewControllers] lastObject];
            }
        }
    }
    
    // If the person is in the chat window AND is talking with the user that
    // sent the chat send the message straight to the chat window    
    if (chatView != nil && chatView.user.userID == userId) {
        [chatView receiveChatText:unescapedMessage];
    }
    // Otherwise send the message as a popup alert
    else
    {
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
        alert.rootView = rootView;
        
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
            
            [alertView.rootView presentViewController:chatNavController
                                             animated:YES
                                           completion:nil];
        }
    }
}


@end
