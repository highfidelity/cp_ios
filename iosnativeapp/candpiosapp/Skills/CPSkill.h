//
//  CPSkill.h
//  candpiosapp
//
//  Created by Stephen Birarda on 5/24/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPSkill : NSObject

@property (nonatomic, assign) NSUInteger skillID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) int loveCount;
@property (nonatomic, strong) NSString *rank;

- (CPSkill *)initFromDictionary:(NSDictionary *)skillDict;

@end
