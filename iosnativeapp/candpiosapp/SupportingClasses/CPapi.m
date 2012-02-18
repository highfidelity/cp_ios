//
//  CPapi.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/06.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//  
//  This is the (un)official C&P iOS API! These functions are to
//  be used to interact with the C&P web services.

#import "CPapi.h"
#import "AppDelegate.h"

@interface CPapi()

+ (void)makeHTTPRequestWithAction:(NSString *)action
                  withParameters:(NSMutableDictionary *)parameters
                 responseHandler:(SEL)selector;

+ (void)OneOnOneChatResponseHandler:(NSData *)response;
+ (void)f2fInviteResponseHandler:(NSData *)response;
+ (void)f2fAcceptResponseHandler:(NSData *)response;
+ (void)f2fDeclineResponseHandler:(NSData *)response;
+ (void)f2fVerifyResponseHandler:(NSData *)response;

@end

@implementation CPapi

@synthesize httpClient;

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
                                                                 [key stringByAddingPercentEscapesUsingEncoding:
                                                                    NSASCIIStringEncoding],
                                                                 [value stringByAddingPercentEscapesUsingEncoding:
                                                                    NSASCIIStringEncoding]];

            urlString = [urlString stringByAppendingString:encodedParams];
        }
    }
    
    NSLog(@"Sending request to URL: %@", urlString);
    
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
                    responseHandler:@selector(OneOnOneChatResponseHandler:)];
}

+ (void)OneOnOneChatResponseHandler:(NSData *)response
{
    NSLog(@"One on one chat sent, or something: %@", response);
}


#pragma mark - Face-to-Face

+ (void)sendF2FInvite:(int)userId
{
    // Send that shit
    NSLog(@"Sending F2F invite request to user id %d", userId);
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:[NSString stringWithFormat:@"%d", userId] forKey:@"greeted_id"];
    
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
    
    if (json == NULL)
    {
        alertMsg = @"Error sending invite.";
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
            alertMsg = [NSString stringWithFormat:@"Invite pending with password: %@",
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
        alertMsg = @"Error accepting invite.";
    } 
    else
    {
        if ([[json objectForKey:@"error"] isEqualToString:@"0"] ||
            [json objectForKey:@"error"] == nil)
        {
            alertMsg = @"Face to Face accepted!";
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
        alertMsg = @"Error accepting invite.";
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
            alertMsg = @"Yay you've met Face to Face!!";
        }
        else if ([[json objectForKey:@"error"] isEqualToString:@"3"])
        {
            alertMsg = @"Password was incorrect :(";
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


@end
