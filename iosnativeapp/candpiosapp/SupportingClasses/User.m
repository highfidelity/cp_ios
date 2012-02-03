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

@implementation User

@synthesize nickname = _nickname;
@synthesize userID = _userID;
@synthesize title = _title;
@synthesize status = _status;
@synthesize location = _location;
@synthesize bio = _bio;
@synthesize urlPhoto = _urlPhoto;
@synthesize skills = _skills;

-(id)init
{
	self = [super init];
	if(self)
	{
        
	}
	return self;
}

-(void)loadUserResumeData:(void (^)(User *user, NSError *error))completion {
    NSString *urlString = [NSString stringWithFormat:@"%@api.php?action=getResume&user_id=%d", kCandPWebServiceUrl, self.userID];
#if DEBUG
        NSLog(@"Requesting resume data for user with ID:%d", self.userID);
#endif
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
#if DEBUG
        NSLog(@"JSON Returned for user resume: %@", JSON);
#endif
        
        self.bio = [JSON objectForKey:@"bio"];
        self.urlPhoto = [JSON objectForKey:@"urlPhoto"];
        
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
