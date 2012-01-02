//
//  CandPAnnotation.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CandPAnnotation.h"

@implementation CandPAnnotation
@synthesize lat,lon;
@synthesize title,imageUrl;
@synthesize objectId;
-(id)initFromDictionary:(NSDictionary*)jsonDict
{
	self=[super init];
	if(self)
	{
		lat = [[jsonDict objectForKey:@"lat"]doubleValue];
		lon = [[jsonDict objectForKey:@"lng"] doubleValue];
		objectId = [[jsonDict objectForKey:@"id"] copy];
		//title = [jsonDict objectForKey:@"title"];
		//description = [jsonDict objectForKey:@"description"];
		//nickname = [jsonDict objectForKey:@"nickname"];
		id imageUrlObj = [jsonDict objectForKey:@"filename"];
		if(imageUrlObj && imageUrlObj != [NSNull null])
			imageUrl = [imageUrlObj copy];
	}
	return self;
}
// for MKAnnotation protocol
// @property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
//
-(CLLocationCoordinate2D) coordinate
{
	return CLLocationCoordinate2DMake(lat, lon);
}

@end
