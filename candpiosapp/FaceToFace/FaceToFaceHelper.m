//
//  FaceToFaceHelper.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/17.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//
//  Functions to help you do things related to Face to Face!

#import "FaceToFaceHelper.h"
#import "FaceToFaceAcceptDeclineViewController.h"
#import "CPUserSessionHandler.h"
#import "ContactListViewController.h"

@implementation FaceToFaceHelper

#pragma mark - Class Methods

static FaceToFaceHelper *sharedHelper;

+ (void)initialize
{
    if(!sharedHelper) {
        sharedHelper = [[self alloc] init];
    }
}

+ (FaceToFaceHelper *)sharedHelper
{
    return sharedHelper;
}

+ (void)presentF2FInviteFromUser:(int)userId
{   
    
#if DEBUG
    NSLog(@"Recieved a F2F Invite from user with ID %d", userId);
#endif
    
    // make sure that we're not already showing another modal view controller
    if ([CPAppDelegate tabBarController].presentedViewController) {
        
        // we have another modal on screen
        // if it's this same request already on screen we're not going to do anything
        if (![[CPAppDelegate tabBarController].presentedViewController isKindOfClass:[FaceToFaceAcceptDeclineViewController class]] ||
            ((FaceToFaceAcceptDeclineViewController *)[CPAppDelegate tabBarController].presentedViewController).user.userID != userId) {
            
            // new contact request ... don't take over the screen but give the user an alert
            UIAlertView *contactRequestAlert = [[UIAlertView alloc] initWithTitle:@"New contact request!"
                                       message:@"Please go to your contact list to accept or decline."
                                      delegate:nil
                             cancelButtonTitle:@"Close"
                             otherButtonTitles:nil];
            
            [contactRequestAlert show];
            
            // tell the ContactListViewController to update so the badge is correct
            [ContactListViewController getNumberOfContactRequestsAndUpdateBadge];
        }
    } else {
        
        // no other modal on screen, good to go for display of contact request
        
#if DEBUG
        NSLog(@"Display an F2F Invite from user with ID %d", userId);
#endif
        
        // Show the SVProgressHUD so the user knows they're waiting for an invite
        [SVProgressHUD showWithStatus:@"Receiving Contact Request..."];
        
        // get the FaceToFace storyboard
        UIStoryboard *f2fstory = [UIStoryboard storyboardWithName:@"FaceToFaceStoryboard_iPhone" bundle:nil];
        
        // instantiate a FacetoFaceInviteViewController to show the F2F invite
        FaceToFaceAcceptDeclineViewController *f2fVC = [f2fstory instantiateInitialViewController];
        
        // setup a user that we will pass to the UserProfileViewController
        User *user = [[User alloc] init];
        user.userID = userId;
        
        // load the user's data so the F2F invite screen will show it all when it gets presented
        [user loadUserResumeOnQueue:nil completion:^(NSError *error){
            if (!error) {
                f2fVC.user = user;
                
                // dismiss the SVProgress HUD, we're going to show the F2F invite modal
                [SVProgressHUD dismiss];
                
                // show the modal view controller
                [[CPAppDelegate tabBarController] presentModalViewController:f2fVC animated:YES];
            } else {
                // dismiss the SVProgress HUD with an error
                NSString *alertMsg = @"Oops! We couldn't get the data.\nAsk the sender to send Contact Request again.";
                
          
                [SVProgressHUD dismissWithError:alertMsg
                                     afterDelay:kDefaultDismissDelay];
            }        
        }];
    }
}

+ (void)presentF2FSuccessFrom:(NSString *) nickname
{
    NSString *alertMsg = [NSString stringWithFormat:
                          @"Awesome! %@ has been added as a Contact!", nickname];
    
    [SVProgressHUD showSuccessWithStatus:alertMsg
                                duration:kDefaultDismissDelay];
}

#pragma mark - Instance Methods

- (void)showContactRequestActionSheetForUserID:(int)userID
{
    // Offer to exchange contacts
    
    // make sure that the
    if (![CPUserDefaultsHandler currentUser]) {
        [CPUserSessionHandler showLoginBanner];
    } else if (userID == [CPUserDefaultsHandler currentUser].userID) {
        // cheeky response for self-talk
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Add a Contact"
                                                            message:@"You should have already met yourself..."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        
    } else {
        // alloc-init the UIActionSheet
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Request to exchange contact info?"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:@"Send"
                                                        otherButtonTitles: nil];
        
        // use the ID of the user with which contact information is being exchanged
        // as the tag for the UIActionSheet
        actionSheet.tag = userID;
        
        // show the UIActionSheet in the passed view
        [actionSheet showFromTabBar:[CPAppDelegate tabBarController].tabBar];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [actionSheet cancelButtonIndex]) {
        [CPapi sendContactRequestToUserId:actionSheet.tag];
    }
}

@end
