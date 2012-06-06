//
//  PayUserViewController.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 18.2.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "PayUserViewController.h"

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
    
    [CPUIHelper makeButtonCPButton: payButton withCPButtonColor:CPButtonTurquoise];
    [CPUIHelper makeButtonCPButton: cancelButton withCPButtonColor:CPButtonGrey];
    
    [[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"perforated-skin.png"]]];
    [paymentAmount becomeFirstResponder];
    
    [paymentAmount setDelegate:self];
    [paymentNote setDelegate:self];

    descriptionView.layer.borderColor = [UIColor colorWithRed:159.0/255 green:159.0/255 blue:159.0/255 alpha:1.0].CGColor;
    descriptionView.layer.borderWidth = 1.0f;
    
    
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
    [payeeImage setImageWithURL:self.user.photoURL];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [CPapi getUserProfileWithCompletionBlock:^(NSDictionary *json, NSError *error) {
        NSDictionary *jsonDict = json;

        int user_id = [[jsonDict objectForKey:@"userid"] intValue];
        if (user_id > 0) {
            [SVProgressHUD dismiss];
            float balance = [[jsonDict objectForKey:@"balance"] floatValue];
            [userBalance setText:[NSString stringWithFormat:@"$%.2f", balance]];

            if (balance == 0) {
                [self performSegueWithIdentifier:@"PayToAddFundsUserSegue" sender:self];
            }

        } else {
            [SVProgressHUD dismissWithError:@"You must be logged in to C&P in order to make payments"
                                 afterDelay:kDefaultDimissDelay];
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

    [SVProgressHUD showWithStatus:@"Proccessing transaction"];

    float amount = [[[paymentAmount text] stringByReplacingOccurrencesOfString:@"$"
                                                                    withString:@""]
            floatValue];
    if (amount == 0)
    {
        [paymentAmount becomeFirstResponder];

        [SVProgressHUD dismissWithError:@"Payment amount must be greater then $0."
                             afterDelay:kDefaultDimissDelay];
        return;
    }

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

        if(successNum && [successNum intValue] != 1)
        {
            NSString *error = [NSString stringWithFormat:@"%@", [jsonDict objectForKey:@"message"]];
            [SVProgressHUD dismissWithError:error
                                 afterDelay:kDefaultDimissDelay];

            if ([successNum intValue] == -1) {
                [[self navigationController] performSelector:@selector(popViewControllerAnimated:)
                                                  withObject:self
                                                  afterDelay:kDefaultDimissDelay];
            }
         
        }
        else
        {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            
            NSString *message = [NSString stringWithFormat:@"Paid %@ $%.2f for %@", self.user.nickname, amount, [paymentNote text]];
            [SVProgressHUD dismissWithSuccess:message
                                 afterDelay:kDefaultDimissDelay];

            [[self navigationController] performSelector:@selector(popViewControllerAnimated:)
                                              withObject:self
                                              afterDelay:kDefaultDimissDelay];
            
        }
        
	} failure:^(NSURLRequest *aRequest, NSHTTPURLResponse *response, NSError *error, id JSON) {
		// handle error
#if DEBUG
		NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription] );
#endif
		[SVProgressHUD dismissWithError:[error localizedDescription]
                             afterDelay:kDefaultDimissDelay];
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

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (textField != paymentAmount) {
        return YES;
    }

    double currentValue = [textField.text doubleValue];
    double cents = round(currentValue * 100.0f);
    
    if ([string length]) {
        for (size_t i = 0; i < [string length]; i++) {
            unichar c = [string characterAtIndex:i];
            if (isnumber(c)) {
                cents *= 10;
                cents += c - '0'; 
            }            
        }
    } else {
        // back Space
        cents = floor(cents / 10);
    }
    
    textField.text = [NSString stringWithFormat:@"%.2f", cents / 100.0f];
    return NO;
}
@end
