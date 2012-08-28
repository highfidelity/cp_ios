//
//  CPUserAction.m
//  candpiosapp
//
//  Created by Andrew Hammond on 7/10/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPUserAction.h"
#import "CPUserActionCell.h"
#import "UserLoveViewController.h"
#import "OneOnOneChatViewController.h"
#import "UserProfileViewController.h"
#import "CPUserSessionHandler.h"

@implementation CPUserAction

static UserProfileViewController* userProfileViewController;
+ (UserProfileViewController*)userProfileViewController 
{
    if (!userProfileViewController) {
        userProfileViewController = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
    } else {
        [userProfileViewController prepareForReuse];
    }
    return userProfileViewController;
}

# pragma mark - CPUserActionCellDelegate

+ (void)cell:(CPUserActionCell*)cell sendLoveFromViewController:(UIViewController*)viewController
{
    // only show the love modal if this user is logged in
    if (![CPUserDefaultsHandler currentUser]) {
        [CPUserSessionHandler showLoginBanner];
        cell.selected = NO;
        return;
    }    
    if (cell.user.userID == [CPUserDefaultsHandler currentUser].userID) {
        // cheeky response for self-talk
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Self-Love" 
                                                            message:@"Feeling lonely?  Try sharing some love with others." 
                                                           delegate:nil 
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    if ([CPUserDefaultsHandler currentUser]) {
        // only show the love modal if this isn't the user themselves
        if (cell.user.userID != [CPUserDefaultsHandler currentUser].userID) {
            UserLoveViewController *loveModal = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"SendLoveModal"];
            loveModal.user = cell.user;
            
            [viewController presentModalViewController:loveModal animated:YES];
        }
    }    
}
+ (void)cell:(CPUserActionCell*)cell sendMessageFromViewController:(UIViewController*)viewController
{
    // handle chat
    if (![CPUserDefaultsHandler currentUser]) {
        [CPUserSessionHandler showLoginBanner];
        cell.selected = NO;
        return;
    }    
    if (cell.user.userID == [CPUserDefaultsHandler currentUser].userID) {
        // cheeky response for self-talk
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Self-Chat" 
                                                            message:@"γνῶθι σεαυτόν (Know Thyself)\n--The Temple of Delphi" 
                                                           delegate:nil 
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    // get a user object with resume data.. which includes its contact settings
    [cell.user loadUserResumeData:^(NSError *error) {
        if (!error) {
            if (cell.user.contactsOnlyChat && !cell.user.isContact && !cell.user.hasChatHistory) {
                NSString *errorMessage = [NSString stringWithFormat:@"You can not chat with %@ until the two of you have exchanged contact information", cell.user.nickname];
                [SVProgressHUD showErrorWithStatus:errorMessage
                                          duration:kDefaultDismissDelay];
            } else {
                // push the chat controller
                OneOnOneChatViewController *chatViewController = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"OneOnOneChatView"];
                chatViewController.user = cell.user; 
                [viewController.navigationController pushViewController:chatViewController animated:YES];
            }
        } else {
            // error checking for load of user
            NSLog(@"Error in user load during chat request.");
        }
    }];
}

+ (void)cell:(CPUserActionCell*)cell exchangeContactsFromViewController:(UIViewController*)viewController
{
    // Offer to exchange contacts
    // handle chat
    if (![CPUserDefaultsHandler currentUser]) {
        [CPUserSessionHandler showLoginBanner];
        cell.selected = NO;
        return;
    }    
    if (cell.user.userID == [CPUserDefaultsHandler currentUser].userID) {
        // cheeky response for self-talk
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Add a Contact" 
                                                            message:@"You should have already met yourself..." 
                                                           delegate:nil 
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:kRequestToAddToMyContactsActionSheetTitle
                                  delegate:(id<UIActionSheetDelegate>)viewController
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:@"Send"
                                  otherButtonTitles: nil
                                  ];
    actionSheet.tag = cell.user.userID;
    [actionSheet showInView:viewController.view];    
}

+ (void)cell:(CPUserActionCell*)cell showProfileFromViewController:(UIViewController*)viewController
{
    NSLog(@"Show Profile called.");
    if (![CPUserDefaultsHandler currentUser]) {
        [CPUserSessionHandler showLoginBanner];
        cell.selected = NO;
        return;
    }
    UserProfileViewController *userProfileViewController = [CPUserAction userProfileViewController];
    userProfileViewController.title = cell.user.nickname;
    
    // push the UserProfileViewController onto the navigation controller stack
    NSLog(@"Push Profile called.");
    [viewController.navigationController pushViewController:userProfileViewController animated:YES];
    NSLog(@"Push Profile returned.");
    // set the user object on the UserProfileVC to the user we just created
    userProfileViewController.user = cell.user;
}


@end
