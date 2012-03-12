//
//  FaceToFacePasswordInputViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 3/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "FaceToFacePasswordInputViewController.h"
#import "CPapi.h"

@interface FaceToFacePasswordInputViewController ()

@end

@implementation FaceToFacePasswordInputViewController
@synthesize passwordField;
@synthesize waitLabel;
@synthesize navigationItem;

// This may seem a little strange but this view controller is never actually on screen.
// It's used to append a view onto the bottom of the F2FAcceptDeclineView (which allows for the scrolling transition)

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // empty the passwordField
    self.passwordField.text = @"";
}

- (void)viewDidUnload
{
    [self setPasswordField:nil];
    [self setWaitLabel:nil];
    [self setNavigationItem:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
