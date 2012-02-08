//
//  RootNavigationController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/2/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "RootNavigationController.h"

@implementation RootNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addCheckInButton];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)addCheckInButton 
{
    UIButton *checkInButton = [UIButton buttonWithType:UIButtonTypeCustom];
    checkInButton.backgroundColor = [UIColor clearColor];
    checkInButton.frame = CGRectMake(235, 395, 75, 75);
    [checkInButton addTarget:self action:@selector(checkInButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [checkInButton setImage:[UIImage imageNamed:@"checked-in.png"] forState:UIControlStateNormal];
    checkInButton.tag = 901;
    [self.view addSubview:checkInButton];    
}

- (void)checkInButtonPressed:(id)sender
{
    [self performSegueWithIdentifier:@"ShowCheckInListTable" sender:self];
}

@end
