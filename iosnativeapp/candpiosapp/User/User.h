//
//  User.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CPVenue.h"

#define kDaysOfTrialAccessWithoutInviteCode 30

@interface User : NSObject <NSCoding>

@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, assign) int userID;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *jobTitle;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSArray *skills;
@property (nonatomic, readonly) BOOL hasAnyTopSkills;
@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic, strong) NSString *bio;
@property (nonatomic, assign) int sponsorId;
@property (nonatomic, strong) NSString *sponsorNickname;
@property (nonatomic, assign) BOOL facebookVerified;
@property (nonatomic, assign) BOOL linkedInVerified;
@property (nonatomic, strong) NSString *hourlyRate;
@property (nonatomic, assign) double totalEarned;
@property (nonatomic, assign) int totalHours;
@property (nonatomic, assign) double totalSpent;
@property (nonatomic, strong) NSString *photoURLString;
@property (nonatomic, assign) double distance;
@property (nonatomic, assign) BOOL checkedIn;
@property (nonatomic, strong) CPVenue *placeCheckedIn;
@property (nonatomic, strong) NSDate *checkoutEpoch;
@property (nonatomic, strong) NSString *join_date;
@property (nonatomic, assign) int trusted_by;
@property (nonatomic, strong) NSArray *workInformation;
@property (nonatomic, readonly) BOOL hasAnyWorkInformation;
@property (nonatomic, strong) NSArray *educationInformation;
@property (nonatomic, readonly) BOOL hasAnyEducationInformation;
@property (nonatomic, readonly) BOOL hasAnyBadges;
@property (nonatomic, strong) NSDictionary *reviews;
@property (nonatomic, strong) NSMutableArray *checkInHistory;
@property (nonatomic, readonly) NSMutableArray *favoritePlaces;
@property (nonatomic, readonly) BOOL hasAnyFavoritePlaces;
@property (nonatomic, strong) NSString *majorJobCategory;
@property (nonatomic, strong) NSString *minorJobCategory;
@property (nonatomic, assign) BOOL enteredInviteCode;
@property (nonatomic, strong) NSDate *joinDate;
@property (nonatomic, strong) NSMutableArray *badges;
@property (nonatomic, strong) NSString *smartererName;
@property (nonatomic, assign) BOOL checkInIsVirtual;
@property (nonatomic, assign) BOOL contactsOnlyChat;
@property (nonatomic, assign) BOOL contactsOnlyCheckIns;
@property (nonatomic, assign) BOOL isContact;
@property (nonatomic, strong) NSString *linkedInPublicProfileUrl;
@property (nonatomic, strong) NSNumber *numberOfContactRequests;
@property (nonatomic, strong) NSString *profileURLVisibility;


-(void)loadUserResumeData:(void (^)(NSError *error))completion;
-(id)initFromDictionary:(NSDictionary *)userDict;
-(NSString *)firstName;

-(NSURL *)photoURL;

- (void)setEnteredInviteCodeFromJSONString:(NSString *)enteredInviteCodeString;
- (void)setJoinDateFromJSONString:(NSString *)dateString;

- (BOOL)isDaysOfTrialAccessWithoutInviteCodeOK;
- (NSComparisonResult) compareDistanceToUser:(User *)otherUser;

@end
