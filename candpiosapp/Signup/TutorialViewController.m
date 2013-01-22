//
//  TutorialViewController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 10/23/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

/*
examle json:
{
    "pages": [
        {"url": "http://tomashoracek.com/media/tutorial1.png"},
        {"url": "http://tomashoracek.com/media/tutorial2.png"},
        {
            "url": "http://tomashoracek.com/media/tutorial3.png",
            "user_cell": {
                "frame": "{{0, 173}, {320, 59}}",
                "name": "Dan McDonley",
                "image": "http://tomashoracek.com/media/tutorial3-profile-image.png"
            }
        }
    ],
    "pager_frame": "{{0, 77}, {320, 34}}"
}
*/

#import "TutorialViewController.h"
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "CPPageControl.h"
#import "ContactListViewController.h"
#import "CPUIHelper.h"

@interface TutorialViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) CPPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (strong, nonatomic) NSMutableArray *pageImageViews;
@property (strong, nonatomic) NSArray *pageInfos;

@end


@implementation TutorialViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.isShownFromLeft = NO;
        self.pageImageViews = [NSMutableArray array];
        [self startLoadingJSON];
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger pageIndex = round(self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
    self.pageControl.currentPage = pageIndex;
    [self pageWasSelectedWithIndex:pageIndex];
}

#pragma mark - actions

- (IBAction)dismissAction
{
    if (self.isShownFromLeft) {
        [[CPAppDelegate settingsMenuViewController] slideAwayChildViewController];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)pageWasSelected
{
    [self.scrollView setContentOffset:CGPointMake(self.pageControl.currentPage * self.scrollView.frame.size.width, 0) animated:YES];
    [self pageWasSelectedWithIndex:self.pageControl.currentPage];
}

#pragma mark - private

- (void)startLoadingJSON
{
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"https://s3.amazonaws.com"]];
    [client registerHTTPOperationClass:[AFJSONRequestOperation class]];

    [client getPath:kTutorialConfigPath
         parameters:nil
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSDictionary *json = responseObject;

                self.pageInfos = json[@"pages"];
                [self initializeSubviewsWithInfo:json];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self dismissAction];
            }];
}

- (void)initializeSubviewsWithInfo:(NSDictionary *)info
{
    CGFloat pageControlHeight = 34;
    CGFloat pageControlWidth = self.nextButton.frame.origin.x - CGRectGetMaxX(self.backButton.frame);
    
    // dot center should 2 pt lower than button center
    self.pageControl = [[CPPageControl alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.backButton.frame),
                                                                       (self.nextButton.center.y + 2) - (pageControlHeight / 2),
                                                                       pageControlWidth,
                                                                       pageControlHeight)];
    self.pageControl.numberOfPages = [self.pageInfos count];
    [self.pageControl addTarget:self action:@selector(pageWasSelected) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.pageControl];
    [self.view bringSubviewToFront:self.pageControl];

    self.scrollView.backgroundColor = [UIColor colorWithR:246 G:247 B:245 A:246];
    self.scrollView.contentSize = CGSizeMake(self.pageControl.numberOfPages * self.scrollView.frame.size.width,
                                             self.scrollView.frame.size.height);

    for (NSUInteger pageIndex = 0; pageIndex < [self.pageInfos count]; pageIndex++) {
        NSDictionary *pageInfo = self.pageInfos[pageIndex];
        [self initializePageAtIndex:pageIndex withPageInfo:pageInfo];
    }
}

- (void)initializePageAtIndex:(NSUInteger)pageIndex withPageInfo:(NSDictionary *)pageInfo
{
    // regardless of iPhone 4 vs iPhone 5 the imageView is 460 pts
    float imageViewHeight = 460;
    
    UIImageView *pageImageView = [[UIImageView alloc] initWithFrame:CGRectMake(pageIndex * self.scrollView.frame.size.width,
                                                                               (self.scrollView.frame.size.height - imageViewHeight) / 2,
                                                                               self.scrollView.frame.size.width,
                                                                               imageViewHeight)];
    
    [pageImageView setImageWithURL:[NSURL URLWithString:pageInfo[@"url"]]];
    pageImageView.clipsToBounds = YES;
    [self.pageImageViews addObject:pageImageView];
    [self.scrollView addSubview:pageImageView];

    NSDictionary *cellInfo = pageInfo[@"user_cell"];
    if (cellInfo) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        ContactListViewController *contactListViewController = [storyboard instantiateViewControllerWithIdentifier:@"ContactListViewController"];

        ContactListCell *cell = [contactListViewController.tableView dequeueReusableCellWithIdentifier:@"ContactListCell"];
        [CPUIHelper changeFontForLabel:cell.nicknameLabel toLeagueGothicOfSize:18.0];

        cell.nicknameLabel.text = cellInfo[@"name"];
        cell.statusLabel.text = nil; 
        cell.frame = CGRectFromString(cellInfo[@"frame"]);
        
        [cell.profilePicture setImageWithURL:[NSURL URLWithString:cellInfo[@"image"]]
                            placeholderImage:[CPUIHelper defaultProfileImage]];
        cell.rightStyle = CPUserActionCellSwipeStyleReducedAction;

       [pageImageView addSubview:cell];
    }
}

- (void)pageWasSelectedWithIndex:(NSUInteger)pageIndex
{
    if (pageIndex >= self.pageInfos.count) {
        return;
    }
    
    self.backButton.hidden = (pageIndex == 0);
    
    // if this is one of the last two pages
    // we might need to change the next button image
    if (pageIndex >= self.pageControl.numberOfPages - 2) {
        NSString *nextPrefixName = pageIndex == self.pageControl.numberOfPages - 1
            ? @"tutorial-done"
            : @"tutorial-next";
        [self.nextButton setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@-default", nextPrefixName]]
                                   forState:UIControlStateNormal];
        [self.nextButton setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@-highlighted", nextPrefixName]]
                                   forState:UIControlStateHighlighted];
    }
    
    NSDictionary *pageInfo = self.pageInfos[pageIndex];
    NSDictionary *cellInfo = pageInfo[@"user_cell"];
    if (cellInfo) {
        UIImageView *pageImageView = self.pageImageViews[pageIndex];
        ContactListCell *cell = pageImageView.subviews[0];

        [cell animateSlideButtonsWithNewCenter:cell.originalCenter
                                                   delay:0
                                                duration:0
                                                animated:NO];

        [cell animateSlideButtonsWithNewCenter:cell.originalCenter + 130
                                                   delay:0.5
                                                duration:0.2
                                                animated:YES];
    }
}

#pragma mark - Button IBActions

- (IBAction)backButtonPressed:(id)sender {
    self.pageControl.currentPage -= 1;
    [self pageWasSelected];
}

- (IBAction)nextButtonPressed:(id)sender {
    if (self.pageControl.currentPage == self.pageControl.numberOfPages - 1) {
        [self dismissAction];
    } else {
        self.pageControl.currentPage += 1;
        [self pageWasSelected];
    }
}

@end
