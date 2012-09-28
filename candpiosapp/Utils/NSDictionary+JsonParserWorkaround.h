//
//  NSDictionary+JsonParserWorkaround.h
//  
//
//  Created by kevin utecht on 9/28/12.
//
//



@interface NSDictionary (JsonParserWorkaround)

// adds an objectForKeyOrNil selector to NSDictionary to return nil when key == [NSNull null]
- (id)objectForKeyOrNil:(id)key;

@end
