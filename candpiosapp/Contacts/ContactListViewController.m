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
#import "CPObjectManager.h"

#define kContactRequestsSection 0
#define kExtraContactRequestsSections 1
#define kHeightForHeader 22.0
#define kContactRequestsCellIdentifier @"ContactRequestCell"
NSString *const kQuickActionPrefix = @"send-love-switch";

@interface ContactListViewController ()

@property (strong, nonatomic) NSMutableArray *sortedContactList;
@property (strong, nonatomic) NSArray *searchResults;
@property (strong, nonatomic) IBOutlet UIImageView *placeholderImageView;
@property (nonatomic) BOOL userIsPerformingQuickAction;
@property (nonatomic) BOOL reloadPrevented;
@property (nonatomic) BOOL isSearching;

- (NSIndexPath *)addToContacts:(NSDictionary *)contactData;
- (void)animateRemoveContactRequestAtIndex:(NSUInteger)index;
- (void)handleSendAcceptOrDeclineComletionWithJson:(NSDictionary *)json andError:(NSError *)error;
- (void)updateBadgeValue;

@end

@implementation ContactListViewController

#pragma mark - Class methods

+ (void)getNumberOfContactRequestsAndUpdateBadge
{
    [CPapi getNumberOfContactRequests:^(NSDictionary *json, NSError *error) {
        // no error handling to do here
        // if we get it, then update it, otherwise we'll leave it
        if (!error && ![[json objectForKey:@"error"] boolValue]) {
            
            // give that new value to CPUserDefaultsHandler
            // it'll update the badge
            [CPUserDefaultsHandler setNumberOfContactRequests:[[json valueForKeyPath:@"payload.number_of_contact_requests"] integerValue]];
        }
    }];
}

#pragma mark - Instance methods

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self hidePlaceholderImageView:YES];
    // place the settings button on the navigation item if required
    // or remove it if the user isn't logged in
    [CPUIHelper settingsButtonForNavigationItem:self.navigationItem];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // let the CPUserActionCell manage selection
    self.tableView.allowsSelection = NO;
    
    // hide the search bar if it hasn't been scrolled
    if (self.tableView.contentOffset.y == 0.0f && ![CPUtils isDeviceWithFourInchDisplay]) {
        [self.tableView setContentOffset:CGPointMake(0, 44) animated:NO];
    }
    
    [self showCorrectLoadingSpinnerForCount:self.contacts.count + self.contactRequests.count];
    [self reloadContactList];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [CPUserActionCell cancelOpenSlideActionButtonsNotification:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadContactList
{
    [[CPObjectManager sharedManager] getObjectsAtPathForRouteNamed:kRouteContactsAndRequests
                                                            object:nil
                                                        parameters:@{@"v" : @"20121129"}
                                                           success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult)
    {
        self.contacts = [NSMutableArray array];
        self.contactRequests = [NSMutableArray array];
        
        for (CPUser *potentialContact in mappingResult.array) {
            if ([potentialContact.isContact boolValue]) {
                [self.contacts addObject:potentialContact];
            } else {
                [self.contactRequests addObject:potentialContact];
            }
        }
        
        self.contacts = [self partitionObjects:self.contacts collationStringSelector:@selector(nickname)];
        
        [self hidePlaceholderImageView:(mappingResult.count > 0)];
        
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
        [self stopAppropriateLoadingSpinner];
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismissWithError:@"Problem getting contact list.\nPlease try again!" afterDelay:kDefaultDismissDelay];
    }];
}

- (NSMutableArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector
{
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];

    NSInteger sectionCount = [[collation sectionTitles] count]; //section count is take from sectionTitles and not sectionIndexTitles
    NSMutableArray *unsortedSections = [NSMutableArray arrayWithCapacity:(NSUInteger)sectionCount];

    // create an array to hold the data for each section
    for(int i = 0; i < sectionCount; i++) {
        [unsortedSections addObject:[NSMutableArray array]];
    }

    // put each object into a section
    for (id object in array) {
        NSInteger index = [collation sectionForObject:object collationStringSelector:selector];
        [[unsortedSections objectAtIndex:(NSUInteger)index] addObject:object];
    }

    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:(NSUInteger)sectionCount];

    //sort each section
    for (NSMutableArray *section in unsortedSections) {
        [sections addObject:[[collation sortedArrayFromArray:section collationStringSelector:selector] mutableCopy]];
    }

    return sections;
}

- (void)hidePlaceholderImageView:(BOOL)hiddenPlaceholder
{
    if (!hiddenPlaceholder && !self.placeholderImageView) {
        self.placeholderImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"contacts-blank-slate"]];
    }
    
    self.tableView.tableFooterView = hiddenPlaceholder
        ? [self tabBarButtonAvoidingFooterView]
        : self.placeholderImageView;
    
    self.tableView.backgroundColor = hiddenPlaceholder
        ? [UIColor colorWithR:51 G:51 B:51 A:1]
        : [UIColor colorWithR:246 G:247 B:245 A:1]  ;
    
    self.tableView.scrollEnabled = hiddenPlaceholder;
    self.searchBar.hidden = !hiddenPlaceholder;
}

- (NSArray*)sectionIndexTitles
{
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.isSearching) {
        return 1;
    }
    
    return [[self sectionIndexTitles] count] + kExtraContactRequestsSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isSearching) {
        return [self.searchResults count];
    }
    
    if (kContactRequestsSection == section) {
        return [self.contactRequests count];
    }
    
    return [[self.contacts objectAtIndex:(NSUInteger)section - kExtraContactRequestsSections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)aSection
{
    if (!self.isSearching) {
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
    if (self.isSearching || self.sortedContactList.count == 0) {
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
    if (!self.isSearching && kContactRequestsSection == indexPath.section) {
        CellIdentifier = kContactRequestsCellIdentifier;
    }
    
    ContactListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[ContactListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    CPUser *contact = [self contactForIndexPath:indexPath];

    cell.nicknameLabel.text = [contact.nickname gtm_stringByUnescapingFromHTML];
    [CPUIHelper changeFontForLabel:cell.nicknameLabel toLeagueGothicOfSize:18.0];

    cell.statusLabel.text = @"";
    
    if (contact.lastCheckIn.statusText.length > 0 && contact.lastCheckIn.isCurrentlyCheckedIn) {
        cell.statusLabel.text = [NSString stringWithFormat:@"\"%@\"", contact.lastCheckIn.statusText];
    }

    [cell.profilePicture setImageWithURL:contact.photoURL placeholderImage:[CPUIHelper defaultProfileImage]];

    cell.user = contact;

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

    if (self.isSearching) return nil;

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
    if (self.isSearching) {
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
        self.searchResults = [NSArray arrayWithArray:self.sortedContactList];
        self.tableView.tableFooterView = [self tabBarButtonAvoidingFooterView];
    }
    else {
        self.searchResults = [self.sortedContactList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(nickname contains[cd] %@)", searchText]];
        self.tableView.tableFooterView = nil;
    }
    [self.tableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)aSearchBar {
    self.isSearching = YES;
    [aSearchBar setShowsCancelButton:YES animated:YES];
    [self performSearch:aSearchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar {
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.searchBar setText:@""];
    [self.searchBar resignFirstResponder];
    self.isSearching = NO;
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
    
    [CPapi sendAcceptContactRequestFromUserID:@([[contactData objectForKey:@"id"] intValue])
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
    
    [CPapi sendDeclineContactRequestFromUserID:@([[contactData objectForKey:@"id"] intValue])
                                    completion:^(NSDictionary *json, NSError *error) {
                                        [self handleSendAcceptOrDeclineComletionWithJson:json andError:error];
                                    }];
    
    [self updateBadgeValue];
}

#pragma mark - private

- (NSIndexPath *)addToContacts:(NSDictionary *)contactData {
    NSInteger sectionIndex = [[UILocalizedIndexedCollation currentCollation] sectionForObject:contactData
                                                                      collationStringSelector:@selector(nickname)];
    NSMutableArray *sectionContacts = [self.contacts objectAtIndex:sectionIndex];
    NSArray *sortDescriptors = [NSArray arrayWithObject:
                                [[NSSortDescriptor alloc] initWithKey:@"nickname" ascending:YES]];
    
    
    [sectionContacts addObject:contactData];
    [self.sortedContactList addObject:contactData];
    
    [sectionContacts sortUsingDescriptors:sortDescriptors];
    [self.sortedContactList sortUsingDescriptors:sortDescriptors];
    
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
    [CPUserDefaultsHandler setNumberOfContactRequests:self.contactRequests.count];
}

- (CPUser *)contactForIndexPath:(NSIndexPath *)indexPath {
    if (self.isSearching) {
        return [self.searchResults objectAtIndex:(NSUInteger)[indexPath row]];
    }
    
    if (kContactRequestsSection == indexPath.section) {
        return [self.contactRequests objectAtIndex:indexPath.row];
    }
    
    return [[self.contacts objectAtIndex:(NSUInteger)indexPath.section - kExtraContactRequestsSections]
            objectAtIndex:(NSUInteger)indexPath.row];
}

@end
