//
//  BalanceViewController.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 23.2.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "BalanceViewController.h"
#import "SVProgressHUD.h"
#import "CPapi.h"
#import "SignupController.h"

@interface BalanceViewController ()

@end

@implementation BalanceViewController
@synthesize userBalance;

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
    
    [CPapi getUserProfileWithCompletionBlock:^(NSDictionary *json, NSError *error) {
        NSLog(@"%@", json);
        NSDictionary *jsonDict = json;
        
        [SVProgressHUD dismiss];
        int user_id = [[jsonDict objectForKey:@"userid"] intValue];
        if (user_id > 0) {
            float balance = [[jsonDict objectForKey:@"balance"] floatValue];
            [userBalance setText:[NSString stringWithFormat:@"$%.2f", balance]];
        } else {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                                message:@"You must be logged in to C&P in order to see your balance" 
                                                               delegate:self 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        
    }];
}

- (void)viewDidUnload
{
    [self setUserBalance:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
