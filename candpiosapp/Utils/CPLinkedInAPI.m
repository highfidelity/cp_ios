//
//  CPLinkedInAPI.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 5/23/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPLinkedInAPI.h"
#import "OAConsumer.h"
#import "OAToken.h"

static CPLinkedInAPI *sharedCPLinkedInAPI = nil;

@implementation CPLinkedInAPI

+ (CPLinkedInAPI *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sharedCPLinkedInAPI) {
            sharedCPLinkedInAPI = [[self alloc] init];
        }
    });
    return sharedCPLinkedInAPI;
}

- (id)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (OAMutableURLRequest *)linkedInJSONAPIRequestWithRelativeURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.linkedin.com/%@", urlString]];
    
    OAMutableURLRequest *linkedInAPIRequest = [[OAMutableURLRequest alloc] initWithURL:url
                                                                              consumer:self.consumer
                                                                                 token:self.token
                                                                                 realm:nil
                                                                     signatureProvider:nil];
    [linkedInAPIRequest setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    
    return linkedInAPIRequest;
}

#pragma mark - properties

- (OAToken *)token {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"linkedin_token"];
    NSString *secret = [[NSUserDefaults standardUserDefaults] objectForKey:@"linkedin_secret"];
    
    return [[OAToken alloc] initWithKey:token secret:secret];
}

- (OAConsumer *)consumer {
    return [[OAConsumer alloc] initWithKey:kLinkedInKey secret:kLinkedInSecret];
}

@end
