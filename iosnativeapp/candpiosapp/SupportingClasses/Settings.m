//
//  Settings.m
//  candpiosapp
//
//  Created by David Mojdehi on 12/31/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import "Settings.h"

@implementation Settings
@synthesize flag;
@synthesize hasLocation;
@synthesize lastKnownLocation;

//=========================================================== 
// - (id)init
//
//=========================================================== 
- (id)init
{
    if ((self = [super init])) {
        flag = true;
    }
    return self;
}

//=========================================================== 
//  Keyed Archiving
//
//=========================================================== 
- (void)encodeWithCoder:(NSCoder *)encoder 
{
    [encoder encodeBool:flag forKey:@"flag"];
    [encoder encodeBool:hasLocation forKey:@"hasLocation"];
    [encoder encodeObject:lastKnownLocation forKey:@"lastKnownLocation"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
    if ((self = [super init])) {
        flag = [decoder decodeBoolForKey:@"flag"];
        hasLocation = [decoder decodeBoolForKey:@"hasLocation"];
        lastKnownLocation = [decoder decodeObjectForKey:@"lastKnownLocation"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id theCopy = nil;
	
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
	
    if (data)
        theCopy = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	
    return theCopy;
}

@end
