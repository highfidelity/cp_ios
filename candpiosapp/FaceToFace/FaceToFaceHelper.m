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

@implementation FaceToFaceHelper


+ (void)presentF2FInviteFromUser:(int)userId
                        fromView:(SettingsMenuController *)view
{   
    
#if DEBUG
    NSLog(@"Recieved a F2F Invite from user with ID %d", userId);
#endif
    
    // make sure that we're not showing an invite from this user already
    if ([view isKindOfClass:[FaceToFaceAcceptDeclineViewController class]]) {
    
        FaceToFaceAcceptDeclineViewController *f2fview = (FaceToFaceAcceptDeclineViewController *)view;
        
        if (f2fview.user.userID == userId) {
            // we've already got an invite up from this user
            // return out of here
            return;
        }        
    }  
    
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
            [view presentModalViewController:f2fVC animated:YES];
        } else {
            // dismiss the SVProgress HUD with an error
            NSString *alertMsg = [NSString stringWithFormat:
                                  @"Oops! We couldn't get the data.\nAsk the sender to send Contact Request again."];

            [SVProgressHUD dismissWithError:alertMsg
                                 afterDelay:kDefaultDismissDelay];
        }        
    }];
}

+ (void)presentF2FAcceptFromUser:(int) userId
                    withPassword:(NSString *)password
                        fromView:(SettingsMenuController *)view
{    
    NSString *alertMsg = [NSString stringWithFormat:
                          @"The Contact Request password is: %@", password];
    
    if (view.f2fInviteAlert) {
        // dismiss the invite alert if it's still hanging around
        [view.f2fInviteAlert dismissWithClickedButtonIndex:0 animated:NO];
    }
    
    // Show password to this user
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Contact Request"
                          message:alertMsg
                          delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: nil];
    [alert show];
    
    view.f2fPasswordAlert = alert;
}

+ (void)presentF2FSuccessFrom:(NSString *) nickname
                     fromView:(SettingsMenuController *) view
{
    NSString *alertMsg = [NSString stringWithFormat:
                          @"Awesome! %@ has been added as a Contact!", nickname];

    // dismiss the password alert if it's still around so they don't stack
    [view.f2fPasswordAlert dismissWithClickedButtonIndex:0 animated:NO];

    [SVProgressHUD showSuccessWithStatus:alertMsg
                                duration:kDefaultDismissDelay];
}
@end
