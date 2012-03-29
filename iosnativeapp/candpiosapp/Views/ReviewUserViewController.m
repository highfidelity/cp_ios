//
//  ReviewUserViewController.m
//  candpiosapp
//
//  Created by liffeeyum on 29/03/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ReviewUserViewController.h"
#import "AFNetworking.h"
#import "SVProgressHud.h"
#import "CPapi.h"

@interface ReviewUserViewController ()
@end

@implementation ReviewUserViewController
@synthesize user = _user;
BOOL hasBalance = NO;

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
    [SVProgressHUD showWithStatus:@"Loading..."];
    [receiverNickname setText: self.user.nickname];
	[receiverImage setImageWithURL: self.user.urlPhoto];
}

- (void)viewWillAppear:(BOOL)animated {
    [CPUIHelper makeButtonCPButton:sendButton withCPButtonColor:CPButtonTurquoise];
    [CPUIHelper makeButtonCPButton:cancelButton withCPButtonColor:CPButtonGrey];
    
    [[AppDelegate instance] hideCheckInButton];
    
    [[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"perforated-skin.png"]]];
    [description becomeFirstResponder];
    
    [description setDelegate:self];
    
    descriptionView.layer.borderColor = [UIColor colorWithRed:159.0/255 green:159.0/255 blue: 159.0/255 alpha:1.0].CGColor;
    descriptionView.layer.borderWidth = 1.0f;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [CPapi getUserProfileWithCompletionBlock:^(NSDictionary *json, NSError *error) {
        NSDictionary *jsonDict = json;
        
        [SVProgressHUD dismiss];
        int user_id = [[jsonDict objectForKey:@"userid"] intValue];
        if (user_id > 0) {
            float balance = [[jsonDict objectForKey:@"balance"] floatValue];
            if (balance > 0) {
                hasBalance = YES;
            }
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"You must be logged in to C&P in order to make payments"
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        
    }];
}

- (void)viewDidUnload
{
    description = nil;
    receiverImage = nil;
    descriptionView = nil;
    cancelButton = nil;
    sendButton = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag && alertView.tag == 5 && buttonIndex == 1) {
        UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"SettingsStoryboard_iPhone" bundle:nil];
        
        UIViewController *AddFundsViewController = (UIViewController *)[secondStoryBoard instantiateViewControllerWithIdentifier:@"AddFundsViewController"];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:AddFundsViewController];
        [self.navigationController presentModalViewController:navController animated:YES];
    }
    
    if (alertView.tag && alertView.tag == 4) {
        [[self navigationController] popViewControllerAnimated: YES];        
    }
}

- (IBAction)sendReview:(id)sender {
    
    if (! hasBalance) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"You must pay $1 to send love."
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Add Funds", nil];
        alertView.tag = 5;
        [alertView show];
        return;
    }
    
    [SVProgressHUD showWithStatus:@"Sending love"];
    AFHTTPClient *httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kCandPWebServiceUrl]];
    NSString *respUserId = [NSString stringWithFormat:@"%d", self.user.userID];
	NSMutableDictionary *reviewParams = [NSMutableDictionary dictionary];
    [reviewParams setObject:@"makeMobileReview" forKey:@"action"];
    [reviewParams setObject:respUserId forKey:@"recipientID"];
    [reviewParams setObject:description.text forKey:@"reviewText"];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST"
                                                            path:@"reviews.php"
                                                      parameters:reviewParams];
    AFJSONRequestOperation *postOperation = [AFJSONRequestOperation                                         JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
        
        NSDictionary *jsonDict = json;
        NSNumber *successNum = [jsonDict objectForKey:@"succeeded"];
        [SVProgressHUD dismiss];
        
        if (successNum && [successNum intValue] != 1) {
            NSString *error = [NSString stringWithFormat:@"%@", [jsonDict objectForKey:@"message"]];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:error
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            
            if ([successNum intValue] == -1) {
                // not logged in - set tag in order for view to be closed
                alertView.tag = 4;
            }
            [alertView show];
        }
        else {


            NSString *message = [NSString stringWithFormat:@"Made review of %@", self.user.nickname];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Transaction"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            alertView.tag = 4;
            [alertView show];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        // handle error
#if DEBUG
        NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription]);
#endif
        [SVProgressHUD dismissWithError:[error localizedDescription]];
    
    }];
    [[NSOperationQueue mainQueue] addOperation:postOperation];
}

- (IBAction)descriptionChanged:(id)sender
{
    int chars = 64 - [[description text] length];
    if (chars < 0)
    {
        chars = 0;
        [description setText: [[description text] substringToIndex:64]];
    }
    [charsLeft setText: [NSString stringWithFormat:@"%d", chars]];
}

- (IBAction)closeView:(UIButton *)sender
{
    [[self navigationController] popViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == description) {
        [textField resignFirstResponder];
    }
    return YES;
}


@end
