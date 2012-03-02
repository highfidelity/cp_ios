//
//  PayUserViewController.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 18.2.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "PayUserViewController.h"
#import "AppDelegate.h"
#import "AFNetworking.h"
#import "SVProgressHUD.h"
#import "CPapi.h"
#import <QuartzCore/QuartzCore.h>

@implementation PayUserViewController
@synthesize user = _user;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [[AppDelegate instance] hideCheckInButton];
    
    [[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"perforated-skin.png"]]];
    [paymentAmount becomeFirstResponder];
    [paymentNote setDelegate: self];

    descriptionView.layer.borderColor = [UIColor colorWithRed:159.0/255 green:159.0/255 blue:159.0/255 alpha:1.0].CGColor;
    descriptionView.layer.borderWidth = 1.0f;
    
    UIColor *borderColor = [[UIColor alloc] initWithRed:122.0/255 green:132.0/255  blue:142.0/255 alpha:1];

    [[payButton layer] setBorderColor:[borderColor CGColor]];
    [[payButton layer] setBorderWidth:1.0f];
    [[payButton layer] setCornerRadius:6];
    
    [[cancelButton layer] setBorderColor:[borderColor CGColor]];
    [[cancelButton layer] setBorderWidth:1.0f];
    [[cancelButton layer] setCornerRadius:6];
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [SVProgressHUD showWithStatus:@"Loading..."];


    [payTo setText: self.user.nickname];
    [payeeImage setImageWithURL: self.user.urlPhoto];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [CPapi getUserProfileWithCompletionBlock:^(NSDictionary *json, NSError *error) {
        NSDictionary *jsonDict = json;

        [SVProgressHUD dismiss];
        int user_id = [[jsonDict objectForKey:@"userid"] intValue];
        if (user_id > 0) {
            float balance = [[jsonDict objectForKey:@"balance"] floatValue];
            [userBalance setText:[NSString stringWithFormat:@"$%.2f", balance]];

            if (balance == 0) {
                [self performSegueWithIdentifier:@"PayToAddFundsUserSegue" sender:self];
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
    paymentAmount = nil;
    paymentNote = nil;
    charsLeft = nil;
    payTo = nil;
    payeeImage = nil;
    userBalance = nil;
    paymentNote = nil;
    paymentNote = nil;
    descriptionView = nil;
    cancelButton = nil;
    payButton = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)makePayment:(id)sender {

    float amount = [[[paymentAmount text] stringByReplacingOccurrencesOfString:@"$"
                                                                    withString:@""]
            floatValue];
    if (amount == 0)
    {
        [paymentAmount becomeFirstResponder];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Invalid payment amount"
                                                            message:@"Payment amount must be greater then $0."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }

    [SVProgressHUD showWithStatus:@"Proccessing transaction"];
    AFHTTPClient *httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kCandPWebServiceUrl]];

    NSString *respUserId = [NSString stringWithFormat:@"%d", self.user.userID];

	NSMutableDictionary *paymentParams = [NSMutableDictionary dictionary];
	[paymentParams setObject:@"makeMobilePayment" forKey:@"action"];
	[paymentParams setObject:respUserId forKey:@"recipientID"];
	[paymentParams setObject:[NSString stringWithFormat:@"%.2f", amount] forKey:@"transactionAmount"];
	[paymentParams setObject:[paymentNote text] forKey:@"transactionDesc"];

	NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST"
                                                            path:@"payments.php"
                                                      parameters:paymentParams];

    AFJSONRequestOperation *postOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {

        
        NSDictionary *jsonDict = json;
        NSNumber *successNum = [jsonDict objectForKey:@"succeeded"];
        
        
		[SVProgressHUD dismiss];
        
        if(successNum && [successNum intValue] != 1)
        {
            NSString *error = [NSString stringWithFormat:@"%@", [jsonDict objectForKey:@"message"]];

            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Transaction error"
                                                                message:error
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            
            if ([successNum intValue] == -1) {
                //not logged in
                [self dismissModalViewControllerAnimated:YES];
            }
         
        }
        else
        {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            
            NSString *message = [NSString stringWithFormat:@"Paid %@ $%.2f for %@", self.user.nickname, amount, [paymentNote text]];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Transaction"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            
        }
        
	} failure:^(NSURLRequest *aRequest, NSHTTPURLResponse *response, NSError *error, id JSON) {
		// handle error
#if DEBUG
		NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription] );
#endif
		[SVProgressHUD dismissWithError:[error localizedDescription]];
	}];

    [[NSOperationQueue mainQueue] addOperation:postOperation];
}

- (IBAction)descriptionChanged:(id)sender 
{
    int chars = 64 - [[paymentNote text] length];
    if (chars < 0) 
    {
        chars = 0;
        [paymentNote setText: [[paymentNote text] substringToIndex:64]];
    }
    [charsLeft setText: [NSString stringWithFormat:@"%d", chars]];
}

- (IBAction)formatAmount:(id)sender 
{
    [paymentAmount setText:[NSString stringWithFormat:@"$%.2f", [[paymentAmount text] floatValue]]];
}

- (IBAction)closeView:(UIButton *)sender
{
    [[self navigationController] popViewControllerAnimated: YES];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
 if (textField == paymentNote) {
     [textField resignFirstResponder];
 }
 return YES;
}

@end
