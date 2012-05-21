//
//  UserProfileViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

typedef enum {
    UserProfileLoadActionNone = 0,
	UserProfileLoadActionLove
} UserProfileLoadAction;

@interface UserProfileViewController : UIViewController

@property (nonatomic, strong) User *user;
@property (nonatomic, assign) UserProfileLoadAction loadAction;
@property (assign, nonatomic) BOOL isF2FInvite;

- (IBAction)f2fInvite;
- (void)placeUserDataOnProfile;
- (void)refreshForNewLove;

@end
