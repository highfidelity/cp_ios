//
//  NSDictionary+JsonParserWorkaround.m
//  
//
//  Created by kevin utecht on 9/28/12.
//
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
