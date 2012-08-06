//
//  User.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "User.h"
#import "CPSkill.h"
#import "MapDataSet.h"
#import "GTMNSString+HTML.h"
#import "CPCheckinHandler.h"

@implementation User

@synthesize nickname = _nickname;
@synthesize userID = _userID;
@synthesize email = _email;
@synthesize title = _title;
@synthesize status = _status;
@synthesize skills = _skills;
@synthesize location = _location;
@synthesize bio = _bio;
@synthesize sponsorId = _sponsorId;
@synthesize sponsorNickname = _sponsorNickname;
@synthesize facebookVerified = _facebookVerified;
@synthesize linkedInVerified = _linkedInVerified;
@synthesize hourlyRate = _hourlyRate;
@synthesize totalEarned = _totalEarned;
@synthesize totalSpent = _totalSpent;
@synthesize photoURLString = _photoURLString;
@synthesize distance = _distance;
@synthesize checkedIn = _checkedIn;
@synthesize placeCheckedIn = _placeCheckedIn;
@synthesize checkoutEpoch = _checkoutEpoch;
@synthesize join_date = _join_date;
@synthesize trusted_by = _trusted_by;
@synthesize workInformation = _workInformation;
@synthesize educationInformation  = _educationInformation;
@synthesize jobTitle = _jobTitle;
@synthesize reviews = _reviews;
@synthesize checkInHistory = _checkInHistory;
@synthesize majorJobCategory = _majorJobCategory;
@synthesize minorJobCategory =  _minorJobCategory;
@synthesize enteredInviteCode = _enteredInviteCode;
@synthesize joinDate = _joinDate;
@synthesize badges = _badges;
@synthesize smartererName = _smartererName;
@synthesize checkInIsVirtual = _checkInIsVirtual;
@synthesize contactsOnlyChat = _contactsOnlyChat;
@synthesize isContact = _isContact;
@synthesize hasChatHistory = _hasChatHistory;
@synthesize totalHours = _totalHours;
@synthesize linkedInPublicProfileUrl = _linkedInPublicProfileUrl;
@synthesize numberOfContactRequests = _numberOfContactRequests;
@synthesize profileURLVisibility = _profileURLVisibility;

-(id)init
{
	self = [super init];
	if(self)
	{
        // init code here
	}
	return self;
}

-(id)initFromDictionary:(NSDictionary *)userDict
{
    self = [super init];
	if(self)
	{
        self.userID = [[userDict objectForKey:@"id"] integerValue];
        self.nickname = [userDict objectForKey:@"nickname"];
        
        self.status = [userDict objectForKey:@"status_text"];
        self.jobTitle = [userDict objectForKey:@"headline"];
        self.majorJobCategory = [userDict objectForKey:@"major_job_category"];
        self.minorJobCategory = [userDict objectForKey:@"minor_job_category"];
        self.jobTitle = [userDict objectForKey:@"headline"];
        
        self.photoURLString = [userDict objectForKey:@"filename"];
        
        double lat = [[userDict objectForKey:@"lat"] doubleValue];
        double lng = [[userDict objectForKey:@"lng"] doubleValue];
        self.location = CLLocationCoordinate2DMake(lat, lng);
        
        self.checkoutEpoch = [NSDate dateWithTimeIntervalSince1970:[[userDict objectForKey:@"checkout"] integerValue]];
        self.checkedIn = [[userDict objectForKey:@"checked_in"] boolValue];
        self.checkInIsVirtual = [[userDict objectForKey:@"is_virtual"] boolValue];
        self.isContact = [[userDict objectForKey:@"is_contact"] boolValue];
	}
	return self;
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) 
    {         
        self.userID = [decoder decodeIntForKey:@"userID"];
        self.nickname = [decoder decodeObjectForKey:@"nickname"];
        self.email = [decoder decodeObjectForKey:@"email"];
        self.photoURLString = [decoder decodeObjectForKey:@"photoURL"];
        self.enteredInviteCode = [decoder decodeBoolForKey:@"enteredInviteCode"];
        self.joinDate = [decoder decodeObjectForKey:@"joinDate"];
        self.skills = [decoder decodeObjectForKey:@"skills"];
        self.profileURLVisibility = [decoder decodeObjectForKey:@"profileURLVisibility"];

        self.majorJobCategory = [decoder decodeObjectForKey:@"majorJobCategory"];
        self.minorJobCategory = [decoder decodeObjectForKey:@"minorJobCategory"];
    }    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInt:self.userID forKey:@"userID"];
    [encoder encodeObject:self.nickname forKey:@"nickname"];
    [encoder encodeObject:self.email forKey:@"email"];
    [encoder encodeObject:self.photoURLString forKey:@"photoURL"];
    [encoder encodeBool:self.enteredInviteCode forKey:@"enteredInviteCode"];
    [encoder encodeObject:self.joinDate forKey:@"joinDate"];
    [encoder encodeObject:self.skills forKey:@"skills"];
    [encoder encodeObject:self.profileURLVisibility forKey:@"profileURLVisibility"];

    [encoder encodeObject:self.majorJobCategory forKey:@"majorJobCategory"];
    [encoder encodeObject:self.minorJobCategory forKey:@"minorJobCategory"];
}

// override nickname setter to decode html entities
- (void)setNickname:(NSString *)nickname
{
    if ([nickname isKindOfClass:[NSNull class]]) {
        _nickname = @"";
    } else {
        _nickname = [nickname gtm_stringByUnescapingFromHTML];
    }  
}

// override nickname setter to decode html entities
- (void)setStatus:(NSString *)status
{
    if ([status isKindOfClass:[NSNull class]]) {
        status = @"";
    }
    
    if ([status length] > 0) {
        status = [status gtm_stringByUnescapingFromHTML];
        status = [status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }    
    _status = status;
}

// override rate setter to decode any html entities
- (void)setHourlyRate:(NSString *)hourlyRate
{
    _hourlyRate = [hourlyRate gtm_stringByUnescapingFromHTML];
}

// override bio setter to decode any html entities
- (void)setBio:(NSString *)bio
{
    _bio = [bio gtm_stringByUnescapingFromHTML];
}

// override job title setter to decode html entities
-(void)setJobTitle:(NSString *)jobTitle
{
    if ([jobTitle isKindOfClass:[NSNull class]]) {
        _jobTitle = @"";
    } else {
        _jobTitle = [jobTitle gtm_stringByUnescapingFromHTML];
    }
}

// override setter for photoURLString so that we handle when it is nil
-(void)setPhotoURLString:(NSString *)photoURLString
{
    _photoURLString = [photoURLString isKindOfClass:[NSNull class]] ? nil : photoURLString;
}

-(NSURL *)photoURL
{
    return self.photoURLString ? [NSURL URLWithString:self.photoURLString] : nil;
}

- (NSString *)firstName
{
    // if the user has a space in their nickname just use the first part
    // otherwise use the whole name
    NSRange spaceRange = [self.nickname rangeOfString:@" "]; 
    NSString *firstName;
    
    if (spaceRange.location != NSNotFound) {
        firstName = [self.nickname substringToIndex:spaceRange.location];
    } else {
        firstName = self.nickname;
    }
    return firstName;
}

- (BOOL)hasAnyTopSkills {
    BOOL topSkill = NO;
    for (CPSkill *skill in self.skills) {
        if (skill.loveCount > 0) {
            topSkill = YES;
            break;
        }
    }
    return topSkill;
}

- (BOOL)hasAnyWorkInformation {
    return self.workInformation.count > 0;
}

- (BOOL)hasAnyEducationInformation {
    return self.educationInformation.count > 0;
}

- (BOOL)hasAnyBadges {
    return self.badges.count > 0;
}

- (NSMutableArray *)favoritePlaces {
    NSMutableArray *places = [NSMutableArray arrayWithCapacity:3];
    
    int placeCount = 1;
    for (CPVenue *place in self.checkInHistory) { 
        if (placeCount == 4) {
            break;
        }
        [places addObject:place];
        placeCount++;
    }
    
    return places;
}

- (BOOL)hasAnyFavoritePlaces {
    return self.favoritePlaces.count > 0;
}

- (void)setEnteredInviteCodeFromJSONString:(NSString *)enteredInviteCodeString {
    if ([@"Y" isEqual:enteredInviteCodeString]) {
        self.enteredInviteCode = YES;
    } else {
        self.enteredInviteCode = NO;
    }
}

- (void)setJoinDateFromJSONString:(NSString *)dateString {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd  HH:mm:ss"];
    
    self.joinDate = [dateFormat dateFromString:dateString];
}

- (BOOL)isDaysOfTrialAccessWithoutInviteCodeOK {
    if ([self enteredInviteCode]) {
        return YES;
    }
    
    NSTimeInterval timeIntervalOfTrialAccess = kDaysOfTrialAccessWithoutInviteCode * 24 * 60 * 60;
    if (0 > timeIntervalOfTrialAccess + [self.joinDate timeIntervalSinceNow]) {
        return NO;
    }
    
    return YES;
}

-(void)loadUserResumeData:(void (^)(NSError *error))completion {
    
    [CPapi getResumeForUserId:self.userID andCompletion:^(NSDictionary *response, NSError *error) {
        
        if (!error) {
            NSDictionary *userDict = [response objectForKey:@"payload"];

            // only add the extra info we get because of resume here
            
            self.nickname = [userDict objectForKey:@"nickname"];

            self.majorJobCategory = [userDict objectForKey:@"major_job_category"];
            self.minorJobCategory = [userDict objectForKey:@"minor_job_category"];
            self.contactsOnlyChat = [[userDict objectForKey:@"contacts_only_chat"] boolValue];
            self.isContact = [[userDict objectForKey:@"user_is_contact"] boolValue];
            self.hasChatHistory = [[userDict objectForKey:@"has_chat_history"] boolValue];

            self.status = [[userDict objectForKey:@"status_text"]
                           stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if ([[userDict objectForKey:@"sponsorNickname"] isKindOfClass:[NSString class]]) {
                self.sponsorNickname = [userDict objectForKey:@"sponsorNickname"];
            }
            
            if ([[userDict objectForKey:@"sponsorId"] isKindOfClass:[NSString class]]) {
                self.sponsorId = [[userDict objectForKey:@"sponsorId"] intValue];
            }
            
            if ([[userDict objectForKey:@"job_title"] isKindOfClass:[NSString class]]) {
                self.jobTitle = [userDict objectForKey:@"job_title"];
            }
            // set the user's photo url        
            self.photoURLString = [userDict objectForKey:@"urlPhoto"];
            self.location = CLLocationCoordinate2DMake(
                                                       [[userDict valueForKeyPath:@"location.lat"] doubleValue],
                                                       [[userDict valueForKeyPath:@"location.lng"] doubleValue]);
            
            // set the booleans if the user is facebook/linkedin verified
            self.facebookVerified = [[userDict valueForKeyPath:@"verified.facebook.verified"] boolValue];
            self.linkedInVerified = [[userDict valueForKeyPath:@"verified.linkedin.verified"] boolValue];
            
            // get the linkedin profile url
            self.linkedInPublicProfileUrl = [userDict objectForKey:@"linkedin_public_profile_url"];
            self.numberOfContactRequests = [userDict objectForKey:@"number_of_contact_requests"];
            
            // get the users hourly_billing_rate if it isn't null
            // set it to N/A if it's empty
            if ([[userDict objectForKey:@"hourly_billing_rate"] isKindOfClass:[NSString class]]) {
                self.hourlyRate = [userDict objectForKey:@"hourly_billing_rate"];
            } else {
                self.hourlyRate = @"N/A";
            }
            
            // set the rest of the user info based on information in the userDict
            self.totalEarned = [[userDict valueForKeyPath:@"stats.totalEarned"] doubleValue];
            self.totalSpent = [[userDict valueForKeyPath:@"stats.totalSpent"] doubleValue];
            self.totalHours = [[userDict valueForKeyPath:@"stats.totalHours"] intValue];
            
            // bio, join date, number of users trusted by
            self.bio = [userDict objectForKey:@"bio"];
            self.join_date = [userDict objectForKey:@"joined"];
            self.trusted_by = [[userDict objectForKey:@"trusted"] intValue];
            
            self.reviews = [userDict objectForKey:@"reviews"];
            
            // create a CPSkill object for each of the skills we get back for this user
            NSMutableArray *skills = [NSMutableArray array];
            for (NSDictionary *skillDict in [userDict objectForKey:@"skills"]) {
                [skills addObject:[[CPSkill alloc] initFromDictionary:skillDict]];
            }
            self.skills = skills;
            
            // work and education
            self.workInformation = [userDict objectForKey:@"work"];
            self.educationInformation = [userDict objectForKey:@"education"];

            // badge information
            // self.badges = [userDict objectForKey:@"badges"];
            
            if (!self.placeCheckedIn) {
                // we don't have a check in for this user so pull it here
                NSDictionary *checkinDict = [userDict valueForKey:@"checkin_data"];
                if ([checkinDict objectForKey:@"venue_id"]) {
                    // try and grab the venue from the activeVenues from the map
                    CPVenue *venue = [[CPAppDelegate settingsMenuController].mapTabController venueFromActiveVenues:[[checkinDict objectForKey:@"venue_id"] integerValue]];
                    // otherwise alloc init one from the dictionary
                    if (!venue) {
                        venue = [[CPVenue alloc] initFromDictionary:checkinDict];
                    }
                    self.placeCheckedIn = venue;
                    self.checkedIn = [[checkinDict valueForKey:@"checked_in"] boolValue];

                    if ([CPUserDefaultsHandler currentUser] && [[CPUserDefaultsHandler currentUser] userID] == self.userID) {
                        if (self.checkedIn) {
                            NSInteger checkOutTime =[[checkinDict objectForKey:@"checkout"] integerValue];
                            [[CPCheckinHandler sharedHandler] saveCheckInVenue:venue andCheckOutTime:checkOutTime];
                        } else {
                            [[CPCheckinHandler sharedHandler] setCheckedOut];
                        }
                    }
                }
            }
            
            // user checkin data
            self.placeCheckedIn.checkinCount = [[userDict valueForKeyPath:@"checkin_data.users_here"] intValue];
            self.checkoutEpoch = [NSDate dateWithTimeIntervalSince1970:[[userDict valueForKeyPath:@"checkin_data.checkout"] intValue]]; 
            //self.checkedIn = [[userDict objectForKey:@"checked_in"] boolValue];
            
            // checkin history
            self.checkInHistory = [NSMutableArray array];
            for (NSDictionary *placeDict in [userDict valueForKey:@"checkin_history"]) {
                CPVenue *place = [CPVenue new];
                place.checkinCount = [[placeDict valueForKey:@"checkin_count"] intValue];
                place.checkinTime = [[placeDict valueForKey:@"checkin_time"] intValue];
                place.venueID = [[placeDict valueForKey:@"venue_id"] intValue];
                place.foursquareID = [placeDict valueForKey:@"foursquare_id"];
                place.name = [placeDict valueForKey:@"name"];
                place.address = [placeDict valueForKey:@"address"];
                place.city = [placeDict valueForKey:@"city"];
                place.state = [placeDict valueForKey:@"state"];
                place.zip = [placeDict valueForKey:@"zip"];
                place.phone = [placeDict valueForKey:@"phone"];
                place.photoURL = [placeDict valueForKey:@"photo_url"];
                [self.checkInHistory addObject:place];
            }
            
            // user email
            self.email = [userDict objectForKey:@"email"];
            
            self.profileURLVisibility = [userDict objectForKey:@"profileURL_visibility"];
            
            [self setEnteredInviteCodeFromJSONString:[userDict objectForKey:@"entered_invite_code"]];
            [self setJoinDateFromJSONString:[userDict objectForKey:@"join_date"]];

            if ([[userDict objectForKey:@"smarterer_name"] isKindOfClass:[NSString class]]) {
                self.smartererName = [userDict objectForKey:@"smarterer_name"];
            }
            
            // call the completion block passed by the caller
            if(completion) {
                completion(nil);
            }
        } else {
            if (completion) 
                completion(error);
        }       
    }];
}

- (NSComparisonResult) compareDistanceToUser:(User *)otherUser {
    NSNumber *distanceA = [NSNumber numberWithDouble:self.distance];
    NSNumber *distanceB = [NSNumber numberWithDouble:otherUser.distance];
    
    return [distanceA compare:distanceB];
}

@end
