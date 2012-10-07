//
//  CPSkill.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/24/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPSkill.h"
#import "NSDictionary+JsonParserWorkaround.h"

@implementation CPSkill

- (CPSkill *)initFromDictionary:(NSDictionary *)skillDict
{
    if (self = [super init]) {
        self.skillID = [[skillDict objectForKey:@"id" orDefault:[NSNumber numberWithInteger:0]] integerValue];
        self.name = [skillDict objectForKey:@"name" orDefault:@""];
        self.isVisible = [[skillDict objectForKey:@"visible" orDefault:[NSNumber numberWithBool:NO]] boolValue];
        self.loveCount = [[skillDict objectForKey:@"love" orDefault:[NSNumber numberWithInt:0]] intValue];
        self.rank = [skillDict objectForKey:@"rank" orDefault:nil];
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


@end
