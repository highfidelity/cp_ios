//
//  GenerateInvitationCodeViewController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 4/5/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "GenerateInvitationCodeViewController.h"

@interface GenerateInvitationCodeViewController ()

@property (nonatomic, weak) IBOutlet UILabel *codeLabel;
@property (nonatomic, weak) IBOutlet UIButton *doneButton;

- (IBAction)donePressed:(id)sender;

#pragma mark -
#pragma mark private

- (void)showCode:(NSString *)code;
- (void)resizeCodeLabel;
- (void)loadCode;

@end

#pragma mark -

@implementation GenerateInvitationCodeViewController

@synthesize codeLabel = _codeLabel;
@synthesize doneButton = _doneButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.codeLabel.layer.cornerRadius = 7;
    
    [CPUIHelper makeButtonCPButton:self.doneButton withCPButtonColor:CPButtonGrey];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    [self loadCode];
}

#pragma mark -
#pragma mark actions

- (IBAction)donePressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark private

- (void)showCode:(NSString *)code {
    self.codeLabel.text = code;
    [self resizeCodeLabel];
    
    self.codeLabel.alpha = 0;
    self.codeLabel.hidden = NO;
    
    [UIView beginAnimations:nil context:nil];
    
    self.codeLabel.alpha = 1;
    
    [UIView commitAnimations];
}

- (void)resizeCodeLabel {
    [self.codeLabel sizeToFit];
    
    CGRect codeLabelFrame = CGRectInset(self.codeLabel.frame, -10, -3);
    codeLabelFrame.origin.x = round((self.view.frame.size.width - codeLabelFrame.size.width) / 2);
    
    self.codeLabel.frame = codeLabelFrame;
}

- (void)loadCode {
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    CLLocation *location = [AppDelegate instance].settings.lastKnownLocation;
    
    [CPapi getInvitationCodeForLocation:location
                   withCompletionsBlock:^(NSDictionary *json, NSError *error) {
        BOOL respError = [[json objectForKey:@"error"] boolValue];
        
        if (!error && !respError) {
            NSDictionary *jsonDict = [json objectForKey:@"payload"];
            [self showCode:[jsonDict objectForKey:@"code"]];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                                message:[json objectForKey:@"payload"]
                                                               delegate:self 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        
        [SVProgressHUD dismiss];
    }];
}

@end
