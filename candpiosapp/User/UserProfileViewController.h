//
//  UserProfileViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "CPUserActionCell.h"

@interface UserProfileViewController : UIViewController <UIScrollViewDelegate, CPUserActionCellDelegate>

@property (strong, nonatomic) CPUser *user;
@property (nonatomic) BOOL isF2FInvite;
@property (nonatomic) BOOL scrollToReviews;

- (void)placeUserDataOnProfile;

@end
