//
//  FoursquareAPIRequest.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "FoursquareAPIRequest.h"

#define OAUTH_TOKEN @"BCG410DXRKXSBRWUNM1PPQFSLEFQ5ND4HOUTTTWYUB1PXYC4"

@implementation FoursquareAPIRequest

// TODO: Make one method that makes the request and call this from the other methods

+(void)dictForVenueWithFoursquareID:(NSString *)foursquare_id
                                             :(void (^)(NSDictionary *dict, NSError *error))completion
{
    // pass the v parameter to indicate when this api request added to the app
    // tells foursquare we are up to date as of that date
    // see https://developer.foursquare.com/overview/versioning
    NSString *urlString = [NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/%@?oauth_token=%@&v=20120208", foursquare_id, OAUTH_TOKEN];
    NSURL *requestURL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    
    // set up an AFJSONRequestOperation with the NSURLRequest
    // call the completion function passed as a block by the caller
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        if(completion)
            completion(JSON, nil); 
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if(completion)
            completion(JSON, error); 
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

+(void)getVenuesCloseToLocation:(CLLocation *)location 
                              :(void (^)(NSDictionary *dict, NSError *error))completion;
{
    NSString *locationString = [NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?ll=%f,%f&limit=20&oauth_token=BCG410DXRKXSBRWUNM1PPQFSLEFQ5ND4HOUTTTWYUB1PXYC4&v=20120302", location.coordinate.latitude, location.coordinate.longitude];
    NSURL *locationURL = [NSURL URLWithString:locationString];
    
    NSLog(@"Making request to Foursquare at URL: %@", locationString);
    NSURLRequest *request = [NSURLRequest requestWithURL:locationURL];
    
    // set up an AFJSONRequestOperation with the NSURLRequest
    // call the completion function passed as a block by the caller
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        if(completion)
            completion(JSON, nil); 
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if(completion)
            completion(JSON, error); 
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

+(void)addNewPlace:(NSString *)name atLocation:(CLLocation *)location
                  :(void (^)(NSDictionary *dict, NSError *error))completion
{
    AFHTTPClient *httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"https://api.foursquare.com/v2/venues/"]];

    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    [requestParams setObject:name forKey:@"name"];
    [requestParams setObject:[NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude] forKey:@"ll"];
    [requestParams setObject:OAUTH_TOKEN forKey:@"oauth_token"];
    [requestParams setObject:@"20120208" forKey:@"v"];
    
    NSLog(@"params: %@", requestParams);
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"add" parameters:requestParams];
    
    // set up an AFJSONRequestOperation with the NSURLRequest
    // call the completion function passed as a block by the caller
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if(completion)
            completion(JSON, nil); 
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if(completion)
            completion(JSON, error); 
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

@end
