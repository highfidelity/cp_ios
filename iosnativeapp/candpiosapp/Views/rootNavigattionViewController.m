//
//  rootNavigattionViewController.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 25.3.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "RootNavigattionViewController.h"
#import "SVProgressHUD.h"
#import "CPapi.h"

@interface RootNavigattionViewController ()

@end

@implementation RootNavigattionViewController

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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Alert View Delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 904 && buttonIndex == 1) {
        [SVProgressHUD show];

        [CPapi checkOutWithCompletion:^(NSDictionary *json, NSError *error) {
            
            BOOL respError = [[json objectForKey:@"error"] boolValue];
            
            [SVProgressHUD dismiss];
            if (!error && !respError) {
                [[UIApplication sharedApplication] cancelAllLocalNotifications];
                NSInteger checkOutTime = (NSInteger) [[NSDate date] timeIntervalSince1970];
                SET_DEFAULTS(Object, kUDCheckoutTime, [NSNumber numberWithInt:checkOutTime]);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"userCheckedIn" object:nil];
            } else {
                
                
                NSString *message = [json objectForKey:@"payload"];
                if (!message) {
                    message = @"Oops. Something went wrong.";    
                }
                
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"An error occurred"
                                      message:message
                                      delegate:self
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles: nil];
                [alert show];
            }
            [[AppDelegate instance] refreshCheckInButton];
        }];
    }
}
@end
