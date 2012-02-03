//
//  UserListTableViewController.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserListTableViewController.h"
#import "MissionAnnotation.h"
#import "UIImageView+WebCache.h"
#import "WebViewController.h"
#import "UserAnnotation.h"
#import "AppDelegate.h"
#import "UserTableViewCell.h"
#import "UserProfileCheckedInViewController.h"

@implementation UserListTableViewController

@synthesize missions, orderedMissions;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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

    self.title = @"List";
    
    // Iterate through the passed missions and only show the ones that were within the map bounds, ordered by distance

    CLLocation *currentLocation = [AppDelegate instance].settings.lastKnownLocation;
    
    for (UserAnnotation *annotation in missions) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:annotation.lat longitude:annotation.lon];
        annotation.distance = [location distanceFromLocation:currentLocation];
    }
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"distance" ascending:YES];

    [missions sortUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"Count: %d", [missions count]);
    return [missions count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return a slightly taller final cell if more than 5 rows, and on the last row, to compensate for the Check In button cutting into the view

    if ([missions count] > 5 && indexPath.row < ([missions count] - 1)) {
        return 60;
    }
    else {
        return 70;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UserTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    // Configure the cell...
    
    UserAnnotation *annotation = [missions objectAtIndex:indexPath.row];
//    cell.textLabel.text = [NSString stringWithFormat:@"%@, %@, %f", [annotation nickname], [annotation skills], [annotation distance]];

    cell.nicknameLabel.text = annotation.nickname;
    if (annotation.skills != [NSNull null]) {
        cell.skillsLabel.text = annotation.skills;
    }
    cell.distanceLabel.text = [NSString stringWithFormat:@"%.1f meters", annotation.distance];
    
    if (annotation.imageUrl) {
        UIImageView *leftCallout = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 32, 32)];
		
		leftCallout.contentMode = UIViewContentModeScaleAspectFill;
        
        [leftCallout setImageWithURL:[NSURL URLWithString:annotation.imageUrl]
                    placeholderImage:[UIImage imageNamed:@"63-runner.png"]];
        
        cell.imageView.image = leftCallout.image;
    }
    else
    {
        cell.imageView.image = [UIImage imageNamed:@"63-runner.png"];			
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MissionAnnotation *annotation = [missions objectAtIndex:indexPath.row];

    UserProfileCheckedInViewController *controller = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"UserProfileCheckedIn"];
    
    [self.navigationController pushViewController:controller animated:YES];
}

@end
