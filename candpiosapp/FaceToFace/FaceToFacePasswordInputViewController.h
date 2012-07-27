//
//  FaceToFacePasswordInputViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 3/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FaceToFaceAcceptDeclineViewController.h"

@interface FaceToFacePasswordInputViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UILabel *waitLabel;
@property (weak, nonatomic) IBOutlet UINavigationItem *f2fNavigationItem;

@end
