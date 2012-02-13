//
//  User.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CPPlace.h"

@interface User : NSObject

@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, assign) int userID;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic, strong) NSString *bio;
@property (nonatomic, assign) BOOL facebookVerified;
@property (nonatomic, assign) BOOL linkedInVerified;
@property (nonatomic, strong) NSString *hourlyRate;
@property (nonatomic, assign) double totalEarned;
@property (nonatomic, assign) double totalSpent;
@property (nonatomic, strong) NSURL *urlPhoto;
@property (nonatomic, strong) NSString *skills;
@property (nonatomic, assign) double distance;
@property (nonatomic, assign) BOOL checkedIn;
@property (nonatomic, strong) CPPlace *placeCheckedIn;
@property (nonatomic, strong) NSDate *checkoutEpoch;
@property (nonatomic, strong) NSString *join_date;
@property (nonatomic, assign) int trusted_by;

-(void)loadUserResumeData:(void (^)(User *user, NSError *error))completion;


@end
