//
//  UserProfileViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface UserProfileViewController : UIViewController

@property (strong, nonatomic) User *user;
@property (nonatomic) BOOL isF2FInvite;

- (IBAction)f2fInvite;
- (void)placeUserDataOnProfile;

@end
