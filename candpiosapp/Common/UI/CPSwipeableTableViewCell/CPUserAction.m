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
#import "FaceToFaceHelper.h"

@implementation CPUserAction

# pragma mark - CPUserActionCellDelegate

+ (void)cell:(CPUserActionCell*)cell sendLoveFromViewController:(UIViewController*)viewController
{
    // only show the love modal if this user is logged in
    if (![CPUserDefaultsHandler currentUser]) {
        [CPUserSessionHandler showLoginBanner];
        cell.selected = NO;
        [cell highlight:NO];
        return;
    }    
    if ([cell.user.userID isEqualToNumber:[CPUserDefaultsHandler currentUser].userID]) {
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
        if (![cell.user.userID isEqualToNumber:[CPUserDefaultsHandler currentUser].userID]) {
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
        [cell highlight:NO];
        return;
    }
    if ([cell.user.userID isEqualToNumber:[CPUserDefaultsHandler currentUser].userID]) {
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
    [cell.user loadUserResumeOnQueue:nil completion:^(NSError *error) {
        if (!error) {
            if (cell.user.contactsOnlyChat && ![cell.user.isContact boolValue] && !cell.user.hasChatHistory) {
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
    // ask FaceToFaceHelper to display a UIActionSheet confirming the contact request
    [[FaceToFaceHelper sharedHelper] showContactRequestActionSheetForUserID:cell.user.userID];
    
    // slide the cell back
    [cell animateSlideButtonsWithNewCenter:cell.originalCenter delay:0 duration:0.2 animated:YES];
    
    // make sure the cell is no longer highlighted
    [cell highlight:NO];
}

+ (void)cell:(CPUserActionCell*)cell showProfileFromViewController:(UIViewController*)viewController
{
    if (![CPUserDefaultsHandler currentUser]) {
        [CPUserSessionHandler showLoginBanner];
        cell.selected = NO;
        [cell highlight:NO];
        return;
    }
    
    UserProfileViewController *userProfileViewController = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
    userProfileViewController.title = cell.user.nickname;
    
    // set the user object on the UserProfileVC to the user we just created
    userProfileViewController.user = cell.user;
    
    // push the UserProfileViewController onto the navigation controller stack
    [viewController.navigationController pushViewController:userProfileViewController animated:YES];
}


@end
