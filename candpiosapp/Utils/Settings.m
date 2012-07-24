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
@synthesize registeredForApnsSuccessfully;
//@synthesize candpLoginToken;
@synthesize userEmailAddress, userPassword, userBalance;
@synthesize notifyInVenueOnly, notifyWhenCheckedIn;;

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
    [encoder encodeBool:registeredForApnsSuccessfully forKey:@"registeredForApnsSuccessfully"];
	[encoder encodeObject:userEmailAddress	forKey:@"userEmailAddress"];
	[encoder encodeObject:userPassword	forKey:@"userPassword"];
	[encoder encodeFloat:userBalance forKey:@"userBalance"];
    [encoder encodeBool:flag forKey:@"notifyInVenueOnly"];
    [encoder encodeBool:flag forKey:@"notifyWhenCheckedIn"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
    if ((self = [super init])) {
        flag = [decoder decodeBoolForKey:@"flag"];
        registeredForApnsSuccessfully = [decoder decodeBoolForKey:@"registeredForApnsSuccessfully"];
		
		userEmailAddress = [decoder decodeObjectForKey:@"userEmailAddress"];
		userPassword = [decoder decodeObjectForKey:@"userPassword"];
		userBalance = [decoder decodeFloatForKey:@"userBalance"];
        
        notifyInVenueOnly = [decoder decodeBoolForKey:@"notifyInVenueOnly"];
        notifyWhenCheckedIn = [decoder decodeBoolForKey:@"notifyWhenCheckedIn"];
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
