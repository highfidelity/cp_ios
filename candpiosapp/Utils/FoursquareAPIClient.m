//
//  FoursquareAPIClient.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "FoursquareAPIClient.h"

@implementation FoursquareAPIClient

static FoursquareAPIClient *_sharedClient;

+ (void)initialize
{
    if (!_sharedClient) {
        _sharedClient = [[FoursquareAPIClient alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.foursquare.com/v2/"]];
    }
}

+ (FoursquareAPIClient *)sharedClient
{
    return _sharedClient;
}

#pragma mark - Ovveridden AFHTTPClient methods
- (id)initWithBaseURL:(NSURL *)url {
    if (self = [super initWithBaseURL:url]) {
        
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        
        // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
        [self setDefaultHeader:@"Accept" value:@"application/json"];
    }
    
    return self;
}    

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters
{
    // append our oauth_token to the request parameters
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    [mutableParameters setObject:kFoursquareOAuthToken forKey:@"oauth_token"];
                   
    NSMutableURLRequest *request = [super requestWithMethod:method path:path parameters:mutableParameters];
    
    NSLog(@"Making request to Foursquare at URL: %@", request.URL.absoluteString);
    
    if ([method isEqualToString:@"POST"]) {
        NSLog(@"Parameters sent with Foursquare POST request: %@", parameters.description);
    }
    
    return request;
}

#pragma mark - Class Helpers

+ (NSMutableDictionary *)parameterDictionaryWithVersionString:(NSString *)versionString existingParameters:(NSMutableDictionary *)existingParameters
{
    if (!existingParameters) {
        existingParameters = [NSMutableDictionary dictionary];
    }
    
    [existingParameters setObject:versionString forKey:@"v"];
    
    return existingParameters;
}

#pragma mark - Request Methods

+ (void)getVenuesCloseToLocation:(CLLocation *)location
                           limit:(int)limit
                      categoryID:(NSString *)categoryID
                   versionString:(NSString *)versionString
                      completion:(AFRequestCompletionBlock)completion
{
    // create dictionary for request parameters
    // pass location as comma seperated floats
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"%f,%f",
                                                                                 location.coordinate.latitude, location.coordinate.longitude] forKey:@"ll"];
    // pass limit for number of venues desired in result
    [parameters setObject:[NSNumber numberWithInt:limit] forKey:@"limit"];
    
    // if we have a category ID ask for a specific category of venue
    if (categoryID) {
        [parameters setObject:categoryID forKey:@"categoryId"];
    }
    
    // add the passed version string to our dictionary of parameters
    parameters = [self parameterDictionaryWithVersionString:versionString existingParameters:parameters];
    
    // make the GET request to venues/search
    [[self sharedClient] getPath:@"venues/search"
                      parameters:parameters
                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                             completion(operation, responseObject, nil);
                         } failure:^(AFHTTPRequestOperation *operation, NSError *error){
                             completion(operation, nil, error);
                         }];
}

+ (void)getVenuesCloseToLocation:(CLLocation *)location
                      completion:(AFRequestCompletionBlock)completion;
{    
    // use above helper to get 20 closest venues, no matter the category
    [self getVenuesCloseToLocation:location limit:20 categoryID:nil versionString:@"20120302" completion:completion];
}

+ (void)getClosestNeighborhoodToLocation:(CLLocation *)location
                                  completion:(AFRequestCompletionBlock)completion
{
    // use above helper to return 2 closest venues in the neighborhood category
    [self getVenuesCloseToLocation:location limit:1 categoryID:@"4f2a25ac4b909258e854f55f" versionString:@"20121001" completion:completion];
}

+ (void)addNewPlace:(NSString *)name
           location:(CLLocation *)location
         completion:(AFRequestCompletionBlock)completion
{
    // setup dictionary with request parameters
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    [requestParams setObject:name forKey:@"name"];
    [requestParams setObject:[NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude] forKey:@"ll"];
    requestParams = [self parameterDictionaryWithVersionString:@"20120208" existingParameters:requestParams];
    
    // post to /venues/add
    [[self sharedClient] postPath:@"venues/add" parameters:requestParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(operation, responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(operation, nil, error);
    }];
}

@end
