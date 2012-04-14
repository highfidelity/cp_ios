//
//  User.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "User.h"
#import "AFJSONRequestOperation.h"
#import "NSString+HTML.h"

@implementation User

@synthesize nickname = _nickname;
@synthesize userID = _userID;
@synthesize email = _email;
@synthesize title = _title;
@synthesize status = _status;
@synthesize location = _location;
@synthesize bio = _bio;
@synthesize facebookVerified = _facebookVerified;
@synthesize linkedInVerified = _linkedInVerified;
@synthesize hourlyRate = _hourlyRate;
@synthesize totalEarned = _totalEarned;
@synthesize totalSpent = _totalSpent;
@synthesize urlPhoto = _urlPhoto;
@synthesize skills = _skills;
@synthesize distance = _distance;
@synthesize checkedIn = _checkedIn;
@synthesize placeCheckedIn = _placeCheckedIn;
@synthesize checkoutEpoch = _checkoutEpoch;
@synthesize join_date = _join_date;
@synthesize trusted_by = _trusted_by;
@synthesize listingsAsClient = _listingsAsClient;
@synthesize listingsAsAgent = _listingsAsAgent;
@synthesize workInformation = _workInformation;
@synthesize educationInformation  = _educationInformation;
@synthesize jobTitle = _jobTitle;
@synthesize reviews = _reviews;
@synthesize checkInHistory = _checkInHistory;
@synthesize majorJobCategory = _majorJobCategory;
@synthesize minorJobCategory =  _minorJobCategory;
@synthesize enteredInviteCode = _enteredInviteCode;
@synthesize joinDate = _joinDate;

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
        
        NSString *photoString = [userDict objectForKey:@"filename"];
        if (![photoString isKindOfClass:[NSNull class]]) {
            self.urlPhoto = [NSURL URLWithString:photoString];
        }        
        
        double lat = [[userDict objectForKey:@"lat"] doubleValue];
        double lng = [[userDict objectForKey:@"lng"] doubleValue];
        self.location = CLLocationCoordinate2DMake(lat, lng);
        
        self.checkedIn = [[userDict objectForKey:@"checked_in"] boolValue];
        

        CPPlace *place = [[CPPlace alloc] init];
        
        NSString *name = [userDict objectForKey:@"venue_name"];
        
        if (![name isKindOfClass:[NSNull class]]) {
            place.name = [userDict objectForKey:@"venue_name"];
        }
        
        NSString *foursquare = [userDict objectForKey:@"foursquare"];
        if ([foursquare isKindOfClass:[NSNull class]]) {
            place.foursquareID = [userDict objectForKey:@"foursquare"];
        }
        
        self.placeCheckedIn = place;
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
        self.urlPhoto = [decoder decodeObjectForKey:@"urlPhoto"];
        self.enteredInviteCode = [decoder decodeBoolForKey:@"enteredInviteCode"];
        self.joinDate = [decoder decodeObjectForKey:@"joinDate"];
    }    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInt:self.userID forKey:@"userID"];
    [encoder encodeObject:self.nickname forKey:@"nickname"];
    [encoder encodeObject:self.email forKey:@"email"];
    [encoder encodeObject:self.urlPhoto forKey:@"urlPhoto"];
    [encoder encodeBool:self.enteredInviteCode forKey:@"enteredInviteCode"];
    [encoder encodeObject:self.joinDate forKey:@"joinDate"];
    
}

// override nickname setter to decode html entities
- (void)setNickname:(NSString *)nickname
{
    if ([nickname isKindOfClass:[NSNull class]]) {
        _nickname = @"";
    } else {
        _nickname = [nickname stringByDecodingHTMLEntities];
    }  
}

// override nickname setter to decode html entities
- (void)setStatus:(NSString *)status
{
    if ([status isKindOfClass:[NSNull class]]) {
        status = @"";
    }
    
    if ([status length] > 0) {
        status = [status stringByDecodingHTMLEntities];
        status = [status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }    
    _status = status;
}

// override rate setter to decode any html entities
- (void)setHourlyRate:(NSString *)hourlyRate
{
    _hourlyRate = [hourlyRate stringByDecodingHTMLEntities];
}

// override bio setter to decode any html entities
- (void)setBio:(NSString *)bio
{
    _bio = [bio stringByDecodingHTMLEntities];
}

// override job title setter to decode html entities
-(void)setJobTitle:(NSString *)jobTitle
{
    if ([jobTitle isKindOfClass:[NSNull class]]) {
        _jobTitle = @"";
    } else {
        _jobTitle = [jobTitle stringByDecodingHTMLEntities];
    }
}

- (NSString *)firstName
{
    // if the user has a space in their nickname just use the first part
    // otherwise use the whole name
    NSRange spaceRange = [self.nickname rangeOfString:@" "]; 
    NSString *firstName;
    
    if (spaceRange.location != NSNotFound) {
        firstName = [self.nickname substringToIndex:spaceRange.location + 1];
    } else {
        firstName = self.nickname;
    }
    return firstName;
}

- (BOOL)hasAnyListingsAsClient {
    return self.listingsAsClient.count > 0;
}

- (BOOL)hasAnyListingsAsAgent {
    return self.listingsAsAgent.count > 0;
}

- (BOOL)hasAnyWorkInformation {
    return self.workInformation.count > 0;
}

- (BOOL)hasAnyEducationInformation {
    return self.educationInformation.count > 0;;
}

- (NSMutableArray *)favoritePlaces {
    NSMutableArray *places = [NSMutableArray arrayWithCapacity:3];
    
    int placeCount = 1;
    for (CPPlace *place in self.checkInHistory) { 
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
            
            // TODO: do most of the init here from initWithDictionary
            // only add the extra info we get because of resume here
            
            self.nickname = [userDict objectForKey:@"nickname"];
            NSString *status = [[userDict objectForKey:@"status_text"]
                                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            self.status = status;
            self.bio = [userDict objectForKey:@"bio"];
            
            if ([[userDict objectForKey:@"job_title"] isKindOfClass:[NSString class]]) {
                self.jobTitle = [userDict objectForKey:@"job_title"];
            }
            // set the user's photo url        
            self.urlPhoto = [NSURL URLWithString:[userDict objectForKey:@"urlPhoto"]];
            self.location = CLLocationCoordinate2DMake(
                                                       [[userDict valueForKeyPath:@"location.lat"] doubleValue],
                                                       [[userDict valueForKeyPath:@"location.lng"] doubleValue]);
            
            // set the booleans if the user is facebook/linkedin verified
            self.facebookVerified = [[userDict valueForKeyPath:@"verified.facebook.verified"] boolValue];
            self.linkedInVerified = [[userDict valueForKeyPath:@"verified.linkedin.verified"] boolValue];
            
            // get the users hourly_billing_rate if it isn't null
            if ([[userDict objectForKey:@"hourly_billing_rate"] isKindOfClass:[NSString class]]) {
                self.hourlyRate = [userDict objectForKey:@"hourly_billing_rate"];
            }        
            
            // set the rest of the user info based on information in the userDict
            self.totalEarned = [[userDict valueForKeyPath:@"stats.totalEarned"] doubleValue];
            self.totalSpent = [[userDict valueForKeyPath:@"stats.totalSpent"] doubleValue];
            
            // bio, join date, number of users trusted by
            self.bio = [userDict objectForKey:@"bio"];
            self.join_date = [userDict objectForKey:@"joined"];
            self.trusted_by = [[userDict objectForKey:@"trusted"] intValue];
            
            // listings information
            self.listingsAsClient = [userDict objectForKey:@"listingsAsClient"];
            self.listingsAsAgent = [userDict objectForKey:@"listingsAsAgent"];
            
            self.reviews = [userDict objectForKey:@"reviews"];
            
            // work and education
            self.workInformation = [userDict objectForKey:@"work"];
            self.educationInformation = [userDict objectForKey:@"education"];        
            
            // user checkin data
            // TODO: the information for this place has likely already been downloaded to the user's device
            // We shouldn't need to make another request to get it here
            self.placeCheckedIn = [[CPPlace alloc] init];
            self.placeCheckedIn.foursquareID = [userDict valueForKeyPath:@"checkin_data.foursquare_id"];
            self.placeCheckedIn.checkinCount = [[userDict valueForKeyPath:@"checkin_data.users_here"] intValue];
            self.checkoutEpoch = [NSDate dateWithTimeIntervalSince1970:[[userDict valueForKeyPath:@"checkin_data.checkout"] intValue]]; 
            
            // checkin history
            self.checkInHistory = [NSMutableArray array];
            for (NSDictionary *placeDict in [userDict valueForKey:@"checkin_history"]) {
                CPPlace *place = [CPPlace new];
                place.checkinCount = [[placeDict valueForKey:@"count"] intValue];
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
            
            [self setEnteredInviteCodeFromJSONString:[userDict objectForKey:@"entered_invite_code"]];
            [self setJoinDateFromJSONString:[userDict objectForKey:@"join_date"]];
            
            // call the completion block passed by the caller
            if(completion)
                completion(nil); 
        } else {
            if (completion) 
                completion(error);
        }       
    }];
}

@end
