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

@property (nonatomic, weak) IBOutlet UITextField *passwordField;
@property (nonatomic, weak) IBOutlet UILabel *waitLabel;
@property (nonatomic, weak) IBOutlet UINavigationItem *f2fNavigationItem;

@end
