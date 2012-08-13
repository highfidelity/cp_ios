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

@property (strong, nonatomic) NSString *entry;
@property (strong, nonatomic) User *author;
@property (strong, nonatomic) NSDate *date;
@property (strong, nonatomic) User *receiver;
@property (strong, nonatomic) CPSkill *skill;
@property (strong, nonatomic) NSMutableArray *replies;
@property (nonatomic) NSUInteger postID;
@property (nonatomic) double *lat;
@property (nonatomic) double *lng;
@property (nonatomic) CPPostType type;
@property (nonatomic) NSUInteger originalPostID;
@property (nonatomic) NSUInteger likeCount;
@property (nonatomic) BOOL userHasLiked;


- (id)initFromDictionary:(NSDictionary *)postDict;

@end
