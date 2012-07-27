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

- (void)addPostsFromArray:(NSArray *)postsArray;
- (int)indexOfPostWithID:(int)postID;

@end
