//
//  NSDictionary+JsonParserWorkaround.h
//  candpiosapp
//
//  Created by Kevin Utecht on 9/28/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//



@interface NSDictionary (JsonParserWorkaround)

// adds an objectForKeyOrNil selector to NSDictionary to return nil when object == [NSNull null]
- (id)objectForKeyOrNil:(id)key;

@end
