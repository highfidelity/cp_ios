//
//  UserLoveViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/21/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserLoveViewController.h"
#import "UserProfileViewController.h"
#import "FlurryAnalytics.h"
#import "CPSkill.h"
#import "LoveSkillTableViewCell.h"

#define LOVE_CHAR_LIMIT 140
#define inAppItem @"com.coffeeandpower.love1"
#define HEADER_SKILL_CELL_HEIGHT 38
#define NORMAL_SKILL_CELL_HEIGHT 35
#define ICON_LEFT_MARGIN 18
#define ICON_WIDTH 13
#define LOADING_SPINNER_TAG 1239


@interface UserLoveViewController () <UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *charCounterLabel;
@property (strong, nonatomic) CPSkill *selectedSkill;
@property (strong, nonatomic) UIView *keyboardBackground;

@end

@implementation UserLoveViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationBar.topItem.title = self.user.nickname;
    
    // show the keyboard on load
    [self.descriptionTextView becomeFirstResponder];
    
    // be the delegate of the text view
    self.descriptionTextView.delegate = self;
    
    // set the placeholder on our CPPlaceHolderTextView
    self.descriptionTextView.placeholder = @"Type your recognition text here...";
    self.descriptionTextView.placeholderColor = [UIColor colorWithR:153 G:153 B:153 A:1];
    
    // place the user's profile picture
    [self.profilePicture setImageWithURL:self.user.photoURL
                        placeholderImage:[CPUIHelper defaultProfileImage]];
    
    // shadow on user profile picture
    [CPUIHelper addShadowToView:self.profilePicture color:[UIColor blackColor] offset:CGSizeMake(1, 1) radius:1 opacity:0.4];
    
    // reload the tableView 
    // it'll show loading 
    [self.tableView reloadData];
    
    // Add notifications for keyboard showing / hiding
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // add a view so we can have a background behind the keyboard
    self.keyboardBackground = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 0)];
    self.keyboardBackground.backgroundColor = [UIColor blackColor];
    
    // add the keyboardBackground to the view
    [self.view addSubview:self.keyboardBackground];
    
    // grab the user's skills
    [CPapi getSkillsForUser:[NSNumber numberWithInt:self.user.userID] completion:^(NSDictionary *json, NSError *error) {
        if (!error) {
            if (![[json objectForKey:@"error"] boolValue]) {
                
                // create an array to hold the skills
                NSMutableArray *userSkills = [NSMutableArray array];
                
                // create the general skill
                CPSkill *generalSkill = [[CPSkill alloc] init];
                generalSkill.name = @"General";
                generalSkill.skillID = 0;
                
                // at first our selected skill will be the general skill
                self.selectedSkill = generalSkill;
                
                // add the generic skill to the array of skills
                [userSkills addObject:generalSkill];
                
                for (NSDictionary *skillDict in [json objectForKey:@"payload"]) {
                    // add this skill to the array of user skills
                    [userSkills addObject:[[CPSkill alloc] initFromDictionary:skillDict]];
                }
                
                // give those skills to the user
                self.user.skills = userSkills;
                
                // reload the tableView with the new data
                [self.tableView reloadData];
                
                if (userSkills.count > 1) {
                    // animate the tableView up so the skill-choosing header appears above the keyboard
                    [UIView beginAnimations:@"shift-up-skills" context:nil];
                    self.loveBackground.frame = CGRectMake(self.loveBackground.frame.origin.x, 
                                                           self.loveBackground.frame.origin.y, 
                                                           self.loveBackground.frame.size.width, 
                                                           self.loveBackground.frame.size.height - HEADER_SKILL_CELL_HEIGHT);
                    self.tableView.frame = CGRectInset(self.tableView.frame, 0, -HEADER_SKILL_CELL_HEIGHT);
                    [UIView commitAnimations];
                }
            } else {
                // error returned from backend
                // show that to the user
                [SVProgressHUD showErrorWithStatus:[error localizedDescription] duration:kDefaultDismissDelay];
            }
        } else {
            // json parse error
            // show the ugly error to the user, might help us debug
            [SVProgressHUD showErrorWithStatus:[error localizedDescription] duration:kDefaultDismissDelay];
        }
    }];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    
    // stop observing keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)sendReview {
    
    // show a progress HUD
    [SVProgressHUD showWithStatus:@"Sending..."];
    // call method in CPapi to send love
    [CPapi sendLoveToUserWithID:self.user.userID loveMessage:self.descriptionTextView.text skillID:self.selectedSkill.skillID completion:^(NSDictionary *json, NSError *error){
        // check for a JSON parse error
        if (!error) {
            BOOL respError = [[json objectForKey:@"error"] boolValue];
            
            // check for a error according to api response
            if (respError) {
                
                // dismiss the HUD with the error that came back
                NSString *error = [NSString stringWithFormat:@"%@", [json objectForKey:@"message"]];
                
                [SVProgressHUD dismissWithError:error
                                     afterDelay:kDefaultDismissDelay];
            }
            else {
                // dismiss the HUD with the success message that came back
                NSString *message = [NSString stringWithFormat:@"You Recognized %@", self.user.nickname];

                // kill the progress HUD
                [SVProgressHUD dismiss];

                // if we have a delegate that is user profile VC
                // tell our delegate to reload data for the new review
                if ([self.delegate isKindOfClass:[UserProfileViewController class]]) {
                    [self.delegate placeUserDataOnProfile];
                }

                BOOL isContact = [[[json objectForKey:@"payload"] objectForKey:@"is_contact"] boolValue];
                if (!isContact) {
                    NSString *alertMessage = [NSString stringWithFormat:@"Would you also like to exchange contact information with  %@?", self.user.nickname];
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:message
                                                                        message:alertMessage
                                                                       delegate:self
                                                              cancelButtonTitle:@"No"
                                                              otherButtonTitles:@"Yes", nil];
                    [alertView show];
                } else {
                    // dismiss the modal
                    [self dismissViewControllerAnimated:YES completion:^{

                        // show a success HUD
                        [SVProgressHUD showSuccessWithStatus:message
                                                    duration:kDefaultDismissDelay];
                    }];
                }
            }
            
        } else {
            // debug the JSON parse error
#if DEBUG
            NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription]);
#endif
        }
    }];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (range.length == 1 && [text isEqualToString:@""]) {
        return YES;
    } else if ([text isEqualToString:@"\n"]) {
        // if there's any review text here then send it
        if (textView.text.length > 0) {
            [self sendReview];
        }
        return NO;
    } else if (textView.text.length > (LOVE_CHAR_LIMIT - 1)) {
        return NO;
    }
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView
{
    self.charCounterLabel.text = [NSString stringWithFormat:@"%d", LOVE_CHAR_LIMIT - textView.text.length];
}

#pragma mark - IBActions

-(IBAction)cancelButtonPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)changeSkillButtonPressed:(id)sender
{
    // hide the keyboard if it's around or show it if it's hidden
    if ([self.descriptionTextView isFirstResponder]) {
        [self.descriptionTextView resignFirstResponder];
    } else {
        [self.descriptionTextView becomeFirstResponder];
    }
    
}

- (void)dismissHUD:(id)sender
{
    [SVProgressHUD dismiss];
}

# pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // alloc-init our table header
    UIView *tableHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, HEADER_SKILL_CELL_HEIGHT)];
    
    // set the background color
    tableHeader.backgroundColor = [UIColor colorWithR:51 G:51 B:51 A:1];
    
    // setup a button for the left side of the header
    UIButton *changeSkillButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, tableHeader.frame.size.width, tableHeader.frame.size.height)];
    
    // add the target for the button as changeSkillButtonPressed
    [changeSkillButton addTarget:self action:@selector(changeSkillButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    // add the button to the table header
    [tableHeader addSubview:changeSkillButton];
    
    UIImageView *leftIcon = [self imageViewForIcon:YES];
    
    // add the left icon to the button
    [changeSkillButton addSubview:leftIcon];
    
    // use the helper method to get the label for the header
    UILabel *headerLabel = [self labelForHeaderOrCell:YES];
    
    headerLabel.text = [NSString stringWithFormat:@"Skill: %@", self.selectedSkill ? self.selectedSkill.name : @"General"];
    
    // add the label to the button
    [changeSkillButton addSubview:headerLabel];
    
    // add a line to the bottom of the view since the header doesn't get a seperator
    UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(0, tableHeader.frame.size.height - 1, tableHeader.frame.size.width, 1)];
    sepLine.backgroundColor = [UIColor colorWithR:58 G:58 B:58 A:1];
    
    // add the seperator line to the tableHeader
    [tableHeader addSubview:sepLine];
    
    return tableHeader;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section 
{
    return HEADER_SKILL_CELL_HEIGHT;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NORMAL_SKILL_CELL_HEIGHT;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.user.skills ? self.user.skills.count : 6;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SkillCellIdentifier = @"SendLoveSkillCell";
    LoveSkillTableViewCell *cell = [[LoveSkillTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SkillCellIdentifier];
    
    CPSkill *cellSkill;
    if (self.user.skills && indexPath.row < self.user.skills.count) {
        // grab this skill out of the array 
        cellSkill = [self.user.skills objectAtIndex:indexPath.row];
    } 
    
    if (cellSkill) {
        // remove the loading spinner if it's here from reuse
        [[cell viewWithTag:LOADING_SPINNER_TAG] removeFromSuperview];
        
        // alloc-init the image view to hold the left icon
        UIImageView *leftIconImageView = [self imageViewForIcon:NO];
        leftIconImageView.tag = ICON_IMAGE_VIEW_TAG;
        
        // add the leftIconImageView to the cell
        [cell addSubview:leftIconImageView];
    } else {
        
        // remove the left icon image view if it's here from reuse
        [[cell viewWithTag:ICON_IMAGE_VIEW_TAG] removeFromSuperview];
        
        // alloc-init a loading spinner for this cell while we have no skill
        UIActivityIndicatorView *loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        loadingSpinner.tag = LOADING_SPINNER_TAG;
        
        // position the loadingSpinner
        CGRect spinnerMove = loadingSpinner.frame;
        spinnerMove.origin.x = 11;
        spinnerMove.origin.y = 10;
        loadingSpinner.frame = spinnerMove;
        
        // start the spinner
        [loadingSpinner startAnimating];
        
        // add the loading spinner to the cell
        [cell addSubview:loadingSpinner];
    }
    
    // use the helper method to create a UILabel
    UILabel *skillLabel = [self labelForHeaderOrCell:NO];
    
    // set the text for the skill label, prepend text for the header if required
    skillLabel.text = cellSkill ? cellSkill.name : @"Loading...";
    
    // add the skillLabel to the cell
    [cell addSubview:skillLabel];
    
    // if this is the selected skill then force it to be active
    cell.forceActive = (cellSkill && cellSkill == self.selectedSkill);
    
    // use the cell's setActive method to set the right state for this cell
    [cell setActive:NO];
    
    // return the cell
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // make sure the keyboard is showing
    [self.descriptionTextView becomeFirstResponder];
    
    // only attempt to select a skill if we actually have skills
    if (self.user.skills) {
        CPSkill *selectedSkill = [self.user.skills objectAtIndex:indexPath.row];
        
        // set our selectedSkillID to this ID
        self.selectedSkill = selectedSkill;
        
        // tell the table to reload 
        // this fixes the text on the header and highlights our cell
        [self.tableView reloadData];
    }
}

# pragma mark - Helpers for tableView
- (UIImageView *)imageViewForIcon:(BOOL)header
{
    NSString *imageName = header ? @"expand-arrow-down" : @"bullet";
    // alloc-init an imageView for the left icon
    UIImageView *leftIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    
    // vertically center the left icon 18 pts in from the left of the cell
    CGRect iconIVFrame = leftIconImageView.frame;
    iconIVFrame.origin.x = ICON_LEFT_MARGIN;
    iconIVFrame.origin.y = ((header ? HEADER_SKILL_CELL_HEIGHT : NORMAL_SKILL_CELL_HEIGHT) / 2) - (iconIVFrame.size.height / 2);
    leftIconImageView.frame = iconIVFrame;
    
    return leftIconImageView;
}

-(UILabel *)labelForHeaderOrCell:(BOOL)header
{
    // create the frame for the label, making changes where required if this is the header cell
    CGRect labelFrame = CGRectZero;
    labelFrame.origin.x = ICON_WIDTH + ICON_LEFT_MARGIN + 10;
    labelFrame.origin.y = 0;
    labelFrame.size.width = [UIScreen mainScreen].bounds.size.width - labelFrame.origin.x - 15 - (header ? 99 : 0);
    labelFrame.size.height = header ? HEADER_SKILL_CELL_HEIGHT : NORMAL_SKILL_CELL_HEIGHT;
    
    // alloc-init the skillLabel and give it the right tag
    UILabel *skillLabel = [[UILabel alloc] initWithFrame:labelFrame];
    
    // set some properties for the text
    skillLabel.textColor = [UIColor colorWithR:229 G:227 B:217 A:1];
    skillLabel.backgroundColor = [UIColor clearColor];
    skillLabel.font = [UIFont systemFontOfSize:13];
    skillLabel.shadowColor = [UIColor blackColor];
    skillLabel.shadowOffset = CGSizeMake(0, -1);
    
    return skillLabel;
}

# pragma mark - Methods for keyboard hide/show notification

- (void)keyboardWillShow:(NSNotification*)notification
{
    CGRect keyboardEndFrame;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    double scrollSpeed = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGRect backgroundRect = self.keyboardBackground.frame;
    backgroundRect.size.height = keyboardEndFrame.size.height;
    backgroundRect.origin.y = self.view.frame.size.height - backgroundRect.size.height;
    
    [UIView animateWithDuration:scrollSpeed
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.keyboardBackground.frame = backgroundRect;
                     }
                     completion:nil];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    CGRect backgroundRect = self.keyboardBackground.frame;
    backgroundRect.origin.y = self.view.frame.size.height;
    backgroundRect.size.height = 0;
    
    // Return the chatContents and the inputs to their original position
    [UIView animateWithDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.keyboardBackground.frame = backgroundRect;
                     }
                     completion:nil];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 if (buttonIndex == alertView.firstOtherButtonIndex) {
                                     [CPapi sendContactRequestToUserId:self.user.userID];
                                 }
                             }];
}

@end
