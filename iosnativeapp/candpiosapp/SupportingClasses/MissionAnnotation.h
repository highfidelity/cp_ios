//
//  MissionAnnotation.h
//  candpiosapp
//
//  Created by David Mojdehi on 1/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CandPAnnotation.h"

@interface MissionAnnotation : CandPAnnotation
{
	
}
@property (nonatomic, copy) NSString *description;
@property (nonatomic, copy) NSString *nickname;
-(id)initFromDictionary:(NSDictionary*)jsonDict;

@end
