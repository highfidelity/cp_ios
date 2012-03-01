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
#import "NSString+HTML.h"

@implementation User

@synthesize nickname = _nickname;
@synthesize userID = _userID;
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


-(id)init
{
	self = [super init];
	if(self)
	{
        
	}
	return self;
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

-(void)loadUserResumeData:(void (^)(User *user, NSError *error))completion {
    // url hitting api.php to getResume
    NSString *urlString = [NSString stringWithFormat:@"%@api.php?action=getResume&user_id=%d", kCandPWebServiceUrl, self.userID];

#if DEBUG
    NSLog(@"Requesting resume data for user with ID:%d", self.userID);
#endif
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    // make an AFJSONRequestOperation with the NSURLRequest
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
#if DEBUG
        NSLog(@"JSON Returned for user resume: %@", JSON);
#endif
        JSON = [JSON objectForKey:@"payload"];
        
        self.nickname = [JSON objectForKey:@"nickname"];
        self.status = [JSON objectForKey:@"status_text"];
        self.bio = [JSON objectForKey:@"bio"];
        
        if ([[JSON objectForKey:@"job_title"] isKindOfClass:[NSString class]]) {
            self.jobTitle = [JSON objectForKey:@"job_title"];
        }
        // set the user's photo url        
        self.urlPhoto = [JSON objectForKey:@"urlPhoto"];
        self.location = CLLocationCoordinate2DMake(
                                                   [[JSON valueForKeyPath:@"location.lat"] doubleValue],
                                                   [[JSON valueForKeyPath:@"location.lng"] doubleValue]);
        
        // set the booleans if the user is facebook/linkedin verified
        self.facebookVerified = [[JSON valueForKeyPath:@"verified.facebook.verified"] boolValue];
        self.linkedInVerified = [[JSON valueForKeyPath:@"verified.linkedin.verified"] boolValue];
        
        // get the users hourly_billing_rate if it isn't null
        if ([[JSON objectForKey:@"hourly_billing_rate"] isKindOfClass:[NSString class]]) {
            self.hourlyRate = [JSON objectForKey:@"hourly_billing_rate"];
        }        
        
        // set the rest of the user info based on information in the JSON
        self.totalEarned = [[JSON valueForKeyPath:@"stats.totalEarned"] doubleValue];
        self.totalSpent = [[JSON valueForKeyPath:@"stats.totalSpent"] doubleValue];
        
        // bio, join date, number of users trusted by
        self.bio = [JSON objectForKey:@"bio"];
        self.join_date = [JSON objectForKey:@"joined"];
        self.trusted_by = [[JSON objectForKey:@"trusted"] intValue];
        
        // listings information
        self.listingsAsClient = [JSON objectForKey:@"listingsAsClient"];
        self.listingsAsAgent = [JSON objectForKey:@"listingsAsAgent"];
        
        self.reviews = [JSON objectForKey:@"reviews"];
        
        // work and education
        self.workInformation = [JSON objectForKey:@"work"];
        self.educationInformation = [JSON objectForKey:@"education"];        
        
        // user checkin data
        self.placeCheckedIn = [[CPPlace alloc] init];
        self.placeCheckedIn.foursquareID = [JSON valueForKeyPath:@"checkin_data.foursquare"];
        self.placeCheckedIn.othersHere = [[JSON valueForKeyPath:@"checkin_data.others_here"] intValue];
        self.checkoutEpoch = [NSDate dateWithTimeIntervalSince1970:[[JSON valueForKeyPath:@"checkin_data.checkout"] intValue]]; 
        
        // call the completion block passed by the caller
        if(completion)
            completion(self, nil); 
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if(completion)
            completion(nil, error);
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

@end
