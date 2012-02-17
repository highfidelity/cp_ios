//
//  CheckInDetailsViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CheckInDetailsViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface CheckInDetailsViewController()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *checkInLabel;
@property (weak, nonatomic) IBOutlet UILabel *placeName;
@property (weak, nonatomic) IBOutlet UILabel *placeAddress;

@end

@implementation CheckInDetailsViewController
@synthesize mapView = _mapView;
@synthesize scrollView = _scrollView;
@synthesize checkInLabel = _checkInLabel;
@synthesize placeName = _placeName;
@synthesize placeAddress = _placeAddress;
@synthesize place = _place;

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
    self.title = self.place.name;
    
    // make an MKCoordinate region for the zoom level on the map
    MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(self.place.lat, self.place.lng), MKCoordinateSpanMake(0.003, 0.003));
    [self.mapView setRegion:region];
    
    // this will always be the point on iPhones up to iPhone4
    // if this needs to be used on iPad we'll need to do this programatically or use an if-else
    CGPoint moveRight = CGPointMake(71, 58);
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:moveRight toCoordinateFromView:self.mapView];
    [self.mapView setCenterCoordinate:coordinate animated:NO];
    
    // set LeagueGothic font where applicable
    UIFont *gothic = [UIFont fontWithName:@"LeagueGothic" size:26.f];
    for (UILabel *labelNeedsGothic in [NSArray arrayWithObjects:self.checkInLabel, nil]) {
        labelNeedsGothic.font = gothic;
    }
    
    // shadow on business card and resume
    CGColorRef shadowColor = [[UIColor blackColor] CGColor];
    CGSize shadowOffset = CGSizeMake(0,2);
    double shadowRadius = 3;
    double shadowOpacity = 1.0;
    for (UIView *needsShadow in [NSArray arrayWithObjects:self.mapView, nil]) {
        needsShadow.layer.shadowColor = shadowColor;
        needsShadow.layer.shadowOffset = shadowOffset;
        needsShadow.layer.shadowRadius = shadowRadius;
        needsShadow.layer.shadowOpacity = shadowOpacity;
        needsShadow.layer.shadowPath = [UIBezierPath bezierPathWithRect:needsShadow.bounds].CGPath;
    } 
    
    // set the diagonal noise texture on the horizontal scrollview
    UIColor *texture = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-diagonal-noise.png"]];
    self.scrollView.backgroundColor = texture;
    
    // set the light diagonal noise texture on the bottom UIView
    UIColor *texture = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-diagonal-noise.png"]];
    
    
    
    
    self.placeName.text = self.place.name;
    self.placeAddress.text = self.place.address;
}

- (void)viewDidUnload
{
    [self setMapView:nil];
    [self setScrollView:nil];
    [self setPlaceName:nil];
    [self setPlaceAddress:nil];
    [self setCheckInLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
