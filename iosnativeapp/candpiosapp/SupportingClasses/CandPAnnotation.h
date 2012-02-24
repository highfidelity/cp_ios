//
//  CandPAnnotation.h
//  candpiosapp
//
//  Created by David Mojdehi on 1/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "OCGrouping.h"

@interface CandPAnnotation : NSObject< MKAnnotation, OCGrouping>
@property (nonatomic,assign) double lat;
@property (nonatomic,assign) double lon;
@property (nonatomic, assign) int checkinId;
@property (nonatomic, assign) bool checkedIn;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, copy) NSString *objectId;
@property (nonatomic, copy) NSString *_groupTag;

-(id)initFromDictionary:(NSDictionary*)jsonDict;

- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToUserAnnotation:(CandPAnnotation *)annotation;
- (NSString *)groupTag;
- (void)setGroupTag:(NSString *)tag;

@end
