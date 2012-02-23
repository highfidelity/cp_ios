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
    [paymentAmount becomeFirstResponder];
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
    [payTo setText: self.user.nickname];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    paymentAmount = nil;
    paymentNote = nil;
    responseText = nil;
    charsLeft = nil;
    payTo = nil;
    messageView = nil;
    paymentView = nil; 
    
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
            
            [responseText setText:[NSString stringWithFormat:@"Paid %@ $%.2f for %@", self.user.nickname, amount, [paymentNote text]]];
                                   
            [paymentView setHidden:YES];
            [messageView setHidden:NO];
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

- (IBAction)closeModal:(id)sender 
{
    [self dismissModalViewControllerAnimated:YES];
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


@end
