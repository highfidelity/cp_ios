//
//  CheckInHelper.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 26.2.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CheckInHelper.h"
#import "CPapi.h"
#import "User.h"
#import "UserProfileCheckedInViewController.h"
#import "MapTabController.h"

@implementation CheckInHelper

+ (void)showCheckInProfileForUser:(int)user_id fromView:(UIViewController *)view {
    
    [CPapi getCheckInDataWithUserId:user_id andCompletion:^(NSDictionary *json, NSError *err) {

        BOOL error = [[json objectForKey:@"error"] boolValue];

        if (!error) {
            NSDictionary *dict = [json objectForKey:@"payload"];

            User *user = [[User alloc] init];
            user.userID = user_id;
            user.nickname = [dict objectForKey:@"nickname"];
            float lat = [[dict objectForKey:@"lat"] floatValue];
            float lng = [[dict objectForKey:@"lng"] floatValue];
            user.location = CLLocationCoordinate2DMake(lat, lng);
            user.status = [dict objectForKey:@"status_text"];
            user.skills = [dict objectForKey:@"skills"];
            user.checkedIn = [[dict objectForKey:@"nickname"] boolValue];

            NSMutableArray *controllers = [NSMutableArray arrayWithArray: [view  childViewControllers]];

            UserProfileCheckedInViewController *pv = [controllers lastObject];

            if ([pv isKindOfClass:[UserProfileCheckedInViewController class]]) {
                [pv setUser:user];
                [pv viewDidLoad];
            } else  {
                MapTabController *mapController = [controllers objectAtIndex:0];
                [mapController performSegueWithIdentifier:@"ShowUserProfileCheckedInFromMap" sender:user];
                [mapController viewDidAppear:YES];
            }
        }
    }];
}


@end
