//
//  NSDictionary+JsonParserWorkaround.m
//  candpiosapp
//  
//  Created by kevin utecht on 9/28/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "NSDictionary+JsonParserWorkaround.h"

@implementation NSDictionary (JsonParserWorkaround)

- (id)objectForKeyOrNil:(id)key {
    id object = [self objectForKey:key];
    if (object == [NSNull null]) {
        return nil;
    }
    
    return object;
}

@end
