//
//  User.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "User.h"
#import "AFJSONRequestOperation.h"
#import "AppDelegate.h"
#import "CPapi.h"
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
@synthesize jobTitle, reviews;
@synthesize checkInHistory = _checkInHistory;

-(id)init
{
	self = [super init];
	if(self)
	{
        // init code here
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
    }    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInt:self.userID forKey:@"userID"];
    [encoder encodeObject:self.nickname forKey:@"nickname"];
    [encoder encodeObject:self.email forKey:@"email"];
    [encoder encodeObject:self.urlPhoto forKey:@"urlPhoto"];
}

// override nickname setter to decode html entities
- (void)setNickname:(NSString *)nickname
{
    _nickname = [nickname stringByDecodingHTMLEntities];
}

// override nickname setter to decode html entities
- (void)setStatus:(NSString *)status
{
    NSString *cleanStatus = [status stringByDecodingHTMLEntities];
    if ([cleanStatus length] > 0) {
        if ([[cleanStatus substringFromIndex:[cleanStatus length] - 1] isEqualToString:@" "]) {
            cleanStatus = [cleanStatus substringToIndex:[cleanStatus length] - 1];
        }
    }    
    _status = cleanStatus;
}

// override rate setter to decode any html entities
- (void)setHourlyRate:(NSString *)hourlyRate
{
    _hourlyRate = [hourlyRate stringByDecodingHTMLEntities];
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

-(void)loadUserResumeData:(void (^)(NSError *error))completion {
    
    [CPapi getResumeForUserId:self.userID andCompletion:^(NSDictionary *response, NSError *error) {
        
        if (!error) {
            NSDictionary *userDict = [response objectForKey:@"payload"];
            
            self.nickname = [userDict objectForKey:@"nickname"];
            NSString *status = [[userDict objectForKey:@"status_text"]
                                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            self.status = status;
            self.bio = [userDict objectForKey:@"bio"];
            
            if ([[userDict objectForKey:@"job_title"] isKindOfClass:[NSString class]]) {
                self.jobTitle = [userDict objectForKey:@"job_title"];
            }
            // set the user's photo url        
            self.urlPhoto = [userDict objectForKey:@"urlPhoto"];
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
            self.placeCheckedIn = [[CPPlace alloc] init];
            self.placeCheckedIn.foursquareID = [userDict valueForKeyPath:@"checkin_data.foursquare"];
            self.placeCheckedIn.othersHere = [[userDict valueForKeyPath:@"checkin_data.others_here"] intValue];
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
                place.icon = [placeDict valueForKey:@"icon"];
                [self.checkInHistory addObject:place];
            }
            
            // user email
            self.email = [userDict objectForKey:@"email"];
            
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
