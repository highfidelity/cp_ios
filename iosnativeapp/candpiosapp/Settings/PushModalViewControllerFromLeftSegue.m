//
//  PushModalViewControllerFromLeftSegue.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 5/10/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "PushModalViewControllerFromLeftSegue.h"

#define PUSH_LEFT_AND_POP_ANIMATION_DURATION 0.35

@implementation PushModalViewControllerFromLeftSegue

- (void)perform {
    UIViewController *src = (UIViewController *) self.sourceViewController;
    UIViewController *dst = (UIViewController *) self.destinationViewController;
    float shift = [UIScreen mainScreen].bounds.size.width;
    
    src.view.transform = CGAffineTransformMakeTranslation(0, 0);
    dst.view.transform = CGAffineTransformMakeTranslation(-shift, -20);
    
    [UIView animateWithDuration:PUSH_LEFT_AND_POP_ANIMATION_DURATION
                     animations:^{
                         [src.view addSubview:dst.view];
                         src.view.transform = CGAffineTransformMakeTranslation(shift, 0);
                     }
                     completion:^(BOOL finished){
                         [src presentModalViewController:dst animated:NO];
                     }
     ];
}

@end

@implementation UIViewController (DismissPushModalViewControllerFromLeftSegue)

- (void)dismissPushModalViewControllerFromLeftSegue {
    UIViewController *src = (UIViewController *) self.navigationController;
    UIViewController *dst = (UIViewController *) self.presentingViewController;
    float shift = [UIScreen mainScreen].bounds.size.width;
    
    src.view.transform = CGAffineTransformMakeTranslation(0, 0);
    dst.view.transform = CGAffineTransformMakeTranslation(shift, 0);
    
    [UIView animateWithDuration:PUSH_LEFT_AND_POP_ANIMATION_DURATION
                     animations:^{
                         [src.view addSubview:dst.view];
                         src.view.transform = CGAffineTransformMakeTranslation(-shift, 0);
                     }
                     completion:^(BOOL finished){
                         [src dismissModalViewControllerAnimated:NO];
                     }
     ];
}

@end
