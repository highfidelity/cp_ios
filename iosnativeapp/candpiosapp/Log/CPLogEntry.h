//
//  CPLogEntry.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CPSkill.h"

@interface CPLogEntry : NSObject

@property (nonatomic, assign) NSUInteger logID;
@property (nonatomic, strong) NSString *entry;
@property (nonatomic, strong) User *author;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) CPVenue *venue;
@property (nonatomic, assign) double *lat;
@property (nonatomic, assign) double *lng;
@property (nonatomic, strong) User *receiver;
@property (nonatomic, strong) CPSkill *skill;

- (id)initFromDictionary:(NSDictionary *)logDict;

@end
