//
//  UserProfileCheckedInViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserProfileCheckedInViewController.h"
#import "OneOnOneChatViewController.h"
#import "SVProgressHUD.h"
#import "AFHTTPClient.h"
#import "UIImageView+WebCache.h"

@interface UserProfileCheckedInViewController()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@end

@implementation UserProfileCheckedInViewController

@synthesize mapView = _mapView;
@synthesize user = _user;
@synthesize userCard = _userCard;


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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.user.nickname;
    self.userCard.backgroundColor =[UIColor colorWithPatternImage:[UIImage imageNamed:@"paper-texture.jpg"]];
    
    MKCoordinateRegion region = MKCoordinateRegionMake(self.user.location, MKCoordinateSpanMake(0.005, 0.005));
    [self.mapView setRegion:region];
        
    CGPoint rightAndUp = CGPointMake(238 - (self.mapView.bounds.size.width / 2), 206 - (self.mapView.bounds.size.height / 2));
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:rightAndUp toCoordinateFromView:self.mapView];
    [self.mapView setCenterCoordinate:coordinate animated:NO];
    
    self.userCard.nickname.text = self.user.nickname;
    self.userCard.status.text = self.user.status;
    
    // pull up SVProgressHUD so we can load the user data
    [SVProgressHUD showWithStatus:@"Loading"];
    // get a user object with resume data
    [self.user loadUserResumeData:^(User *user, NSError *error) {
        if (user) {
            self.user = user;   
            [self.userCard.imageView  setImageWithURL:self.user.urlPhoto];
            [SVProgressHUD dismiss];
        } else {
            [SVProgressHUD dismissWithError:[error localizedDescription]];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // hide the progress HUD if the user is going back and it's still loading
    [SVProgressHUD dismiss];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"OneOnOneChatSegue"])
	{
        // Tell the OneOnOneChatViewController what user they're going to be
        // chatting with.
        [[segue destinationViewController] setUser:self.user];
    }
}

@end
