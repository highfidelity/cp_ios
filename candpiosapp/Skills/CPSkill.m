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
        self.skillID = [skillDict objectForKeyOrNil:@"id"] ? [[skillDict objectForKey:@"id"] integerValue] : 0;
        self.name = [skillDict objectForKeyOrNil:@"name"] ? [skillDict objectForKey:@"name"] : @"";
        self.isVisible = [skillDict objectForKeyOrNil:@"visible"] ? [[skillDict objectForKey:@"visible"] boolValue] : NO;
        self.loveCount = [skillDict objectForKeyOrNil:@"love"] ? [[skillDict objectForKey:@"love"] intValue] : 0;
        self.rank = [skillDict objectForKeyOrNil:@"rank"];
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
