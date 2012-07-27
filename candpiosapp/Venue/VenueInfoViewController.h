//
//  VenueInfoViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 3/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPVenue.h"

@interface VenueInfoViewController : UIViewController

@property (strong, nonatomic) CPVenue *venue;
@property (weak, nonatomic) IBOutlet UIImageView *venuePhoto;
@property (weak, nonatomic) IBOutlet UIView *firstAidSection;
@property (weak, nonatomic) IBOutlet UIView *userSection;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) NSMutableDictionary *categoryCount;
@property (strong, nonatomic) NSMutableDictionary *currentUsers;
@property (strong, nonatomic) NSMutableArray *previousUsers;
@property (strong, nonatomic) NSMutableSet *usersShown;
@property (strong, nonatomic) NSMutableDictionary *userObjectsForUsersOnScreen;
@property (nonatomic) BOOL scrollToUserThumbnail;


@end
