//
//  CPSkill.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/24/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPSkill.h"

@implementation CPSkill

- (CPSkill *)initFromDictionary:(NSDictionary *)skillDict
{
    if (self = [super init]) {
        self.skillID = [[skillDict objectForKey:@"id"] integerValue];
        self.name = [skillDict objectForKey:@"name"];  
        self.isVisible = [[skillDict objectForKey:@"visible"] boolValue];
        self.loveCount = [skillDict objectForKey:@"love"] ? [[skillDict objectForKey:@"love"] intValue] : 0;
        self.rank = [skillDict objectForKey:@"rank"];
    }
    
    return self;
}

-(id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.skillID = [decoder decodeIntegerForKey:@"id"];
        self.name = [decoder decodeObjectForKey:@"name"];
        self.isVisible = [decoder decodeBoolForKey:@"isVisible"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInteger:self.skillID forKey:@"id"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeBool:self.isVisible forKey:@"isVisible"];
}

- (void)setRank:(NSString *)rank 
{
    _rank = [rank isKindOfClass:[NSNull class]] ? nil : rank;
}

@end
