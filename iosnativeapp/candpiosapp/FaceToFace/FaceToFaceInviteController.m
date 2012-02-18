//
//  FaceToFaceInviteController.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/14.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "FaceToFaceInviteController.h"
#import "SVProgressHUD.h"
#import "CPapi.h"

@implementation FaceToFaceInviteController
@synthesize userNickname = _userNickname;
@synthesize userImage = _userImage;
@synthesize f2fText = _f2fText;
@synthesize f2fAcceptButton = _f2fAcceptButton;
@synthesize f2fDeclineButton = _f2fDeclineButton;
@synthesize f2fActionCaption = _f2fActionCaption;
@synthesize f2fPassword = _f2fPassword;

@synthesize user = _user;
@synthesize passwordMode = _passwordMode;

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
    if (self.user == nil)
    {
        [NSException raise:@"Face to Face invite error"
                    format:@"Greeter's userId is invalid: %d", self.user.userID];
    }
    
    if (self.passwordMode != nil)
    {
        self.f2fAcceptButton.hidden = YES;
        self.f2fDeclineButton.hidden = YES;
        self.f2fActionCaption.hidden = YES;
        self.f2fText.text = [NSString stringWithFormat:@"The password is: %@", self.passwordMode];
    }

    [SVProgressHUD showWithStatus:@"Loading request"];
    [self.user loadUserResumeData:^(User *user, NSError *error)
    {
        if (user)
        {
            self.user = user;
            self.userNickname.text = user.nickname;
            // TODO: Why does UserProfileCheckedInViewController have setImageWithURL but we don't??? -alexi 2012-02-17
            // [self.userImage setImageWithURL:user.urlPhoto];
            [SVProgressHUD dismiss];
        }
        else
        {
            [SVProgressHUD dismissWithError:[error localizedDescription]];
        }
    }];

}

- (void)viewDidUnload
{
    [self setUserNickname:nil];
    [self setUserImage:nil];
    [self setF2fText:nil];
    [self setF2fAcceptButton:nil];
    [self setF2fDeclineButton:nil];
    [self setF2fActionCaption:nil];
    [self setF2fPassword:nil];
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
    [CPapi sendF2FAccept:self.user.userID];
    self.f2fText.text = [NSString stringWithFormat:@"Ask %@ for the password to confirm!", self.user.nickname];
    
    self.f2fAcceptButton.hidden = YES;
    self.f2fDeclineButton.hidden = YES;
    self.f2fActionCaption.hidden = YES;
    self.f2fPassword.hidden = NO;
}

- (IBAction)declineF2F {
    [CPapi sendF2FDecline:self.user.userID];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)f2fSubmitPassword {
    [CPapi sendF2FVerify:self.user.userID
                password:self.f2fPassword.text];
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}
@end
