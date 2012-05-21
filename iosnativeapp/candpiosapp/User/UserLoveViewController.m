//
//  UserLoveViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/21/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserLoveViewController.h"
#import "UserProfileViewController.h"

#define LOVE_CHAR_LIMIT 140

@interface UserLoveViewController () <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *charCounterLabel;

@end

@implementation UserLoveViewController
@synthesize delegate = _delegate;
@synthesize charCounterLabel = _charCounterLabel;
@synthesize profilePicture = _profilePicture;
@synthesize descriptionTextView = _descriptionTextView;
@synthesize navigationBar = _navigationBar;
@synthesize user = _user;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

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
    self.descriptionTextView.placeholder = @"Recognize this person for $1";
    self.descriptionTextView.placeholderColor = [UIColor colorWithR:153 G:153 B:153 A:1];
    
    // place the user's profile picture
    [self.profilePicture setImageWithURL:self.user.urlPhoto placeholderImage:[CPUIHelper defaultProfileImage]];
    
    // shadow on user profile picture
    [CPUIHelper addShadowToView:self.profilePicture color:[UIColor blackColor] offset:CGSizeMake(1, 1) radius:1 opacity:0.4];
}

- (void)viewDidUnload
{
    [self setProfilePicture:nil];
    [self setDescriptionTextView:nil];
    [self setNavigationBar:nil];
    [self setCharCounterLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)sendReview {
    // show a progress HUD
    [SVProgressHUD showWithStatus:@"Sending..."];
    // call method in CPapi to send love
    [CPapi sendLoveToUserWithID:self.user.userID loveMessage:self.descriptionTextView.text completion:^(NSDictionary *json, NSError *error){
        // check for a JSON parse error
        if (!error) {
            BOOL respError = [[json objectForKey:@"error"] boolValue];
            
            // check for a error according to api response
            if (respError) {
                
                // dismiss the HUD with the error that came back
                NSString *error = [NSString stringWithFormat:@"%@", [json objectForKey:@"message"]];
                
                [SVProgressHUD dismissWithError:error
                                     afterDelay:kDefaultDimissDelay];
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
                
                // dismiss the modal
                [self dismissViewControllerAnimated:YES completion:^{
                    
                    // show a success HUD
                    [SVProgressHUD showSuccessWithStatus:message
                                           duration:kDefaultDimissDelay];
                }];
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


@end
