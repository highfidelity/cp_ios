//
//  FaceToFaceInviteController.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/14.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "FaceToFaceInviteController.h"
#import "SVProgressHUD.h"

@implementation FaceToFaceInviteController
@synthesize greeterNickname = _greeterNickname;
@synthesize greeterImage = _greeterImage;

@synthesize greeter = _greeter;

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Look up the user's information
    if (self.greeter == nil) {
        [NSException raise:@"Face to Face invite error"
                    format:@"Greeter's userId is invalid: %d", self.greeter.userID];
    }

    [SVProgressHUD showWithStatus:@"Loading request"];
    [self.greeter loadUserResumeData:^(User *user, NSError *error) {
        if (user) {
            self.greeter = user;
            self.greeterNickname.text = user.nickname;
            // TODO: Why does UserProfileCheckedInViewController have setImageWithURL but we don't??? -alexi 2012-02-17
            // [self.greeterImage setImageWithURL:user.urlPhoto];
            [SVProgressHUD dismiss];
        } else {
            [SVProgressHUD dismissWithError:[error localizedDescription]];
        }
    }];

}

- (void)viewDidUnload
{
    [self setGreeterNickname:nil];
    [self setGreeterImage:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Actions

- (IBAction)acceptF2F {
    // TODO: send the accept command
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)declineF2F {
    // TODO: send the decline command
    [self dismissModalViewControllerAnimated:YES];
}
@end
