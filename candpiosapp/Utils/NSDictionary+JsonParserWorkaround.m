//
//  NSDictionary+JsonParserWorkaround.m
//  candpiosapp
//  
//  Created by Kevin Utecht on 9/28/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "NSDictionary+JsonParserWorkaround.h"

@implementation NSDictionary (JsonParserWorkaround)

- (id)objectForKey:(id)key orDefault:(id)defaultValue {
    id object = [self objectForKey:key];
    if (object == [NSNull null]) {
        return defaultValue;
    }
    
    return object;
}

- (NSNumber *)numberForKey:(id)key orDefault:(NSNumber *)defaultValue {
    // during the period of transitioning over to RestKit this is used
    // to map String JSON keys to NSNumber via numberWithDouble
    NSString *stringValue = [self objectForKey:key];
    
    if ([stringValue isKindOfClass:[NSNull class]]) {
        return defaultValue;
    } else {
        return @([stringValue doubleValue]);
    }
}

@end
