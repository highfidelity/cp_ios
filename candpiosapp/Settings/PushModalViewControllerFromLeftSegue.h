//
//  PushModalViewControllerFromLeftSegue.h
//  candpiosapp
//
//  Created by Tomáš Horáček on 5/10/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

@interface PushModalViewControllerFromLeftSegue : UIStoryboardSegue

@end


@interface UIViewController (DismissPushModalViewControllerFromLeftSegue)

- (void)dismissPushModalViewControllerFromLeftSegue;
- (void)dismissPushModalViewControllerFromLeftSegueWithCompletion:(void (^)(void))completion;

@end
