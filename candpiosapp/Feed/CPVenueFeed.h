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
@property (nonatomic) NSUInteger lastReplyID;
@property (nonatomic) int updateTimestamp;

- (void)addPostsFromArray:(NSArray *)postsArray;
- (void)addRepliesFromDictionary:(NSDictionary *)repliesDict;
- (NSUInteger)indexOfPostWithID:(NSUInteger)postID;

@end
