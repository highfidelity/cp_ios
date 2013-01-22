//
//  CPapi.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/06.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//  
//  This is the (un)official C&P iOS API! These functions are to
//  be used to interact with the C&P web services.

#import <CoreLocation/CoreLocation.h>
#import "CPapi.h"
#import "UIImage+Resize.h"
#import "UIImage+FixOrientation.h"

@interface CPapi()

+ (void)makeHTTPRequestWithAction:(NSString *)action
                  withParameters:(NSMutableDictionary *)parameters
                 responseHandler:(SEL)selector;
 

+ (void)makeHTTPRequestWithAction:(NSString *)action
                   withParameters:(NSMutableDictionary *)parameters 
                       completion:(void(^)(NSDictionary *json, NSError *error))completion;

+ (void)makeHTTPRequestWithAction:(NSString *)action
                   withParameters:(NSMutableDictionary *)parameters 
                            queue:(NSOperationQueue *)operationQueue
                       completion:(void(^)(NSDictionary *json, NSError *error))completion;
                            

+ (void)makeHTTPRequest:(NSURLRequest *)request 
                  queue:(NSOperationQueue *)operationQueue
             completion:(void(^)(NSDictionary *json, NSError *error))completion;
                 


+ (void)oneOnOneChatResponseHandler:(NSData *)response;

@end

@implementation CPapi


// TODO: Show the network activity indicator while the request is being made. Update SVProgressHUD to its latest version (where it no longer automatically shows the network activity indicator when the HUD is displayed) so that the indicator is the responsibility of the actual request and not the HUD

// Private method to perform HTTP requests to the C&P API

// TODO : get rid of this method in favor of the following one that uses AFJSONRequestOperation

+ (void)makeHTTPRequestWithAction:(NSString *)action
                   withParameters:(NSMutableDictionary *)parameters
                  responseHandler:(SEL)selector
{
    
    NSString *urlString = [NSString stringWithFormat:@"%@api.php?action=%@",
                           kCandPWebServiceUrl, action];
    
    // Add parameters to the URL, if they were supplied
    if (parameters) {
        for (NSString * key in parameters) {
            id value = [parameters valueForKey: key];

            NSString *encodedParams = [NSString stringWithFormat:@"&%@=%@",
                                                                 [self urlEncode:key],
                                                                 [self urlEncode:value]];

            urlString = [urlString stringByAppendingString:encodedParams];
        }
    }
    
#if DEBUG
    NSLog(@"Sending request to URL: %@", urlString);
#endif
    
    NSURL *locationURL = [NSURL URLWithString:urlString];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       NSData* data = [NSData dataWithContentsOfURL: locationURL];
                       if (selector) {
                           [self performSelectorOnMainThread:selector
                                                  withObject:data
                                               waitUntilDone:YES];
                       }
                   });
}

// Private method to perform HTTP Requests to the C&P API
+ (void)makeHTTPRequestWithAction:(NSString *)action 
                   withParameters:(NSMutableDictionary *)parameters
                       completion:(void (^)(NSDictionary *, NSError *))completion
{
    [self makeHTTPRequestWithAction:action withParameters:parameters queue:nil completion:completion];
}

// Calls the next method with a timeout of 60 (which is the default)
+ (void)makeHTTPRequestWithAction:(NSString *)action 
                   withParameters:(NSMutableDictionary *)parameters 
                            queue:(NSOperationQueue *)operationQueue
                       completion:(void (^)(NSDictionary *, NSError *))completion

{
    [self makeHTTPRequestWithAction:action withParameters:parameters queue:operationQueue timeout:60 completion:completion];
}   

// Private method to perform HTTP Requests to the C&P API
// Different than the above because it will accept the queue on which it should make requests
// Uses the AFJSONRequestOperation which seems to be the easiest way to pass around
// completion blocks

+ (void)makeHTTPRequestWithAction:(NSString *)action 
                   withParameters:(NSMutableDictionary *)parameters 
                            queue:(NSOperationQueue *)operationQueue
                          timeout:(NSTimeInterval)timeout
                       completion:(void (^)(NSDictionary *, NSError *))completion
                            
{
    NSString *urlString = [NSString stringWithFormat:@"%@api.php?action=%@",
                           kCandPWebServiceUrl, action];
    if (parameters) {
        for (NSString *key in parameters) {
            id value = [parameters valueForKey: key];
            
            NSString *encodedParams = [NSString stringWithFormat:@"&%@=%@",
                                       [self urlEncode:key],
                                       [self urlEncode:value]];
            
            urlString = [urlString stringByAppendingString:encodedParams];
        }
    }
    
#if DEBUG
    NSLog(@"Sending request to URL: %@", urlString);
#endif
    
    NSURLRequest *request = nil;
    NSURL *url = [NSURL URLWithString:urlString];
    
    request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:timeout];
    
    [self makeHTTPRequest:request queue:operationQueue completion:completion];
}


// Private method that takes an NSURLRequest and performs it using AFJSONOperation
+ (void)makeHTTPRequest:(NSURLRequest *)request 
                  queue:(NSOperationQueue *)operationQueue
             completion:(void (^)(NSDictionary *, NSError *))completion
                  
{
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request 
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            if (completion) {
                completion(JSON, nil);   
            }
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            if (completion) {
                completion(JSON, error);
        }
            
    }];
    
    // check if we were passed a specific queue to run this request on
    
    if (!operationQueue) {
        operationQueue = [[NSOperationQueue alloc] init];
    }
    
    [operationQueue addOperation:operation];
}


#pragma mark - Helper functions

// Stolen from http://cybersam.com/ios-dev/proper-url-percent-encoding-in-ios
+ (NSString *)urlEncode:(NSString *)string {
    return (__bridge NSString *) 
        CFURLCreateStringByAddingPercentEscapes(NULL,
                                                (__bridge CFStringRef) string,
                                                NULL,
                                                (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                kCFStringEncodingUTF8);
}

// Stolen from http://cybersam.com/ios-dev/proper-url-percent-encoding-in-ios
+ (NSString *)urlDecode:(NSString *)string {
    return (__bridge NSString *)
        CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                (__bridge CFStringRef) string,
                                                                CFSTR(""),
                                                                kCFStringEncodingUTF8);
}

// See if we're actually logged in.
// If we are, execute successBlock
// If not, execute failureBlock
// TODO: Make sure this stuff actually works. 2012-02-07 alexi
+ (void)verifyLoginStatusWithBlock:(void (^)(void))successBlock
                      failureBlock:(void (^)(void))failureBlock
{
    AFHTTPClient *httpClient;
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    [requestParams setObject:@"getUserData" forKey:@"action"];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"api.php" parameters:requestParams];
    
    AFJSONRequestOperation *postOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
        NSDictionary *jsonDict = json;
        NSLog(@"Json fields: " );
        [jsonDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSLog(@"     %@ : '%@'", key, obj );
        }];
		
        if ([[jsonDict allKeys] containsObject: @"userid"]) {
            // Check to see if we got a userid back in the response
            // We're logged in, cool.
            (void) successBlock;
        } else {
            // If not, we're not logged in
            (void) failureBlock;
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        // handle error
        NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription] );
        // Make sure we're logged out
        (void) failureBlock;
    }];
    
    [[NSOperationQueue mainQueue] addOperation:postOperation];
}


#pragma mark - One-on-One Chat

+ (void)sendOneOnOneChatMessage:(NSString *)message
                        toUserID:(NSNumber *)userID
{
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:message forKey:@"message"];
    [parameters setValue:[NSString stringWithFormat:@"%@", userID] forKey:@"toUserId"];
    
    [self makeHTTPRequestWithAction:@"oneOnOneChatFromMobile"
                     withParameters:parameters
                    responseHandler:@selector(oneOnOneChatResponseHandler:)];
    [Flurry logEvent:@"sentChatMessage"];
}

+ (void)oneOnOneChatResponseHandler:(NSData *)response
{
    NSLog(@"One on one chat sent, or something: %@", response);
}

+ (void)oneOnOneChatGetHistoryWith:(CPUser *)user
                        completion:(void (^)(NSDictionary *, NSError *))completion
{    
    [self makeHTTPRequestWithAction:@"getOneOnOneChatHistory"
                     withParameters:[@{@"other_user": [NSString stringWithFormat:@"%@", user.userID]} mutableCopy]
                         completion:completion];
}

#pragma mark - Contact Requests
+ (void)getNumberOfContactRequests:(void (^)(NSDictionary *, NSError *))completion
{
    [self makeHTTPRequestWithAction:@"getNumberOfContactRequests" withParameters:nil completion:completion];
}

+ (void)sendContactRequestToUserID:(NSNumber *)userID {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%@", userID], @"acceptor_id",
                                   nil];
    
    [SVProgressHUD showWithStatus:@"Sending Request..."];
    
    [self makeHTTPRequestWithAction:@"sendContactRequest"
                     withParameters:params
                         completion:
     ^(NSDictionary *json, NSError *error) {
         NSString *alertMsg = nil;
         
         [SVProgressHUD dismiss];
         
         if (json == NULL) {
             alertMsg = @"We couldn't send the request.\nPlease try again.";
         } else {
             if ([[json objectForKey:@"error"] boolValue]) {
                 alertMsg = [json objectForKey:@"message"];
             } else {
                 [SVProgressHUD showSuccessWithStatus:@"Contact Request Sent!"];
             }
         }
         
         if (alertMsg) {
             UIAlertView *alert = [[UIAlertView alloc]
                                   initWithTitle:@"Add a Contact"
                                   message:alertMsg
                                   delegate:self
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles: nil];
             [alert show];
             
             // avoid stacking the f2f alerts
             [CPAppDelegate settingsMenuViewController].f2fInviteAlert = alert;
         }
         
         [Flurry logEvent:@"contactRequestSent"];
    }];
}

+ (void)sendAcceptContactRequestFromUserID:(NSNumber *)userID
                                completion:(void (^)(NSDictionary *, NSError *))completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%@", userID], @"initiator_id",
                                   nil];
    
    [self makeHTTPRequestWithAction:@"acceptContactRequest"
                     withParameters:params
                         completion:completion];
    [Flurry logEvent:@"contactRequestAccepted"];
}

+ (void)sendDeclineContactRequestFromUserID:(NSNumber *)userID
                                 completion:(void (^)(NSDictionary *, NSError *))completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%@", userID], @"initiator_id",
                                   nil];
    
    [self makeHTTPRequestWithAction:@"declineContactRequest"
                     withParameters:params
                         completion:completion];
    [Flurry logEvent:@"contactRequestDeclined"];    
}

# pragma mark - Map Dataset
+ (void)getNearestVenuesWithCheckinsToCoordinate:(CLLocationCoordinate2D)coordinate
                                     mapQueue:(NSOperationQueue *)mapQueue
                               completion:(void (^)(NSDictionary *, NSError *))completion
{
    // parameters for API call
    // you could also send checked_in_since (timestamp) and limit (integer) to this call
    // those default to 1 week ago and 25
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:[NSString stringWithFormat:@"%f", coordinate.latitude] forKey:@"lat"];
    [params setValue:[NSString stringWithFormat:@"%f", coordinate.longitude] forKey:@"lng"];
    
    [self makeHTTPRequestWithAction:@"getNearestVenuesAndUsersWithCheckinsDuringInterval" withParameters:params queue:mapQueue timeout:9 completion:completion];
}

#pragma mark - Checkins
+ (void)getNearestCheckedInWithCompletion:(void (^)(NSDictionary *, NSError *))completion
{
    CLLocation *userLocation = [CPAppDelegate currentOrDefaultLocation];
    NSDictionary *params = @{
        @"lat": [NSString stringWithFormat:@"%f", userLocation.coordinate.latitude],
        @"lng": [NSString stringWithFormat:@"%f", userLocation.coordinate.longitude],
        @"v": @"20121116",
    };

    [self makeHTTPRequestWithAction:@"getNearestCheckedIn"
                     withParameters:[params mutableCopy]
                         completion:completion];
}

+ (void)getUsersCheckedInAtFoursquareID:(NSString *)foursquareID 
                                       :(void (^)(NSDictionary *, NSError *))completion
{
    [self makeHTTPRequestWithAction:@"getUsersCheckedIn"
                     withParameters:[NSDictionary dictionaryWithObject:foursquareID
                                                                forKey:@"foursquare"]
                         completion:completion];
}

+ (void)changeHeadlineToNewHeadline:(NSString *)newHeadline
                         completion:(void (^)(NSDictionary *, NSError *))completion
{
    [self makeHTTPRequestWithAction:@"changeCurrentHeadline"
                     withParameters:[NSDictionary dictionaryWithObject:newHeadline
                                                                forKey:@"headline"]
                         completion:completion];
}

+ (void)checkOutWithCompletion:(void (^)(NSDictionary *, NSError *))completion
{
    [self makeHTTPRequestWithAction:@"checkout"
                     withParameters:nil
                         completion:completion];
}

+ (void)getDefaultCheckInVenueWithCompletion:(void (^)(NSDictionary *, NSError *))completion
{
    [self makeHTTPRequestWithAction:@"getDefaultCheckInVenue" withParameters:nil completion:completion];   
}

+ (void)getResumeForUserID:(NSNumber *)userID
                     queue:(NSOperationQueue *)operationQueue
             completion:(void (^)(NSDictionary *, NSError *))completion
{
    // params dict with user id
    NSMutableDictionary *parameters = [@{@"user_id":[NSString stringWithFormat:@"%@", userID]} mutableCopy];
    
    // make the request
    [self makeHTTPRequestWithAction:@"getResume"
                     withParameters:parameters
                              queue:operationQueue
                         completion:completion];
}

+ (void)getUserProfileWithCompletionBlock:(void (^)(NSDictionary *, NSError *))completion
{
    [self makeHTTPRequestWithAction:@"getUserData"
                     withParameters:nil
                         completion:completion];
}

+ (void)getUserTransactionDataWithCompletitonBlock:(void (^)(NSDictionary *, NSError *))completion
{
    [self makeHTTPRequestWithAction:@"getTransactionData"
                     withParameters:nil
                         completion:completion];
}

+ (void)getCheckInDataWithUserId:(int)userId
                   andCompletion:(void (^)(NSDictionary *, NSError *))completion
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:[NSString stringWithFormat:@"%d", userId]
                  forKey:@"user_id"];
    
    [self makeHTTPRequestWithAction:@"getUserCheckInData" 
                     withParameters:parameters
                         completion:completion];
}

+ (void)getContactListWithCompletionsBlock:(void(^)(NSDictionary *json, NSError *error))completion
{
    [self makeHTTPRequestWithAction:@"getContactList" withParameters:nil completion:completion];
}

# pragma mark - Love

+ (void)sendLoveToUserWithID:(NSNumber *)recieverID
                 loveMessage:(NSString *)message
                     skillID:(NSUInteger)skillID 
                  completion:(void (^)(NSDictionary *, NSError *))completion
{
    NSMutableDictionary *reviewParams = [NSMutableDictionary dictionaryWithCapacity:2];
    [reviewParams setObject:[NSString stringWithFormat:@"%@", recieverID] forKey:@"recipientID"];
    [reviewParams setObject:[NSString stringWithFormat:@"%d", skillID] forKey:@"skill_id"];
    [reviewParams setObject:message forKey:@"reviewText"];
    
    [self makeHTTPRequestWithAction:@"sendLove" withParameters:reviewParams completion:completion];
    [Flurry logEvent:@"sentLove"];
}


+ (void)sendPlusOneForLoveWithID:(int)reviewID 
                      completion:(void(^)(NSDictionary *json, NSError *error))completion
{
    // setup the parameters dictionary
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:1];
    [parameters setValue:[NSString stringWithFormat:@"%d", reviewID] forKey:@"review_id"];
    
    // make the request
    [self makeHTTPRequestWithAction:@"sendPlusOneForLove" withParameters:parameters completion:completion];
    [Flurry logEvent:@"sentPlusOneForLove"];
}

# pragma mark - Skills

+ (void)getSkillsForUser:(NSNumber *)userID 
              completion:(void (^)(NSDictionary *, NSError *))completion
{
    NSMutableDictionary *parameters;
   
    // if we have a userID passed then it's not for the current user
    // so set that param
    if (userID) {
        parameters = [NSMutableDictionary dictionaryWithCapacity:1];
        [parameters setValue:userID.stringValue forKey:@"user_id"];
    }
    
    [self makeHTTPRequestWithAction:@"getSkillsForUser" withParameters:parameters completion:completion];
}

+ (void)changeSkillStateForSkillWithId:(int)skillID 
                                 visible:(BOOL)visible
                            skillQueue:(NSOperationQueue *)skillQueue 
                            completion:(void (^)(NSDictionary *, NSError *))completion
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:2];
    [parameters setValue:[NSString stringWithFormat:@"%d", skillID] forKey:@"skill_id"];
    [parameters setValue:[NSString stringWithFormat:@"%d", visible] forKey:@"visible"];
    
    // make the request
    [self makeHTTPRequestWithAction:@"changeSkillVisibility" withParameters:parameters queue:skillQueue timeout:5 completion:completion];

}


# pragma mark - User Settings

+ (void)getNotificationSettingsWithCompletition:(void (^)(NSDictionary *, NSError *))completion {
    [self makeHTTPRequestWithAction:@"getNotificationSettings"
                     withParameters:nil
                         completion:completion];
}

+ (void)setNotificationSettingsForDistance:(NSString *)distance
                      receiveNotifications:(BOOL)receiveNotifications
                              andCheckedId:(BOOL)checkedOnly
                    receiveContactEndorsed:(BOOL)receiveContactEndorsed
                     contactHeadlineChange:(BOOL)contactHeadlineChange
                                 quietTime:(BOOL)quietTime
                             quietTimeFrom:(NSDate *)quietTimeFrom
                               quietTimeTo:(NSDate *)quietTimeTo  
                   timezoneOffsetInSeconds:(NSInteger)tzOffsetSeconds                            
                      chatFromContactsOnly:(BOOL)chatFromContactsOnly
{
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"HH:mm"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:distance forKey:@"push_distance"];
    [parameters setValue:receiveNotifications ? @"1" : @"0" forKey:@"receive_push_notifications"];
    [parameters setValue:checkedOnly ? @"1" : @"0" forKey:@"checked_in_only"];
    [parameters setValue:receiveContactEndorsed ? @"1" : @"0" forKey:@"push_contacts_endorsement"];
    [parameters setValue:contactHeadlineChange ? @"1" : @"0" forKey:@"push_headline_changes"];
    [parameters setValue:quietTime ? @"1" : @"0" forKey:@"quiet_time"];
    [parameters setValue:[formatter stringFromDate:quietTimeFrom] forKey:@"quiet_time_from"];
    [parameters setValue:[formatter stringFromDate:quietTimeTo] forKey:@"quiet_time_to"];
    [parameters setValue:[NSString stringWithFormat:@"%d", tzOffsetSeconds] forKey:@"tz_offset_seconds"];
    [parameters setValue:chatFromContactsOnly ? @"1" : @"0" forKey:@"contacts_only_chat"];
    
    [self makeHTTPRequestWithAction:@"setNotificationSettings"
                         withParameters:parameters
                             completion:nil];
}

+ (void)setUserProfileDataWithDictionary:(NSMutableDictionary *)dataDict andCompletion:(void (^)(NSDictionary *, NSError *))completion
{
    // make the HTTP Request with the dataDict passed from UserSettingsTableViewController
    // in the current implementation this dictionary has one value and one key
    
    [self makeHTTPRequestWithAction:@"setUserProfileData" 
                     withParameters:dataDict 
                         completion:completion];
}

+ (void)uploadUserProfilePhoto:(UIImage *)image withCompletion:(void (^)(NSDictionary *, NSError *))completion
{
    // setup a client for this request so we can do the file uploading magic
    AFHTTPClient *httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kCandPWebServiceUrl]];
    
    image = [image fixOrientation];
    
    // do this in a thread so we don't block ui
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        double ratio;
        UIImage *resizedImage = image;
        
        // let's resize the image first before we upload if it's longest side is bigger than 800
        if (image.size.width > 512 || image.size.height > 512) {
            if (image.size.width < image.size.height) {
                ratio = image.size.width / 512.0;
            } else {
                ratio = image.size.height / 512.0;
            }
            resizedImage = [image resizedImage:CGSizeMake((image.size.width / ratio), (image.size.height / ratio)) interpolationQuality:kCGInterpolationHigh];
#if DEBUG
            NSLog(@"The orginal image dimensions were %gx%g. It has been resized to %gx%g.", image.size.width, image.size.height, resizedImage.size.width, resizedImage.size.height);
#endif
        }
        
        // get NSData for the image
        NSData *imageData = UIImageJPEGRepresentation(resizedImage, 1.0); 
        
        // set the action to setUserProfileData
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"setUserProfileData" forKey:@"action"];
        
        // setup the request to pass the image
        NSURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"api.php" parameters:params constructingBodyWithBlock: ^(id <AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData
                                        name:@"profile"
                                    fileName:[NSString stringWithFormat:@"%@_iPhone_Profile_Upload.jpeg", [CPUserDefaultsHandler currentUser].userID]
                                    mimeType:@"image/jpeg"];
        }];
        
        // go back to the main queue and make the request (the makeHTTPRequest method will queue it in an operation queue)
        dispatch_async(dispatch_get_main_queue(), ^{
#if DEBUG
            NSLog(@"Uploading profile image for user with id %d", [CPUserDefaultsHandler currentUser].userID);
#endif
            
            // make the request
            [self makeHTTPRequest:request queue:nil completion:^(NSDictionary *responseDict, NSError *error){
                completion(responseDict, error); 
            }];
        });
    });    
}

+ (void)saveUserMajorJobCategory:(NSString *)majorJobCategory andMinorJobCategory:(NSString *)minorJobCategory
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:majorJobCategory forKey:@"major_job_category"];
    [parameters setValue:minorJobCategory forKey:@"minor_job_category"];

    [self makeHTTPRequestWithAction:@"updateJobCategories"
                     withParameters:parameters
                         completion:nil];
}

+ (void)deleteAccountWithParameters:(NSMutableDictionary *)parameters completion:(void(^)(NSDictionary *json, NSError *error))completion {
    [self makeHTTPRequestWithAction:@"deleteAccount"
                     withParameters:parameters
                         completion:completion];

}

+ (void)saveVenueAutoCheckinStatus:(CPVenue *)venue
{
    NSLog(@"Saving checkin status of %d for venue: %@", venue.autoCheckin, venue.name);

    NSNumber *currentUserID = [[CPUserDefaultsHandler currentUser] userID];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:currentUserID.stringValue forKey:@"user_id"];
    [parameters setValue:venue.venueID.stringValue forKey:@"venue_id"];
    [parameters setValue:[NSString stringWithFormat:@"%d", venue.autoCheckin] forKey:@"autocheckin"];
    
    [self makeHTTPRequestWithAction:@"saveVenueAutoCheckinStatus"
                     withParameters:parameters
                    responseHandler:nil];
}

+ (void)getLinkedInPostStatus:(void (^)(NSDictionary *, NSError *))completion
{
    [self makeHTTPRequestWithAction:@"getLinkedInPostStatus"
                     withParameters:nil
            completion:completion];
}

+ (void)saveLinkedInPostStatus:(BOOL)status
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:(status ? @"1" : @"0") forKey:@"post_to_linkedin"];

    [self makeHTTPRequestWithAction:@"saveLinkedInPostStatus"
                     withParameters:parameters
                         completion:nil];
}

+ (void)addContactsByLinkedInIDs:(NSArray *)connections
{
    if ( ! [connections isKindOfClass:[NSArray class]]) {
        return;
    }
    
    NSError *error = nil;
    NSData *connectionsJSONData = [NSJSONSerialization dataWithJSONObject:connections
                                                              options:kNilOptions
                                                                error:&error];
    NSString *connectionsJSONString = [[NSString alloc] initWithData:connectionsJSONData
                                                            encoding:NSUTF8StringEncoding];

    [self makeHTTPRequestWithAction:@"addContactsByLinkedInIDs"
                     withParameters:[NSMutableDictionary dictionaryWithObject:connectionsJSONString
                                                                       forKey:@"connections"]
                         completion:NULL];
}

@end
