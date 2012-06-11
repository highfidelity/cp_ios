//
//  LogCreateViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPPlaceholderTextView.h"

@interface LogCreateViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet CPPlaceholderTextView *logTextView;

@end
