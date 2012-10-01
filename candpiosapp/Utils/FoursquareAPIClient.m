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

+ (NSMutableDictionary *)parameterDictionaryWithVersionString:(NSString *)versionString andExistingParameters:(NSMutableDictionary *)existingParameters
{
    if (!existingParameters) {
        existingParameters = [NSMutableDictionary dictionary];
    }
    
    [existingParameters setObject:versionString forKey:@"v"];
    
    return existingParameters;
}

#pragma mark - Request Methods

+ (void)getVenuesCloseToLocation:(CLLocation *)location
                              withCompletion:(void (^)(AFHTTPRequestOperation *operation, id responseObject, NSError *error))completion;
{    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"%f,%f",
                                                                   location.coordinate.latitude, location.coordinate.longitude] forKey:@"ll"];
    
    parameters = [self parameterDictionaryWithVersionString:@"20120302" andExistingParameters:parameters];
    
    [[self sharedClient] getPath:@"venues/search"
                      parameters:parameters
                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                             completion(operation, responseObject, nil);
                         } failure:^(AFHTTPRequestOperation *operation, NSError *error){
                             completion(operation, nil, error);
                         }];
}

+ (void)addNewPlace:(NSString *)name
        atLocation:(CLLocation *)location
    withCompletion:(void (^)(AFHTTPRequestOperation *operation, id responseObject, NSError *error))completion;
{
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    [requestParams setObject:name forKey:@"name"];
    [requestParams setObject:[NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude] forKey:@"ll"];
    requestParams = [self parameterDictionaryWithVersionString:@"20120208" andExistingParameters:requestParams];
    
    [[self sharedClient] postPath:@"add" parameters:requestParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(operation, responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(operation, nil, error);
    }];
}

@end
