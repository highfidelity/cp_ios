//
//  MissionAnnotation.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "MissionAnnotation.h"

@implementation MissionAnnotation
@synthesize description,nickname;
-(id)initFromDictionary:(NSDictionary*)jsonDict
{
	self=[super initFromDictionary:jsonDict];
	if(self)
	{
		description = [jsonDict objectForKey:@"description"];
		nickname = [jsonDict objectForKey:@"nickname"];
		self.title = [jsonDict objectForKey:@"title"];

	}
	return self;
}

@end
