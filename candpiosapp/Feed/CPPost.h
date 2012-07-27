//
//  CPPost.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CPSkill.h"

typedef enum {
    CPPostTypeUpdate,
    CPPostTypeLove,
    CPPostTypeQuestion,
    CPPostTypeCheckin
} CPPostType;

@interface CPPost : NSObject

@property (nonatomic, assign) NSUInteger postID;
@property (strong, nonatomic) NSString *entry;
@property (strong, nonatomic) User *author;
@property (strong, nonatomic) NSDate *date;
@property (nonatomic, assign) double *lat;
@property (nonatomic, assign) double *lng;
@property (strong, nonatomic) User *receiver;
@property (strong, nonatomic) CPSkill *skill;
@property (nonatomic, assign) CPPostType type;
@property (strong, nonatomic) NSMutableArray *replies;
@property (nonatomic, assign) NSUInteger originalPostID;
@property (nonatomic, assign) NSUInteger likeCount;
@property (nonatomic, assign) BOOL userHasLiked;

- (id)initFromDictionary:(NSDictionary *)postDict;

@end
