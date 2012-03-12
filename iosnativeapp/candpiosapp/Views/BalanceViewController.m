//
//  BalanceViewController.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 23.2.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "BalanceViewController.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "CPapi.h"
#import "SignupController.h"
#import "WalletCell.h"
#import "TableCellHelper.h"

#define kRefreshViewHeight 52.0f
#define kPullText @"Pull down to update"
#define kReleaseText @"Release to update"
#define kUpdatingText @"updating ..."

@interface BalanceViewController ()

@end

@implementation BalanceViewController
@synthesize transTableView;
@synthesize userBalance;
@synthesize pullIcon;
@synthesize pullDownLabel;
@synthesize updateTimeLabel;
@synthesize balanceScrollView;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - UIView Methods

- (void)viewWillAppear:(BOOL)animated {
    [[AppDelegate instance] hideCheckInButton];
    
    [[self userBalance] setText: [NSString stringWithFormat:@"$%.2f", [AppDelegate instance].settings.userBalance]];
    
    [self.balanceScrollView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"perforated-skin.png"]]];
    [self loadTransactionData];    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadTransactionData];

    
    // content size for the scroll view
    // allows scrolling to show pull to refresh
    self.balanceScrollView.contentSize = self.balanceScrollView.frame.size;
    
    isFlipped = NO;
    loading = NO;
}

- (void)viewDidUnload
{
    [self setUserBalance:nil];
    [self setPullIcon:nil];
    [self setPullDownLabel:nil];
    [self setUpdateTimeLabel:nil];
    [self setTransTableView:nil];
    [self setBalanceScrollView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView 
{
    if (!loading && !isFlipped && scrollView.contentOffset.y <= -kRefreshViewHeight) {
        [pullDownLabel setText:kReleaseText];
        isFlipped = YES;
        
        [CPUIHelper rotateImage:pullIcon 
                       duration:0.2f
                          curve:UIViewAnimationCurveEaseIn 
                        degrees:180];
    }
    
    if (!loading && isFlipped && scrollView.contentOffset.y > -kRefreshViewHeight) {
        [pullDownLabel setText:kPullText];
        isFlipped = NO;
        [CPUIHelper rotateImage:pullIcon 
                       duration:0.2f 
                          curve:UIViewAnimationCurveEaseIn 
                        degrees:0];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (isFlipped) {
        loading = YES;
        [pullDownLabel setText:kUpdatingText];
        [CPUIHelper rotateImage:pullIcon 
                       duration:0.2f
                          curve:UIViewAnimationCurveEaseIn 
                        degrees:0];
        
        [self loadTransactionData];
    }
}

#pragma mark - Data Source Load Methods
- (void)loadTransactionData
{
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    [CPapi getUserTrasactionDataWithCompletitonBlock:^(NSDictionary *json, NSError *error) {

#if DEBUG
        NSLog(@"%@", json);
#endif
        
        BOOL respError = [[json objectForKey:@"error"] boolValue];
        
        if (!error && !respError) {
            NSDictionary *jsonDict = [json objectForKey:@"payload"];
            
            float balance = [[jsonDict objectForKey:@"balance"] floatValue];
            
            [AppDelegate instance].settings.userBalance = balance;
            [[AppDelegate instance] saveSettings];
            
            [[self userBalance] setText:[NSString stringWithFormat:@"$%.2f", balance]];

            transactions = [jsonDict objectForKey:@"transactions"];
            
            [transTableView reloadData];
            
            NSDate *date = [NSDate date];
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"MM/dd/YYYY"];
            NSString *dateString = [dateFormat stringFromDate:date];
            
            [updateTimeLabel setText:[NSString stringWithFormat:@"last updated %@", dateString]];
        } else {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                                message:[json objectForKey:@"payload"]
                                                               delegate:self 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    
        [pullDownLabel setText:kPullText];
        loading = NO;
        
        [SVProgressHUD dismiss];
    }];
    
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel* headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 40)];
    headerLabel.backgroundColor = RGBA(88, 88, 88, 1);
    headerLabel.textColor = RGBA(235, 235, 235, 1);
    headerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0];
    headerLabel.text = @" Transaction History ";
    
    return headerLabel;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *transaction = [transactions objectAtIndex:[indexPath row]];
    
    static NSString *cellIdentifier = @"TransactionListCustomCell";
    WalletCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[WalletCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                 reuseIdentifier:cellIdentifier];
    }

    [[cell amountLabel] setText:[NSString stringWithFormat:@"$%@", [transaction objectForKey:@"amount"]]];
    
    
    NSString *from_to = @"to";
    
    if ([[transaction objectForKey:@"payer"] intValue] != [[AppDelegate instance].settings.candpUserId intValue]) {
        from_to = @"from";
    }
    
    [[cell nicknameLabel] setText:[NSString stringWithFormat:@"%@ %@",
                                  from_to,
                                  [transaction objectForKey:@"nickname"]]];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *paymentDate = [formatter dateFromString:[transaction objectForKey:@"settlement_time"]];
    NSString *dateString;
    
    NSTimeInterval timeInterval = [paymentDate timeIntervalSinceNow];    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    
    if (timeInterval < -6*24*60*60) {
        [dateFormat setDateFormat:@"MM/dd/YYYY"];
    }
    else {
        [dateFormat setDateFormat:@"EEE"];
    }
    
    dateString = [dateFormat stringFromDate:paymentDate];
    
    [[cell dateLabel] setText:dateString];

    if ([[transaction objectForKey:@"nickname"] isEqualToString:@"Exchange"]) {
        [[cell descriptionLabel] setText:[NSString stringWithFormat:@"$%@ added to balance via %@", [transaction objectForKey:@"amount"], [transaction objectForKey:@"type"]]];           
    } 
    else {
        
        NSString *descr = [transaction objectForKey:@"description"];
        [[cell descriptionLabel] setText:descr];
        CGSize maximumLabelSize = CGSizeMake([[cell descriptionLabel] frame].size.width, 9999);
        
        CGSize expectedLabelSize = [descr sizeWithFont:[[cell descriptionLabel] font] 
                                     constrainedToSize:maximumLabelSize
                                         lineBreakMode:[cell descriptionLabel].lineBreakMode]; 
        
        if (expectedLabelSize.height > [[cell descriptionLabel] frame].size.height) {
#if DEBUG  
            NSLog(@"label size: %f", expectedLabelSize.height);
#endif
            //[[cell stateImage] setHidden:NO];
            [cell setFullHeight:
             [cell frame].size.height + expectedLabelSize.height - [[cell descriptionLabel] frame].size.height];
        }
    }

    
    NSObject *thumbnail = [transaction objectForKey:@"thumbnail"];
    
    if (thumbnail != [NSNull null]) {
        
        [[cell profileImage] setContentMode:UIViewContentModeScaleAspectFill];
        [[cell profileImage] setImageWithURL:[NSURL URLWithString:[transaction objectForKey:@"thumbnail"]] 
                            placeholderImage:[UIImage imageNamed:@"defaultAvatar25"]];
    }
    else {
        [[cell profileImage] setImage:[UIImage imageNamed:@"defaultAvatar25"]];
    }
    
    UIView *myBackView = [[UIView alloc] initWithFrame:cell.frame];
    myBackView.backgroundColor = RGBA(179, 179, 179, 1);
    cell.selectedBackgroundView = myBackView;
    
    [[cell contentView] setBackgroundColor:[UIColor whiteColor]];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [transactions count];
}

- (IBAction)gearPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
