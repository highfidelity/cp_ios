//
//  CPVenueFeed.h
//  candpiosapp
//
//  Created by Stephen Birarda on 7/9/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPVenueFeed : NSObject

@property (nonatomic, strong) CPVenue *venue;
@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic) int lastID;
@property (nonatomic) int lastReplyID;

- (void)addPostsFromArray:(NSArray *)postsArray;
- (void)addRepliesFromDictionary:(NSDictionary *)repliesDict;
- (int)indexOfPostWithID:(int)postID;

@end
