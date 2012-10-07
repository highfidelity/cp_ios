//
//  NSDictionary+JsonParserWorkaround.h
//  candpiosapp
//
//  Created by Kevin Utecht on 9/28/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

@interface NSDictionary (JsonParserWorkaround)

// adds an objectForKey selector to NSDictionary with the additon of a default value.  If object == [NSNull null],
// then the default value is returned
- (id)objectForKey:(id)key orDefault:(id)defaultValue;

@end
