//
//  CheckInDetailsViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "CPPlace.h"

@interface CheckInDetailsViewController : UIViewController

@property (nonatomic,strong) CPPlace *place;
-(void)userImageButtonPressed:(UIButton *)sender;

@end
