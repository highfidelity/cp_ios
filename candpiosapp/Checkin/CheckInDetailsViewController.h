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

@property (strong, nonatomic) CPVenue *venue;
@property (weak, nonatomic) id delegate;
@property (nonatomic) BOOL checkInIsVirtual;

-(void)userImageButtonPressed:(UIButton *)sender;

@end
