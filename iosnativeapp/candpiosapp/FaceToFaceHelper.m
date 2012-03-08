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
#import "User.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"

@implementation FaceToFaceHelper


+ (void)presentF2FInviteFromUser:(int)userId
                        fromView:(UIViewController *)view
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
    [SVProgressHUD showWithStatus:@"Recieving F2F Invite"];
    
    // get the FaceToFace storyboard
    UIStoryboard *f2fstory = [UIStoryboard storyboardWithName:@"FaceToFaceStoryboard_iPhone" bundle:nil];
    
    // instantiate a FacetoFaceInviteViewController to show the F2F invite
    FaceToFaceAcceptDeclineViewController *f2fVC = [f2fstory instantiateInitialViewController];
    
    // setup a user that we will pass to the UserProfileCheckedInViewController
    User *user = [[User alloc] init];
    user.userID = userId;
    
    // load the user's data so the F2F invite screen will show it all when it gets presented
    [user loadUserResumeData:^(User *user, NSError *error){
        if (!error) {     
            f2fVC.user = user;
            
            // dismiss the SVProgress HUD, we're going to show the F2F invite modal
            [SVProgressHUD dismiss];
            
            // show the modal view controller
            [view presentModalViewController:f2fVC animated:YES];
        } else {
            // dismiss the SVProgress HUD with an error
            [SVProgressHUD dismiss];
            NSString *alertMsg = [NSString stringWithFormat:
                                  @"Oops! We couldn't get the data.\nAsk the sender to invite you again."];
            
            // Show password to this user
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Face to Face"
                                  message:alertMsg
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles: nil];
            [alert show];
        }        
    }];
}

+ (void)presentF2FAcceptFromUser:(int) userId
                    withPassword:(NSString *)password
                        fromView:(UIViewController *)view
{    
    NSString *alertMsg = [NSString stringWithFormat:
                          @"The Face to Face password is: %@", password];
    
    // Show password to this user
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Face to Face"
                          message:alertMsg
                          delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: nil];
    [alert show];
}

+ (void)presentF2FSuccessFrom:(NSString *) nickname
                     fromView:(UIViewController *) view
{
    NSString *alertMsg = [NSString stringWithFormat:
                          @"Awesome! You met %@ Face to Face!", nickname];

    // Show error if we got one
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Face to Face"
                          message:alertMsg
                          delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: nil];
    [alert show];
}

@end
