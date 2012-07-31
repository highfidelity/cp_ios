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
    // enumerate through the posts in the array and add them to mutablePosts
    // by using the initFromDictionary method in the CPPost model
    for (NSDictionary *postDict in postsArray) {
        CPPost *newPost = [[CPPost alloc] initFromDictionary:postDict];
        
        if (![self.posts containsObject:newPost]) {
            int postIndex = self.lastID == 0 ? self.posts.count : 0;
            [self.posts insertObject:newPost atIndex:postIndex];
        }       
    }
}

- (void)addRepliesFromDictionary:(NSDictionary *)repliesDict
{
    int maxReplyID;
    
    // loop through the keys of the dictionary returned from API
    // these are the post ID for the original post the reply associates to
    for (NSNumber *original_post_ID in repliesDict) {
        // grab the original post from our posts array
        CPPost *originalPost = [self.posts objectAtIndex:[self indexOfPostWithID:[original_post_ID intValue]]];
        
        // loop through the replies for this post and add them to the original post
        for (NSDictionary *replyDict in [repliesDict objectForKey:original_post_ID]) {
            CPPost *replyPost = [[CPPost alloc] initFromDictionary:replyDict];
            
            // add this reply if we don't already have it
            if (![originalPost.replies containsObject:replyPost]) {
                [originalPost.replies addObject:replyPost];
                
                // check if we have a new maxReplyID
                 maxReplyID = (originalPost.postID > maxReplyID) ?
                              originalPost.postID : maxReplyID;
            }
            
        }
    }
    
    // our last reply ID is the maxReplyID we figured out during the enumeration
    self.lastReplyID = maxReplyID;
}

- (int)indexOfPostWithID:(int)postID
{
    // leverage the overridden isEqual method in CPPost and NSMutableArray's indexOfObject
    CPPost *originalPostPlaceHolder = [[CPPost alloc] init];
    originalPostPlaceHolder.postID = postID;
    
    return [self.posts indexOfObject:originalPostPlaceHolder];
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
