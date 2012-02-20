//
//  FaceToFaceHelper.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/17.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//
//  Functions to help you do things related to Face to Face!

#import "FaceToFaceHelper.h"
#import "FaceToFaceInviteController.h"
#import "User.h"

@implementation FaceToFaceHelper


+ (void)presentF2FInviteFromUser:(int) userId
                        fromView:(UIViewController *)view
{    
    FaceToFaceInviteController *f2fView = [view.storyboard instantiateViewControllerWithIdentifier:@"FaceToFaceInviteView"];
    
    f2fView.user = [[User alloc] init];
    f2fView.user.userID = userId;
    
    [view presentModalViewController:f2fView animated:YES];
}

+ (void)presentF2FAcceptFromUser:(int) userId
                    withPassword:(NSString *)password
                        fromView:(UIViewController *)view
{    
    FaceToFaceInviteController *f2fView = [view.storyboard instantiateViewControllerWithIdentifier:@"FaceToFaceInviteView"];
    
    f2fView.user = [[User alloc] init];
    f2fView.user.userID = userId;
    f2fView.passwordMode = [NSString stringWithString:password];
    
    [view presentModalViewController:f2fView animated:YES];
}

+ (void)presentF2FSuccessFrom:(NSString *) nickname
                     fromView:(UIViewController *) view
{
    NSString *alertMsg = [NSString stringWithFormat:
                          @"Oh snap! You met %@ Face to Face!", nickname];

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
