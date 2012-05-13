//
//  ContactListViewController.m
//  candpiosapp
//
//  Created by Fredrik Enestad on 2012-03-19.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ContactListViewController.h"
#import "UserTableViewCell.h"
#import "UserProfileCheckedInViewController.h"
#import "NSString+HTML.h"


// add a nickname selector to NSDictionary so we can sort the contact list
@interface NSDictionary (nickname)
- (NSString *)nickname;
@end

@implementation NSDictionary (nickname)
- (NSString *)nickname
{
    if (![self objectForKey:@"nickname"]) {
        return nil;
    }
    return [self objectForKey:@"nickname"];
}
@end


@interface ContactListViewController () {
    NSArray *sortedContactList;
    NSArray *searchResults;
    BOOL isSearching;
}

@property (weak, nonatomic) IBOutlet UIImageView *placeholderImage;
@end

@implementation ContactListViewController
@synthesize placeholderImage;

@synthesize contacts, searchBar;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        isSearching = NO;
    }
    return self;
}

-(NSArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector
{
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];

    NSInteger sectionCount = [[collation sectionTitles] count]; //section count is take from sectionTitles and not sectionIndexTitles
    NSMutableArray *unsortedSections = [NSMutableArray arrayWithCapacity:(NSUInteger)sectionCount];

    //create an array to hold the data for each section
    for(int i = 0; i < sectionCount; i++)
    {
        [unsortedSections addObject:[NSMutableArray array]];
    }

    //put each object into a section
    for (id object in array)
    {
        NSInteger index = [collation sectionForObject:object collationStringSelector:selector];
        [[unsortedSections objectAtIndex:(NSUInteger)index] addObject:object];
    }

    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:(NSUInteger)sectionCount];

    //sort each section
    for (NSMutableArray *section in unsortedSections)
    {
        [sections addObject:[collation sortedArrayFromArray:section collationStringSelector:selector]];
    }

    return sections;
}

- (void)setContacts:(NSArray *)contactList {
    contacts = [self partitionObjects:contactList collationStringSelector:@selector(nickname)];

    // store the array for search
    sortedContactList = [contactList copy];
}

-(void)hidePlaceholder:(BOOL)hide
{
    [self.placeholderImage setHidden:hide];
    [self.tableView setScrollEnabled:hide];
    [self.searchBar setHidden:!hide];
    isSearching = !hide;
}

- (NSArray*)sectionIndexTitles 
{
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self setPlaceholderImage:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self hidePlaceholder:YES];
    // place the settings button on the navigation item if required
    // or remove it if the user isn't logged in
    [CPUIHelper settingsButtonForNavigationItem:self.navigationItem];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // hide the search bar if it hasn't been scrolled
    if (self.tableView.contentOffset.y == 0.0f) {
        [self.tableView setContentOffset:CGPointMake(0, 44) animated:NO];
    }
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    [CPapi getContactListWithCompletionsBlock:^(NSDictionary *json, NSError *error) {
        [SVProgressHUD dismiss];
        if (!error) {
            if (![[json objectForKey:@"error"] boolValue]) {
                NSMutableArray *payload = [json objectForKey:@"payload"];
                [self hidePlaceholder:[payload count] > 0];
                
                // sort the list by name
                NSSortDescriptor *d = [[NSSortDescriptor alloc] initWithKey:@"nickname" ascending:YES];
                [payload sortUsingDescriptors:[NSArray arrayWithObjects:d,nil]];
                self.contacts = [payload copy];
                
                // update table
                [self.tableView reloadData];
            }
            else {
                NSLog(@"%@",[json objectForKey:@"payload"]);
                [SVProgressHUD dismissWithError:[json objectForKey:@"payload"]
                                     afterDelay:kDefaultDimissDelay];
            }
        }
        else {
            NSLog(@"Coundn't fetch contact list");
        }
    }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (isSearching) return 1;
    return [[self sectionIndexTitles] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (isSearching) return [searchResults count];

    return [[self.contacts objectAtIndex:(NSUInteger)section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)aSection
{
    if (!isSearching) {
        return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:(NSUInteger)aSection];
    }

    return @"";
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (isSearching) return nil;
    return [[NSArray arrayWithObject:UITableViewIndexSearch] arrayByAddingObjectsFromArray:[self sectionIndexTitles]];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (index == 0) {
        [self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
        return NSNotFound;
    }
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index-1];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (NSDictionary *)contactForIndexPath:(NSIndexPath *)indexPath {
    if (isSearching) {
        return [searchResults objectAtIndex:(NSUInteger)[indexPath row]];
    }

    return [[self.contacts objectAtIndex:(NSUInteger)indexPath.section] objectAtIndex:(NSUInteger)indexPath.row];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"UserListCustomCell";

    UserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UserTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    NSDictionary *contact = [self contactForIndexPath:indexPath];

    cell.checkInCountLabel.text = @"";
    cell.checkInLabel.text = @"";
    cell.distanceLabel.text = @"";
    cell.nicknameLabel.text = [contact objectForKey:@"nickname"];
    [CPUIHelper changeFontForLabel:cell.nicknameLabel toLeagueGothicOfSize:18.0];

    NSString *status = [contact objectForKey:@"status_text"];
    cell.statusLabel.text = @"";
    if (status.length > 0) {
        status = [[status stringByDecodingHTMLEntities] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        cell.statusLabel.text = [NSString stringWithFormat:@"\"%@\"",status];
    }

    UIImageView *imageView = cell.profilePictureImageView;
    if ([contact objectForKey:@"imageUrl"] != [NSNull null]) {

        imageView.contentMode = UIViewContentModeScaleAspectFill;

        [imageView setImageWithURL:[NSURL URLWithString:[contact objectForKey:@"imageUrl"]]
                       placeholderImage:[CPUIHelper defaultProfileImage]];
    }
    else
    {
        imageView.image = [CPUIHelper defaultProfileImage];
    }

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *contact = [self contactForIndexPath:indexPath];
    User *user = [[User alloc] init];
    user.nickname = [contact objectForKey:@"nickname"];
    user.userID = [[contact objectForKey:@"id"] intValue];
    user.status = [contact objectForKey:@"status_text"];
    user.urlPhoto = [contact objectForKey:@"imageUrl"];

    // instantiate a UserProfileViewController
    UserProfileCheckedInViewController *vc = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
    vc.user = user;
    [self.navigationController pushViewController:vc animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    if (isSearching) return nil;

    NSString *title = [self tableView:tableView titleForHeaderInSection:section];

    UIView *theView = [[UIView alloc] init];
    theView.backgroundColor = RGBA(66, 66, 66, 1);

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    [label sizeToFit];

    label.frame = CGRectMake(label.frame.origin.x+10, label.frame.origin.y+1, label.frame.size.width, label.frame.size.height);

    [theView addSubview:label];

    return theView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (isSearching || ![[self.contacts objectAtIndex:(NSUInteger)section] count]) {
        return 0;
    }


    return 22.0;
}

#pragma mark - UISearchBarDelegate
- (void)performSearch:(NSString *)searchText {
    if ([searchText isEqualToString:@""]) {
        searchResults = [sortedContactList copy];
    }
    else {
        searchResults = [sortedContactList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(nickname contains[cd] %@)", searchText]];
    }
    [self.tableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)aSearchBar {
    isSearching = YES;
    [aSearchBar setShowsCancelButton:YES animated:YES];
    [self performSearch:aSearchBar.text];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar {
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.searchBar setText:@""];
    [self.searchBar resignFirstResponder];
    isSearching = NO;
    [self.tableView reloadData];
}
- (void)searchBar:(UISearchBar *)aSearchBar textDidChange:(NSString *)searchText {
    [self performSearch:searchText];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar {
    [self.searchBar resignFirstResponder];
}


@end
