//
//  User.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface User : NSObject

@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, assign) int userID;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic, strong) NSString *bio;
@property (nonatomic, strong) NSURL *urlPhoto;
@property (nonatomic, strong) NSString *skills;

-(void)loadUserResumeData:(void (^)(User *user, NSError *error))completion;


@end
