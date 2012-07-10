//
//  CPVenueFeed.m
//  candpiosapp
//
//  Created by Stephen Birarda on 7/9/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPVenueFeed.h"
#import "CPPost.h"

@implementation CPVenueFeed

@synthesize venue = _venue;
@synthesize posts = _posts;

- (NSMutableArray *)posts
{
    if (!_posts) {
        _posts = [NSMutableArray array];
    }
    return _posts;
}

- (void)addPostsFromArray:(NSArray *)postsArray
{    
    // for right now we clear the posts in the feed before adding the new ones
    // next commit with add only new posts and re-sort array by date
    self.posts = [NSMutableArray array];
    
    // enumerate through the posts in the array and add them to mutablePosts
    // by using the initFromDictionary method in the CPPost model
    for (NSDictionary *postDict in postsArray) {
        CPPost *newPost = [[CPPost alloc] initFromDictionary:postDict];
        [self.posts addObject:newPost];
    }
    
    // TODO: remove this sorting code once a Testflight build has gone out with this
    // and we can change the API to return posts in the correct order
    self.posts = [[self.posts sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSDate *first = [(CPPost *)a date];
        NSDate *second = [(CPPost *)b date];
        
        // compare the two dates
        NSComparisonResult result = [first compare:second];
        
        // switch-case to flip the order
        switch (result) {
            case NSOrderedAscending:
                result = NSOrderedDescending;
                break;
            case NSOrderedDescending:
                result = NSOrderedAscending;
            default:
                break;
        }
        
        return result;
    }] mutableCopy];
}   

-(BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    } else if (![object isKindOfClass:[self class]]) {
        return NO;
    } else if ([self.venue isEqual:[object venue]]) {
        return YES;
    } else {
        return NO;
    }
}

@end
