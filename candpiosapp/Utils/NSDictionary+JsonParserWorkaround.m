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

@end
