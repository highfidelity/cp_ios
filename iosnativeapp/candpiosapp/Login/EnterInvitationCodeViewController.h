//
//  EnterInvitationCodeViewController.h
//  candpiosapp
//
//  Created by Tomáš Horáček on 4/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

typedef enum {
    kEnterInvitationCodeViewControllerShouldDismiss = 0,
    kEnterInvitationCodeViewControllerShouldPop,
} EnterInvitationCodeViewControllerShouldDismissOrPop;

@interface EnterInvitationCodeViewController : UIViewController

@property (nonatomic, assign) BOOL dontShowTextNoticeAfterLaterButtonPressed;
@property (nonatomic, assign) EnterInvitationCodeViewControllerShouldDismissOrPop shouldDismissOrPop;

@end
