//
//  FaceToFacePasswordInputViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 3/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "FaceToFacePasswordInputViewController.h"

@implementation FaceToFacePasswordInputViewController

// This may seem a little strange but this view controller is never actually on screen.
// It's used to append a view onto the bottom of the F2FAcceptDeclineView (which allows for the scrolling transition)

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // empty the passwordField
    self.passwordField.text = @"";
}

@end
