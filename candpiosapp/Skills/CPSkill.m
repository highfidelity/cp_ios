//
//  CPSkill.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/24/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPSkill.h"


// adds an objectForKeyNotNull selector to NSDictionary to return nil when key == [NSNull null]
// see: http://stackoverflow.com/questions/5716942/touchjson-dealing-with-nsnull
@implementation NSDictionary (Utility)

- (id)objectForKeyNotNull:(id)key {
    id object = [self objectForKey:key];
    if (object == [NSNull null]) {
        return nil;
    }
    
    return object;
}

@end



@implementation CPSkill

- (CPSkill *)initFromDictionary:(NSDictionary *)skillDict
{
    if (self = [super init]) {
        self.skillID = [skillDict objectForKeyNotNull:@"id"] ? [[skillDict objectForKey:@"id"] integerValue] : 0;
        self.name = [skillDict objectForKeyNotNull:@"name"] ? [skillDict objectForKey:@"name"] : @"";
        self.isVisible = [skillDict objectForKeyNotNull:@"visible"] ? [[skillDict objectForKey:@"visible"] boolValue] : NO;
        self.loveCount = [skillDict objectForKeyNotNull:@"love"] ? [[skillDict objectForKey:@"love"] intValue] : 0;
        self.rank = [skillDict objectForKeyNotNull:@"rank"];
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
