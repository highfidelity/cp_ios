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
@synthesize registeredForApnsSuccessfully;
//@synthesize candpLoginToken;
@synthesize candpUserId;
@synthesize facebookAccessToken, facebookExpirationDate;
@synthesize userEmailAddress, userNickname, userPassword;

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
    [encoder encodeBool:registeredForApnsSuccessfully forKey:@"registeredForApnsSuccessfully"];
	
    [encoder encodeObject:lastKnownLocation forKey:@"lastKnownLocation"];
	//[encoder encodeObject:candpLoginToken forKey:@"candpLoginToken"];
	[encoder encodeObject:candpUserId forKey:@"candpUserId"];
	[encoder encodeObject:facebookAccessToken forKey:@"facebookAccessToken"];
	[encoder encodeObject:facebookExpirationDate forKey:@"facebookExpirationDate"];
	[encoder encodeObject:userEmailAddress	forKey:@"userEmailAddress"];
	[encoder encodeObject:userNickname	forKey:@"userNickname"];
	[encoder encodeObject:userPassword	forKey:@"userPassword"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
    if ((self = [super init])) {
        flag = [decoder decodeBoolForKey:@"flag"];
        hasLocation = [decoder decodeBoolForKey:@"hasLocation"];
        registeredForApnsSuccessfully = [decoder decodeBoolForKey:@"registeredForApnsSuccessfully"];
        lastKnownLocation = [decoder decodeObjectForKey:@"lastKnownLocation"];
		//candpLoginToken = [decoder decodeObjectForKey:@"candpLoginToken"];
		candpUserId = [decoder decodeObjectForKey:@"candpUserId"];
		
		facebookAccessToken = [decoder decodeObjectForKey:@"facebookAccessToken"];
		facebookExpirationDate = [decoder decodeObjectForKey:@"facebookExpirationDate"];
		userEmailAddress = [decoder decodeObjectForKey:@"userEmailAddress"];
		userNickname = [decoder decodeObjectForKey:@"userNickname"];
		userPassword = [decoder decodeObjectForKey:@"userPassword"];
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
