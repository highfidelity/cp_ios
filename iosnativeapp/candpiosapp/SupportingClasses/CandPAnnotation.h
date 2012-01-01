//
//  CandPAnnotation.h
//  candpiosapp
//
//  Created by David Mojdehi on 1/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface CandPAnnotation : NSObject< MKAnnotation >
@property (nonatomic,assign) double lat;
@property (nonatomic,assign) double lon;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *imageUrl;
-(id)initFromDictionary:(NSDictionary*)jsonDict;

@end
