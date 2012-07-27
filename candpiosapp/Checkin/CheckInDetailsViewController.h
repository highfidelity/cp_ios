//
//  CheckInDetailsViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "CPVenue.h"

@interface CheckInDetailsViewController : UIViewController <UIAlertViewDelegate>

@property (nonatomic, assign) id delegate;
@property (nonatomic, strong) CPVenue *venue;
@property (nonatomic, assign) bool checkInIsVirtual;

-(void)userImageButtonPressed:(UIButton *)sender;

@end
