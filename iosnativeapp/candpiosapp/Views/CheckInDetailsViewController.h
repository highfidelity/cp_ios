//
//  CheckInDetailsViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "CPVenue.h"

@interface CheckInDetailsViewController : UIViewController

@property (nonatomic, assign) id delegate;
@property (nonatomic, strong) CPVenue *place;

-(void)userImageButtonPressed:(UIButton *)sender;

@end
