//
//  UserAnnotation.h
//  candpiosapp
//
//  Created by David Mojdehi on 1/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CandPAnnotation.h"

@interface UserAnnotation : CandPAnnotation
{
	
}
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *skills;
-(id)initFromDictionary:(NSDictionary*)jsonDict;

@end
