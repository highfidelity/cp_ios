//
//  UserAnnotation.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserAnnotation.h"

@implementation UserAnnotation
@synthesize nickname, skills, distance;

-(id)initFromDictionary:(NSDictionary *)jsonDict
{
	self = [super initFromDictionary:jsonDict];
	if(self)
	{
		nickname = [jsonDict objectForKey:@"nickname"];
		self.title = nickname;
		skills = [jsonDict objectForKey:@"skills"];
		if(skills && ((NSNull*)skills != [NSNull null]))
			self.subtitle = skills;

	}
	return self;
}

@end
