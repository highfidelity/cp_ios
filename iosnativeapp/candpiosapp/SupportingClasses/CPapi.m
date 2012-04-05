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

@interface CPapi()

+ (void)makeHTTPRequestWithAction:(NSString *)action
                  withParameters:(NSMutableDictionary *)parameters
                 responseHandler:(SEL)selector;

+ (void)makeHTTPRequestWithAction:(NSString *)action
                   withParameters:(NSMutableDictionary *)parameters 
                       completion:(void(^)(NSDictionary *json, NSError *error))completion;

+ (void)makeHTTPRequest:(NSURLRequest *)request 
             completion:(void(^)(NSDictionary *json, NSError *error))completion;


+ (void)oneOnOneChatResponseHandler:(NSData *)response;
+ (void)f2fInviteResponseHandler:(NSData *)response;
+ (void)f2fAcceptResponseHandler:(NSData *)response;
+ (void)f2fDeclineResponseHandler:(NSData *)response;
+ (void)f2fVerifyResponseHandler:(NSData *)response;

@end

@implementation CPapi

// TODO: Show the network activity indicator while the request is being made. Update SVProgressHUD to its latest version (where it no longer automatically shows the network activity indicator when the HUD is displayed) so that the indicator is the responsibility of the actual request and not the HUD

// Private method to perform HTTP requests to the C&P API
+ (void)makeHTTPRequestWithAction:(NSString *)action
                   withParameters:(NSMutableDictionary *)parameters
                  responseHandler:(SEL)selector
{
    
    NSString *urlString = [NSString stringWithFormat:@"%@api.php?action=%@",
                           kCandPWebServiceUrl, action];
    
    // Add parameters to the URL, if they were supplied
    if (parameters != nil) {
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
                       if (selector != nil) {
                           [self performSelectorOnMainThread:selector
                                                  withObject:data
                                               waitUntilDone:YES];
                       }
                   });
}

// Private method to perform HTTP Requests to the C&P API
// Uses the AFJSONRequestOperation which seems to be the easiest way to pass around
// completion blocks

// TODO: Put a timeout on the requests so if the DB is down or something we're not sitting there doing nothing

+ (void)makeHTTPRequestWithAction:(NSString *)action 
                   withParameters:(NSMutableDictionary *)parameters 
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
    
    NSURLRequest *request =  [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [self makeHTTPRequest:request completion:completion];
}

// Private method that takes an NSURLRequest and performs it using AFJSONOperation
+ (void)makeHTTPRequest:(NSURLRequest *)request completion:(void (^)(NSDictionary *, NSError *))completion
{
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request 
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            if (completion != nil) {
                completion(JSON, nil);   
            }
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            if (completion != nil) {
                completion(JSON, error);
        }
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
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
                        toUser:(int)userId
{
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:message forKey:@"message"];
    [parameters setValue:[NSString stringWithFormat:@"%d", userId] forKey:@"toUserId"];
    
    [self makeHTTPRequestWithAction:@"oneOnOneChatFromMobile"
                     withParameters:parameters
                    responseHandler:@selector(oneOnOneChatResponseHandler:)];
}

+ (void)oneOnOneChatResponseHandler:(NSData *)response
{
    NSLog(@"One on one chat sent, or something: %@", response);
}

+ (void)oneOnOneChatGetHistoryWith:(User *)user
                        completion:(void (^)(NSDictionary *, NSError *))completion
{
    /*
    NSDate *date1 = [NSDate dateWithTimeIntervalSince1970: 1000000];
    NSDate *date2 = [NSDate dateWithTimeIntervalSince1970: 2000000];
    
    ChatMessage *message1 = [[ChatMessage alloc] initWithMessage:@"History 1"
                                                          toUser:fromUser
                                                        fromUser:toUser
                                                            date:date1];
    ChatMessage *message2 = [[ChatMessage alloc] initWithMessage:@"History 2"
                                                          toUser:toUser
                                                        fromUser:fromUser
                                                            date:date2];
    
    [history insertMessage:message1];
    [history insertMessage:message2];
     */
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:[NSString stringWithFormat:@"%d", user.userID]
                  forKey:@"other_user"];
    
    [self makeHTTPRequestWithAction:@"getOneOnOneChatHistory"
                     withParameters:parameters
                         completion:completion];
}


#pragma mark - Face-to-Face

+ (void)sendF2FInvite:(int)userId
{
    // Send that shit
    NSLog(@"Sending F2F invite request to user id %d", userId);
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:[NSString stringWithFormat:@"%d", userId] forKey:@"greeted_id"];

    [SVProgressHUD showWithStatus:@"Sending Invite..."];
    [self makeHTTPRequestWithAction:@"f2fInvite"
                     withParameters:parameters
                    responseHandler:@selector(f2fInviteResponseHandler:)];
}

+ (void)f2fInviteResponseHandler:(NSData *)response
{
    /** Server side documentation:
     * Invite a user to Face2Face
     * @greeted_id - the user you want to do F2F with
     * @venue_name - the foursquare venue ID or something? need to figure this out
     * Error codes:
     *  0 - no error
     *  1 - User not logged in
     *  2 - Cannot find this user id
     *  3 - Error writing F2F to Db
     *  4 - F2F already in progress (password included)
     *  5 - Other
     *  6 - F2F already in progress (no password)
     */

    NSError *error;
    NSDictionary* json = [NSJSONSerialization 
                          JSONObjectWithData: response
                          options: kNilOptions
                          error: &error];
    
    NSString *alertMsg = @"";
    NSLog(@"f2f response: %@", json);
    
    [SVProgressHUD dismiss];
    
    if (json == NULL)
    {
        alertMsg = @"We couldn't send the invite.\nPlease try again.";
    } 
    else
    {
        if ([[json objectForKey:@"error"] isEqualToString:@"0"] ||
            [json objectForKey:@"error"] == nil)
        {
            alertMsg = @"Invite sent!";
        }
        else if ([[json objectForKey:@"error"] isEqualToString:@"4"])
        {
            alertMsg = [NSString stringWithFormat:@"We've resent your invite.\nThe password is: %@.",
                        [json objectForKey:@"message"]];
        }
        else if ([[json objectForKey:@"error"] isEqualToString:@"6"])
        {
            alertMsg = @"Invite already sent";
        }
        else
        {
            // Otherwise, just show whatever came back in "message"
            alertMsg = [json objectForKey:@"message"];
        }
    }
    
    // Show error if we got one
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Face to Face"
                          message:alertMsg
                          delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: nil];
    [alert show];
    
    // set the invite alert property on the SettingsMenuController
    // allows us to avoid stacking the f2f alerts
    
    [AppDelegate instance].settingsMenuController.f2fInviteAlert = alert;
}

+ (void)sendF2FAccept:(int)userId
{
    // Send that shit
    NSLog(@"Sending F2F accept to user id %d", userId);
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:[NSString stringWithFormat:@"%d", userId] forKey:@"greeter_id"];
    
    [self makeHTTPRequestWithAction:@"f2fAccept"
                     withParameters:parameters
                    responseHandler:@selector(f2fAcceptResponseHandler:)];

}

+ (void)f2fAcceptResponseHandler:(NSData *)response
{
    
    // TODO: handle error in accept response
    
    /** Documentation from candpweb/web/api.php
     * @greeter_id - the user whose F2F invite you're accepting
     * Error codes:
     *  1 - Not logged in
     *  2 - Invalid greeter user id
     *  3 - DB error accepting F2f
     *  4 - [undefined]
     *  5 - Other (message from exception)
     */

//    NSError *error;
//    NSDictionary* json = [NSJSONSerialization 
//                          JSONObjectWithData: response
//                          options: kNilOptions
//                          error: &error];
//    
//    NSString *alertMsg = @"";
//    NSLog(@"f2f response: %@", json);
//    
//    if (json == NULL)
//    {
//        alertMsg = @"Error accepting invite.";
//    } 
//    else
//    {
//        if ([[json objectForKey:@"error"] isEqualToString:@"0"] ||
//            [json objectForKey:@"error"] == nil)
//        {
//            alertMsg = @"Face to Face accepted!";
//        }
//        else
//        {
//            // Otherwise, just show whatever came back in "message"
//            alertMsg = [json objectForKey:@"message"];
//        }
//    }
//    
//    // Show error if we got one
//    UIAlertView *alert = [[UIAlertView alloc]
//                          initWithTitle:@"Face to Face"
//                          message:alertMsg
//                          delegate:self
//                          cancelButtonTitle:@"OK"
//                          otherButtonTitles: nil];
//    [alert show];
}

+ (void)sendF2FDecline:(int)userId
{
    // Send that shit
    NSLog(@"Sending F2F decline to user id %d", userId);
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:[NSString stringWithFormat:@"%d", userId] forKey:@"greeter_id"];
    
    [self makeHTTPRequestWithAction:@"f2fDecline"
                     withParameters:parameters
                    responseHandler:@selector(f2fDeclineResponseHandler:)];
}

+ (void)f2fDeclineResponseHandler:(NSData *)response
{
    /** Documentation from candpweb/web/api.php
     * @greeter_id - the user whose F2F invite you're accepting
     * Error codes:
     *  1 - Not logged in
     *  2 - Invalid greeter user id
     *  3 - DB error accepting F2f
     *  4 - [undefined]
     *  5 - Other (message from exception)
     */
    
    NSError *error;
    NSDictionary* json = [NSJSONSerialization 
                          JSONObjectWithData: response
                          options: kNilOptions
                          error: &error];
    
    NSString *alertMsg = @"";
    NSLog(@"f2f response: %@", json);
    
    if (json == NULL)
    {
        alertMsg = @"Error declining invite.";
    } 
    else
    {
        if ([[json objectForKey:@"error"] isEqualToString:@"0"] ||
            [json objectForKey:@"error"] == nil)
        {
            alertMsg = @"Face to Face declined.";
        }
        else
        {
            // Otherwise, just show whatever came back in "message"
            alertMsg = [json objectForKey:@"message"];
        }
    }
    
    // Show error if we got one
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Face to Face"
                          message:alertMsg
                          delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: nil];
    [alert show];
}

+ (void)sendF2FVerify:(int)userId
             password:(NSString *)password
{
    // Send that shit
    NSLog(@"Sending F2F password for user id %d", userId);
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:[NSString stringWithFormat:@"%d", userId]
                  forKey:@"greeter_id"];
    [parameters setValue:[NSString stringWithString: password]
                  forKey:@"password"];
    
    [SVProgressHUD show];
    [self makeHTTPRequestWithAction:@"f2fVerify"
                     withParameters:parameters
                    responseHandler:@selector(f2fVerifyResponseHandler:)];
}

+ (void)f2fVerifyResponseHandler:(NSData *)response 
{
    /** Server side documentation
     * Confirms a F2F meeting by checking the password
     * @greeted_id
     * @password
     * Error codes:
     *  1 - User not logged in
     *  2 - Cannot find other F2F user id
     *  3 - Secret word is wrong
     *  4 - unused
     *  5 - Custom exception, 'message' contains reason
     */
    NSError *error;
    NSDictionary* json = [NSJSONSerialization 
                          JSONObjectWithData: response
                          options: kNilOptions
                          error: &error];
    
    NSString *alertMsg = @"";
    NSLog(@"f2f response: %@", json);
    
    if (json == NULL)
    {
        alertMsg = @"Error submitting password.";
    } 
    else
    {
        if ([[json objectForKey:@"error"] isEqualToString:@"0"] ||
            [json objectForKey:@"error"] == nil)
        {
            alertMsg = @"Congratulations! You've met Face to Face.";
            [SVProgressHUD dismiss];
            [[AppDelegate instance].tabBarController dismissModalViewControllerAnimated:YES];
        }
        else if ([[json objectForKey:@"error"] isEqualToString:@"3"])
        {
            [SVProgressHUD dismiss];
            alertMsg = @"Wrong password!\nPlease try again.";
        }
        else
        {
            [SVProgressHUD dismiss];
            // Otherwise, just show whatever came back in "message"
            alertMsg = [json objectForKey:@"message"];
        }
    }
    
    // Show error if we got one
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Face to Face"
                          message:alertMsg
                          delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: nil];
    [alert show];
}


#pragma mark - CheckIn

+ (void)getUsersCheckedInAtFoursquareID:(NSString *)foursquareID 
                                       :(void (^)(NSDictionary *, NSError *))completion
{
    [self makeHTTPRequestWithAction:@"getUsersCheckedIn"
                     withParameters:[NSDictionary dictionaryWithObject:foursquareID
                                                                forKey:@"foursquare"]
                         completion:completion];
}

+ (void)checkInToLocation:(CPPlace *)place
              checkInTime:(NSInteger)checkInTime
             checkOutTime:(NSInteger)checkOutTime
               statusText:(NSString *)stausText
          completionBlock:(void (^)(NSDictionary *, NSError *))completion
{        
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:[NSString stringWithFormat:@"%.7lf", place.lat]
                  forKey:@"lat"];
    [parameters setValue:[NSString stringWithFormat:@"%.7lf", place.lng]
                  forKey:@"lng"];
    [parameters setValue:place.name forKey:@"venue_name"];
    [parameters setValue:[NSString stringWithFormat:@"%d", checkInTime]
                  forKey:@"checkin"];
    [parameters setValue:[NSString stringWithFormat:@"%d", checkOutTime]
                  forKey:@"checkout"];
    [parameters setValue:place.foursquareID forKey:@"foursquare"];
    [parameters setValue:place.address forKey:@"address"];
    [parameters setValue:place.city forKey:@"city"];
    [parameters setValue:place.state forKey:@"state"];
    [parameters setValue:place.zip forKey:@"zip"];
    [parameters setValue:place.phone forKey:@"phone"];
    [parameters setValue:place.formattedPhone forKey:@"formatted_phone"];
    // Don't pass the place icon - it's a dictionary and this crashes the request
    // [parameters setValue:place.icon forKey:@"icon"];
    [parameters setValue:stausText forKey:@"status"];
    
        
    [self makeHTTPRequestWithAction:@"checkin"
                     withParameters:parameters
                         completion:completion];
}

+ (void)checkOutWithCompletion:(void (^)(NSDictionary *, NSError *))completion
{
    [self makeHTTPRequestWithAction:@"checkout"
                     withParameters:nil
                         completion:completion];
}

+ (void)getResumeForUserId:(int)userId
             andCompletion:(void (^)(NSDictionary *, NSError *))completion
{
    // params dict with user id
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%d", userId], @"user_id", nil];
    
    // make the request
    [self makeHTTPRequestWithAction:@"getResume"
                     withParameters:parameters
                         completion:completion];
}

+ (void)getUserProfileWithCompletionBlock:(void (^)(NSDictionary *, NSError *))completion
{
    [self makeHTTPRequestWithAction:@"getUserData"
                     withParameters:nil
                         completion:completion];
}

+ (void)getVenuesInSWCoords:(CLLocationCoordinate2D)SWCoord
                andNECoords:(CLLocationCoordinate2D)NECoord
               userLocation:(CLLocation *)userLocation
             withCompletion:(void (^)(NSDictionary *, NSError *))completion
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:[NSString stringWithFormat:@"%f", SWCoord.latitude] forKey:@"sw_lat"];
    [parameters setValue:[NSString stringWithFormat:@"%f", SWCoord.longitude] forKey:@"sw_lng"];
    [parameters setValue:[NSString stringWithFormat:@"%f", NECoord.latitude] forKey:@"ne_lat"];
    [parameters setValue:[NSString stringWithFormat:@"%f", NECoord.longitude] forKey:@"ne_lng"];
    
    [parameters setValue:[NSString stringWithFormat:@"%f", userLocation.coordinate.latitude] forKey:@"lat"];
    [parameters setValue:[NSString stringWithFormat:@"%f", userLocation.coordinate.longitude] forKey:@"lng"];
    
    [self makeHTTPRequestWithAction:@"getVenuesInBounds"
                     withParameters:parameters
                         completion:completion];
}

+ (void)getUserTrasactionDataWithCompletitonBlock:(void (^)(NSDictionary *, NSError *))completion
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

# pragma mark - User Settings

+ (void)getNotificationSettingsWithCompletition:(void (^)(NSDictionary *, NSError *))completion {
    [self makeHTTPRequestWithAction:@"getNotificationSettings"
                     withParameters:nil
                         completion:completion];
}

+ (void)setNotificationSettingsForDistance:(NSString *)distance
                              andCheckedId:(BOOL)checkedOnly {

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:distance forKey:@"push_distance"];
    [parameters setValue:checkedOnly ? @"1" : @"0" forKey:@"checked_in_only"];

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
            [formData appendPartWithFileData:imageData name:@"profile" fileName:[NSString stringWithFormat:@"%d_iPhone_Profile_Upload.jpeg", [CPAppDelegate currentUser].userID] mimeType:@"image/jpeg"];
        }];
        
        // go back to the main queue and make the request (the makeHTTPRequest method will queue it in an operation queue)
        dispatch_async(dispatch_get_main_queue(), ^{
#if DEBUG
            NSLog(@"Uploading profile image for user with id %d", [CPAppDelegate currentUser].userID);
#endif
            
            // make the request
            [self makeHTTPRequest:request completion:^(NSDictionary *responseDict, NSError *error){
                completion(responseDict, error); 
            }];
        });
    });    
}

@end
