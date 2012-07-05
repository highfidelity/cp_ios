//
//  LogVenuesTableViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 7/3/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "FeedVenuesTableViewController.h"
#import "FeedViewController.h"

#define SHOW_FEED_SEGUE @"ShowVenueFeed"

@interface FeedVenuesTableViewController ()

@end

@implementation FeedVenuesTableViewController

@synthesize venues = _venues;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self reloadDefaultVenues:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newFeedVenueAdded:) name:@"feedVenueAdded" object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)newFeedVenueAdded:(NSNotification *)notification
{
    [self reloadDefaultVenues:notification.object];
    if (self.tabBarController.selectedIndex != 0) {
        self.tabBarController.selectedIndex = 0;
    }
}

- (void)reloadDefaultVenues:(CPVenue *)venueToShow
{
    self.venues = [[NSMutableArray alloc] init];
    
    CPVenue *currentVenue = [CPUserDefaultsHandler currentVenue];
    // if it exists add the user's current venue as the first object in self.venues
    if (currentVenue) { 
        [self.venues addObject:currentVenue];
    }    
    
    NSDictionary *storedFeedVenues = [CPUserDefaultsHandler feedVenues];
    for (NSString *venueIDKey in storedFeedVenues) {
        // grab the NSData representation of the venue and decode it
        NSData *venueData = [storedFeedVenues objectForKey:venueIDKey];
        CPVenue *decodedVenue = [NSKeyedUnarchiver unarchiveObjectWithData:venueData];
        
        // only add the venue if the user isn't checked in there
        if (decodedVenue.venueID != currentVenue.venueID) {
            [self.venues addObject:decodedVenue];
        }
    }
    
    [self.tableView reloadData];
    
    // perform segue to venue feed if we have a venue to show
    if (venueToShow) {
        // select the right cell
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.venues indexOfObject:venueToShow] inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        
        // perform segue to that venue feed
        [self performSegueWithIdentifier:SHOW_FEED_SEGUE sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    CPVenue *selectedVenue;
    
    if ([[segue identifier] isEqualToString:@"ShowVenueFeedForNewPost"]) {
        [[segue destinationViewController] setNewPostAfterLoad:YES];
        selectedVenue = [self.venues objectAtIndex:0];
    } else {
        // get the indexPath for the selected row
        NSIndexPath *selectedPath = [self.tableView indexPathForSelectedRow];
        selectedVenue = [self.venues objectAtIndex:selectedPath.row];
    }
    
    [[segue destinationViewController] setVenue:selectedVenue];
    
    if ([CPAppDelegate tabBarController].forcedCheckin) {
        // if this was a forcedCheckin then the user wants to post an update right away
        [[segue destinationViewController] setNewPostAfterLoad:YES];
        
        // reset the tabBarController's forced checkin variable
        [CPAppDelegate tabBarController].forcedCheckin = NO;
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.venues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FeedVenueCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    CPVenue *feedVenue = [self.venues objectAtIndex:indexPath.row];
    
    cell.textLabel.text = feedVenue.name;
    
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:SHOW_FEED_SEGUE sender:self];
}

@end
