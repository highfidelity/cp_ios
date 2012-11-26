//
//  Settings.m
//  candpiosapp
//
//  Created by David Mojdehi on 12/31/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import "Settings.h"

@implementation Settings

- (id)init
{
    if (self = [super init]) {
        self.flag = true;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder 
{
    [encoder encodeBool:self.flag forKey:@"flag"];
    [encoder encodeBool:self.registeredForApnsSuccessfully forKey:@"registeredForApnsSuccessfully"];
    [encoder encodeObject:self.userEmailAddress	forKey:@"userEmailAddress"];
    [encoder encodeObject:self.userPassword	forKey:@"userPassword"];
    [encoder encodeFloat:self.userBalance forKey:@"userBalance"];
    [encoder encodeBool:self.flag forKey:@"notifyInVenueOnly"];
    [encoder encodeBool:self.flag forKey:@"notifyWhenCheckedIn"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
    if (self = [super init]) {
        self.flag = [decoder decodeBoolForKey:@"flag"];
        self.registeredForApnsSuccessfully = [decoder decodeBoolForKey:@"registeredForApnsSuccessfully"];
        
        self.userEmailAddress = [decoder decodeObjectForKey:@"userEmailAddress"];
        self.userPassword = [decoder decodeObjectForKey:@"userPassword"];
        
        self.userBalance = [decoder decodeFloatForKey:@"userBalance"];
        self.notifyInVenueOnly = [decoder decodeBoolForKey:@"notifyInVenueOnly"];
        self.notifyWhenCheckedIn = [decoder decodeBoolForKey:@"notifyWhenCheckedIn"];
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
