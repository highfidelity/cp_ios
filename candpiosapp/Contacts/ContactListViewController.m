//
//  ContactListViewController.m
//  candpiosapp
//
//  Created by Fredrik Enestad on 2012-03-19.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ContactListViewController.h"
#import "UserProfileViewController.h"
#import "GTMNSString+HTML.h"
#import "UserLoveViewController.h"
#import "UIViewController+CPUserActionCellAdditions.h"

#define kContactRequestsSection 0
#define kExtraContactRequestsSections 1
#define kHeightForHeader 22.0
#define kContactRequestsCellIdentifier @"ContactRequestCell"
NSString *const kQuickActionPrefix = @"send-love-switch";

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
    NSMutableArray *sortedContactList;
    NSArray *searchResults;
    BOOL isSearching;
}

@property (weak, nonatomic) IBOutlet UIImageView *placeholderImage;
@property (nonatomic, assign) BOOL userIsPerformingQuickAction;
@property (nonatomic, assign) BOOL reloadPrevented;

- (NSIndexPath *)addToContacts:(NSDictionary *)contactData;
- (void)animateRemoveContactRequestAtIndex:(NSUInteger)index;
- (void)handleSendAcceptOrDeclineComletionWithJson:(NSDictionary *)json andError:(NSError *)error;
- (void)updateBadgeValue;
- (void)setBadgeNumber:(NSInteger)badgeNumber;
- (NSDictionary *)contactForIndexPath:(NSIndexPath *)indexPath;
- (User *)userForIndexPath:(NSIndexPath *)indexPath;

@end


@implementation ContactListViewController

@synthesize placeholderImage;
@synthesize userIsPerformingQuickAction = _userIsPerformingQuickAction;
@synthesize reloadPrevented = _reloadPrevented;
@synthesize contacts, searchBar;
@synthesize contactRequests = _contactRequests;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        isSearching = NO;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(numberOfContactRequestsNotification:)
                                                     name:kNumberOfContactRequestsNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNumberOfContactRequestsNotification
                                                  object:nil];
}

- (NSMutableArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector
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
        [sections addObject:[[collation sortedArrayFromArray:section collationStringSelector:selector] mutableCopy]];
    }

    return sections;
}

- (void)setContacts:(NSMutableArray *)contactList {
    contacts = [self partitionObjects:contactList collationStringSelector:@selector(nickname)];
    
    // store the array for search
    sortedContactList = [contactList mutableCopy];
}

- (void)hidePlaceholder:(BOOL)hide
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self hidePlaceholder:YES];
    // place the settings button on the navigation item if required
    // or remove it if the user isn't logged in
    [CPUIHelper settingsButtonForNavigationItem:self.navigationItem];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [CPUserActionCell cancelOpenSlideActionButtonsNotification:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // let the CPUserActionCell manage selection
    self.tableView.allowsSelection = NO;
    
    // hide the search bar if it hasn't been scrolled
    if (self.tableView.contentOffset.y == 0.0f) {
        [self.tableView setContentOffset:CGPointMake(0, 44) animated:NO];
    }
    
    [self showCorrectLoadingSpinnerForCount:self.contacts.count + self.contactRequests.count];
    [CPapi getContactListWithCompletionsBlock:^(NSDictionary *json, NSError *error) {
        [self stopAppropriateLoadingSpinner];
        if (!error) {
            if (![[json objectForKey:@"error"] boolValue]) {
                NSArray *payload = [json objectForKey:@"payload"];
                NSArray *contactRequests = [json objectForKey:@"contact_requests"];
                
                [self hidePlaceholder:[payload count] > 0 || [contactRequests count] > 0];
                
                NSSortDescriptor *nicknameSort = [[NSSortDescriptor alloc] initWithKey:@"nickname" ascending:YES];
                
                // No reason to sort if there is 1 or less
                if (payload.count > 1) { 
                    payload = [payload sortedArrayUsingDescriptors:[NSArray arrayWithObject:nicknameSort]]; 
                }
                if (contactRequests.count > 1) {
                    contactRequests = [contactRequests sortedArrayUsingDescriptors:[NSArray arrayWithObject:nicknameSort]]; 
                }
                
                
                self.contacts = [payload mutableCopy];
                self.contactRequests = [contactRequests mutableCopy];
                
                if (!self.userIsPerformingQuickAction) {
                    NSUInteger preReloadVisibleCellsCount = [self.tableView.visibleCells count];
                    
                    [self.tableView reloadData];
                    
                    if (!preReloadVisibleCellsCount) {
                        [self animateSlideWaveWithCPUserActionCells:self.tableView.visibleCells];
                    }
                } else {
                    self.reloadPrevented = YES;
                }
                [self updateBadgeValue];
            }
            else {
                NSLog(@"%@",[json objectForKey:@"payload"]);
                [SVProgressHUD showErrorWithStatus:[json objectForKey:@"payload"] duration:kDefaultDismissDelay];
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [CPUserActionCell cancelOpenSlideActionButtonsNotification:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (isSearching) {
        return 1;
    }
    
    return [[self sectionIndexTitles] count] + kExtraContactRequestsSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (isSearching) {
        return [searchResults count];
    }
    
    if (kContactRequestsSection == section) {
        return [self.contactRequests count];
    }
    
    return [[self.contacts objectAtIndex:(NSUInteger)section - kExtraContactRequestsSections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)aSection
{
    if (!isSearching) {
        if (kContactRequestsSection == aSection) {
            if ([self.contactRequests count]) {
                return @"Contact Requests";
            }
            return nil;
        }
        
        return [[[UILocalizedIndexedCollation currentCollation] sectionTitles]
                objectAtIndex:(NSUInteger)aSection - kExtraContactRequestsSections];
    }

    return @"";
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (isSearching) {
        return nil;
    }
    
    return [[NSArray arrayWithObject:UITableViewIndexSearch] arrayByAddingObjectsFromArray:[self sectionIndexTitles]];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (index == 0) {
        [self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
        return NSNotFound;
    }
    
    return [[UILocalizedIndexedCollation currentCollation]
            sectionForSectionIndexTitleAtIndex:index - 1 + kExtraContactRequestsSections];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"ContactListCell";
    if (!isSearching && kContactRequestsSection == indexPath.section) {
        CellIdentifier = kContactRequestsCellIdentifier;
    }
    
    ContactListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ContactListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    NSDictionary *contact = [self contactForIndexPath:indexPath];

    cell.nicknameLabel.text = [contact objectForKey:@"nickname"];
    [CPUIHelper changeFontForLabel:cell.nicknameLabel toLeagueGothicOfSize:18.0];

    NSString *status = [contact objectForKey:@"status_text"];
    bool checkedIn = [[contact objectForKey:@"checked_in"]boolValue];
    cell.statusLabel.text = @"";
    if (status.length > 0 && checkedIn) {
        status = [[status gtm_stringByUnescapingFromHTML] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        cell.statusLabel.text = [NSString stringWithFormat:@"\"%@\"",status];
    }

    UIImageView *imageView = cell.profilePicture;
    if (![[contact objectForKey:@"imageUrl"] isKindOfClass:[NSNull class]]) {

        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [imageView setImageWithURL:[NSURL URLWithString:[contact objectForKey:@"imageUrl"]]
                       placeholderImage:[CPUIHelper defaultProfileImage]];
    } else {
        imageView.image = [CPUIHelper defaultProfileImage];
    }

    cell.user = [self userForIndexPath:indexPath];

    if ([CellIdentifier isEqualToString:kContactRequestsCellIdentifier]) {
        cell.acceptContactRequestButton.hidden = NO;
        cell.declineContactRequestButton.hidden = NO;
        
        cell.contactListTVC = self;
        cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        cell.backgroundView.backgroundColor = RGBA(66, 128, 128, 1);
        
        cell.rightStyle = CPUserActionCellSwipeStyleNone;
    } else {
        cell.rightStyle = CPUserActionCellSwipeStyleReducedAction;
        cell.delegate = self;
    }

    return cell;
}


#pragma mark - Table view delegate

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

    label.frame = CGRectMake(label.frame.origin.x+10,
                             label.frame.origin.y+1,
                             label.frame.size.width,
                             label.frame.size.height);

    [theView addSubview:label];

    return theView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (isSearching) {
        return 0;
    }
    
    if (kContactRequestsSection == section) {
        if ([self.contactRequests count]) {
            return kHeightForHeader;
        }
        return 0;
    }
    
    if (0 == [[self.contacts objectAtIndex:(NSUInteger)section - kExtraContactRequestsSections] count]) {
        return 0;
    }
    
    return kHeightForHeader;
}

#pragma mark - UISearchBarDelegate
- (void)performSearch:(NSString *)searchText {
    if ([searchText isEqualToString:@""]) {
        searchResults = [NSArray arrayWithArray:sortedContactList];
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

#pragma mark - UserTableViewCellDelegate

- (void)clickedAcceptButtonInUserTableViewCell:(ContactListCell *)contactListCell {
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:contactListCell];
    NSDictionary *contactData = [self.contactRequests objectAtIndex:indexPath.row];
    
    [self.tableView beginUpdates];
    {
        [self.contactRequests removeObjectAtIndex:indexPath.row];
        [self animateRemoveContactRequestAtIndex:indexPath.row];
        
        NSIndexPath *newContactIndexPath = [self addToContacts:contactData];
        
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newContactIndexPath]
                              withRowAnimation:UITableViewRowAnimationFade];
        if (1 == [[self.contacts objectAtIndex:newContactIndexPath.section - kExtraContactRequestsSections] count]) {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:newContactIndexPath.section]
                          withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    [self.tableView endUpdates];
    
    [CPapi sendAcceptContactRequestFromUserId:[[contactData objectForKey:@"id"] intValue]
                                   completion:^(NSDictionary *json, NSError *error) {
                                       [self handleSendAcceptOrDeclineComletionWithJson:json andError:error];
                                   }];
    
    [self updateBadgeValue];
}

- (void)clickedDeclineButtonInUserTableViewCell:(ContactListCell *)contactListCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:contactListCell];
    NSDictionary *contactData = [self.contactRequests objectAtIndex:indexPath.row];
    
    [self.contactRequests removeObjectAtIndex:indexPath.row];
    [self animateRemoveContactRequestAtIndex:indexPath.row];
    
    [CPapi sendDeclineContactRequestFromUserId:[[contactData objectForKey:@"id"] intValue]
                                    completion:^(NSDictionary *json, NSError *error) {
                                        [self handleSendAcceptOrDeclineComletionWithJson:json andError:error];
                                    }];
    
    [self updateBadgeValue];
}

#pragma mark - actions

- (void)numberOfContactRequestsNotification:(NSNotification *)notification {
    [self setBadgeNumber:[[[notification userInfo] objectForKey:@"numberOfContactRequests"] integerValue]];
}

#pragma mark - private

- (NSIndexPath *)addToContacts:(NSDictionary *)contactData {
    NSInteger sectionIndex = [[UILocalizedIndexedCollation currentCollation] sectionForObject:contactData
                                                                      collationStringSelector:@selector(nickname)];
    NSMutableArray *sectionContacts = [self.contacts objectAtIndex:sectionIndex];
    NSArray *sortDescriptors = [NSArray arrayWithObject:
                                [[NSSortDescriptor alloc] initWithKey:@"nickname" ascending:YES]];
    
    
    [sectionContacts addObject:contactData];
    [sortedContactList addObject:contactData];
    
    [sectionContacts sortUsingDescriptors:sortDescriptors];
    [sortedContactList sortUsingDescriptors:sortDescriptors];
    
    NSIndexPath *contactIndexPath = [NSIndexPath indexPathForRow:[sectionContacts indexOfObject:contactData]
                                                       inSection:sectionIndex + kExtraContactRequestsSections];
    return contactIndexPath;
}

- (void)animateRemoveContactRequestAtIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:kContactRequestsSection];
    
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
    
    if (0 == [self.contactRequests count]) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                      withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)handleSendAcceptOrDeclineComletionWithJson:(NSDictionary *)json andError:(NSError *)error {
    NSString *errorMessage = nil;
    
    if (error) {
        errorMessage = [error localizedDescription];
    } else {
        if (json == NULL) {
            errorMessage = @"We couldn't send the request.\nPlease try again.";
        } else if ([[json objectForKey:@"error"] boolValue]) {
            errorMessage = [json objectForKey:@"message"];
        }
    }
    
    if (errorMessage) {
        [SVProgressHUD showErrorWithStatus:errorMessage duration:kDefaultDismissDelay];
    }
}

- (void)updateBadgeValue {
    [self setBadgeNumber:[self.contactRequests count]];
}

- (void)setBadgeNumber:(NSInteger)badgeNumber {
    NSString *badgeValue = nil;
    if (badgeNumber > 0) {
        badgeValue = [NSString stringWithFormat:@"%d", badgeNumber];
    }
    self.navigationController.tabBarItem.badgeValue = badgeValue;
}

- (NSDictionary *)contactForIndexPath:(NSIndexPath *)indexPath {
    if (isSearching) {
        return [searchResults objectAtIndex:(NSUInteger)[indexPath row]];
    }
    
    if (kContactRequestsSection == indexPath.section) {
        return [self.contactRequests objectAtIndex:indexPath.row];
    }
    
    return [[self.contacts objectAtIndex:(NSUInteger)indexPath.section - kExtraContactRequestsSections]
            objectAtIndex:(NSUInteger)indexPath.row];
}

- (User *)userForIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *contact = [self contactForIndexPath:indexPath];
    User *user = [[User alloc] init];
    user.nickname = [contact objectForKey:@"nickname"];
    user.userID = [[contact objectForKey:@"id"] intValue];
    user.status = [contact objectForKey:@"status_text"];
    user.photoURLString = [contact objectForKey:@"imageUrl"];
    
    return user;
}

@end
