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

+ (AFHTTPRequestOperation *)getVenuesCloseToLocation:(CLLocation *)location
                           limit:(int)limit
                      categoryID:(NSString *)categoryID
                      searchText:(NSString *)searchText
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
    
    // if we have searchText then pass that as the query
    if (searchText) {
        [parameters setObject:searchText forKey:@"query"];
    }
    
    // add the passed version string to our dictionary of parameters
    parameters = [self parameterDictionaryWithVersionString:versionString existingParameters:parameters];
    
    // create an AFHTTPRequestOperation and equeue it
    NSMutableURLRequest *request = [[self sharedClient] requestWithMethod:@"GET" path:@"venues/search" parameters:parameters];
    
#if DEBUG
    // log out this request if it's not a search (since those clog up the log)
    if (!searchText) {
        NSLog(@"Making request to Foursquare at URL: %@", request.URL.absoluteString);
    }
#endif
    
    AFHTTPRequestOperation *operation = [[self sharedClient]
                                         HTTPRequestOperationWithRequest:request
                                                                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                    completion(operation, responseObject, nil);
                                                                } failure:^(AFHTTPRequestOperation *operation, NSError *error){
                                                                    completion(operation, nil, error);
                                                                }];
    
    [[self sharedClient] enqueueHTTPRequestOperation:operation];
    
    // return the AFHTTPRequestOperation so they can easily be cancelled
    return operation;
}

+ (AFHTTPRequestOperation *)getVenuesCloseToLocation:(CLLocation *)location
                      searchText:(NSString *)searchText
                      completion:(AFRequestCompletionBlock)completion;
{    
    // use above helper to get 20 closest venues, no matter the category
    return [self getVenuesCloseToLocation:location
                             limit:20
                        categoryID:nil
                        searchText:searchText
                     versionString:@"20120302"
                        completion:completion];
}

+ (AFHTTPRequestOperation *)getClosestNeighborhoodToLocation:(CLLocation *)location
                                  completion:(AFRequestCompletionBlock)completion
{
    // use above helper to return 2 closest venues in the neighborhood category
    return [self getVenuesCloseToLocation:location
                             limit:1
                        categoryID:kFoursquareNeighborhoodCategoryID
                        searchText:nil
                     versionString:@"20121001"
                        completion:completion];
}

@end
