	//
//  NotificationsTableViewController.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 12/22/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "NotificationsTableViewController.h"
#import "ActionSheetDatePicker.h"
#import "PushModalViewControllerFromLeftSegue.h"
#import "CPCheckedLabel.h"
#import "CPSwitch.h"

@interface NotificationsTableViewController () <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet CPCheckedLabel *checkedInCityLabel;
@property (weak, nonatomic) IBOutlet CPCheckedLabel *checkedInVenueLabel;
@property (weak, nonatomic) IBOutlet CPCheckedLabel *checkedInContactsLabel;
@property (weak, nonatomic) IBOutlet UIButton *quietTimeFromButton;
@property (weak, nonatomic) IBOutlet UIButton *quietTimeToButton;

@property (weak, nonatomic) IBOutlet CPSwitch *notificationsSwitch;
@property (weak, nonatomic) IBOutlet CPSwitch *quietTimeSwitch;
@property (weak, nonatomic) IBOutlet CPSwitch *notifyOnEndorsementSwitch;
@property (weak, nonatomic) IBOutlet CPSwitch *notifyHeadlineChangesSwitch;
@property (weak, nonatomic) IBOutlet CPSwitch *contactsOnlyChatSwitch;
@property (weak, nonatomic) IBOutlet CPSwitch *checkedInOnlySwitch;

@property (weak, nonatomic) IBOutlet UILabel *chatNotificationLabel;

@property (strong, nonatomic) NSDate *quietTimeFromDate;
@property (strong, nonatomic) NSDate *quietTimeToDate;

@property (weak, nonatomic) IBOutlet UITableViewCell *timeFrameCell;
@end

@implementation NotificationsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [CPCheckedLabel createRadioButtonGroup:@[
        self.checkedInContactsLabel,
        self.checkedInCityLabel,
        self.checkedInVenueLabel
     ]];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadNotificationSettings];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [self saveNotificationSettings];
    [super viewDidDisappear:animated];
}


#pragma mark - Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    }
    
    NSArray *sectionHeaders = @[
        @"",
        @"Show check ins from people that are ...",
        @"Notifications from my contacts",
        @"Chat availability"
    ];
    
    UIView *tempView=[[UIView alloc]initWithFrame:CGRectMake(0, 200, 300, 244)];
    tempView.backgroundColor=[UIColor clearColor];
    
    UILabel *tempLabel=[[UILabel alloc]initWithFrame:CGRectMake(37, 0, 300, 44)];
    tempLabel.backgroundColor=[UIColor clearColor];
    tempLabel.textColor = [UIColor lightGrayColor];
    tempLabel.font = [UIFont boldSystemFontOfSize:14];
    tempLabel.text = [sectionHeaders objectAtIndex:(NSUInteger) section];
    
    [tempView addSubview:tempLabel];
    return tempView;
}


#pragma mark - Api calls
- (void)loadNotificationSettings
{
    [SVProgressHUD show];
    [CPapi getNotificationSettingsWithCompletition:^(NSDictionary *json, NSError *err) {
        BOOL error = [[json objectForKey:@"error"] boolValue];
        if (error) {
            [self dismissModalViewControllerAnimated:YES];
            NSString *message = @"There was a problem getting your data!\nPlease logout and login again.";
            [SVProgressHUD dismissWithError:message
                                 afterDelay:kDefaultDismissDelay];
        } else {
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"HH:mm:ss"];
            [dateFormat setTimeZone:[NSTimeZone localTimeZone]];
            
            NSDictionary *dict = [json objectForKey:@"payload"];
            
            NSString *receiveNotifications = [dict objectForKey:@"receive_push_notifications"];
            [[self notificationsSwitch] setOn:[receiveNotifications isEqualToString:@"1"]];
            [self notificationSwitchChanged:self.notificationsSwitch];
            
            NSString *push_distance = [dict objectForKey:@"push_distance"];
            if ([push_distance isEqualToString:@"venue"]) {
                self.checkedInVenueLabel.checked = YES;
            } else if ([push_distance isEqualToString:@"city"]) {
                self.checkedInCityLabel.checked = YES;
            } else {
                self.checkedInContactsLabel.checked = YES;
            }
            
            NSString *checkInOnly = [dict objectForKey:@"checked_in_only"];
            [[self checkedInOnlySwitch] setOn:[checkInOnly isEqualToString:@"1"]];
            
            NSString *notifyOnEndorsement = [dict objectForKey:@"push_contacts_endorsement"];
            [[self notifyOnEndorsementSwitch] setOn:[notifyOnEndorsement isEqualToString:@"1"]];
            
            NSString *notifyHealdineChanges = [dict objectForKey:@"push_headline_changes"];
            [[self notifyHeadlineChangesSwitch] setOn:[notifyHealdineChanges isEqualToString:@"1"]];
            
            NSString *quietTime = [dict objectForKey:@"quiet_time"];
            [[self quietTimeSwitch] setOn:[quietTime isEqualToString:@"1"]];
            
            NSString *quietTimeFrom = [dict objectForKey:@"quiet_time_from"];
            if ([quietTimeFrom isKindOfClass:[NSNull class]]) {
                quietTimeFrom = @"20:00:00";
            }
            
            @try {
                self.quietTimeFromDate = [dateFormat dateFromString:quietTimeFrom];
            }
            @catch (NSException* ex) {
                self.quietTimeFromDate = [dateFormat dateFromString:@"7:00"];
            }
            
            [[self quietTimeFromButton] setTitle:[self setTimeText:self.quietTimeFromDate]
                          forState:UIControlStateNormal];
            
            
            NSString *quietTimeTo = [dict objectForKey:@"quiet_time_to"];
            if ([quietTimeTo isKindOfClass:[NSNull class]]) {
                quietTimeTo = @"07:00:00";
            }
            
            @try {
                self.quietTimeToDate = [dateFormat dateFromString:quietTimeTo];
            }
            @catch (NSException* ex) {
                self.quietTimeToDate = [dateFormat dateFromString:@"19:00"];
            }
            
            [[self quietTimeToButton] setTitle:[self setTimeText:self.quietTimeToDate]
                                      forState:UIControlStateNormal];
            
            NSString *contactsOnlyChat = [dict objectForKey:@"contacts_only_chat"];
            [[self contactsOnlyChatSwitch] setOn:[contactsOnlyChat isEqualToString:@"0"]];
            
            [SVProgressHUD dismiss];
        }
    }];
}

- (void)saveNotificationSettings
{
    NSString *distance = @"city";
    
    if (self.checkedInVenueLabel.checked) {
        distance = @"venue";
    } else if (self.checkedInContactsLabel.checked) {
        distance = @"contacts";
    }

    [CPapi setNotificationSettingsForDistance:distance
                         receiveNotifications:self.notificationsSwitch.on
                                 andCheckedId:self.checkedInOnlySwitch.on
                       receiveContactEndorsed:self.notifyOnEndorsementSwitch.on
                        contactHeadlineChange:self.notifyHeadlineChangesSwitch.on
                                    quietTime:self.quietTimeSwitch.on
                                quietTimeFrom:self.quietTimeFromDate
                                  quietTimeTo:self.quietTimeToDate
                      timezoneOffsetInSeconds:[[NSTimeZone defaultTimeZone] secondsFromGMT]
                         chatFromContactsOnly:!self.contactsOnlyChatSwitch.on];
}



- (IBAction)quietFromClicked:(UIButton *)sender
{
    [ActionSheetDatePicker showPickerWithTitle:@"Select Quiet Time From"
                                datePickerMode:UIDatePickerModeTime
                                  selectedDate:[self quietTimeFromDate]
                                        target:self
                                        action:@selector(timeWasSelected:element:)
                                        origin:sender];
}

- (IBAction)quietToClicked:(UIButton *)sender
{
    [ActionSheetDatePicker showPickerWithTitle:@"Select Quiet Time To"
                                datePickerMode:UIDatePickerModeTime
                                  selectedDate:[self quietTimeToDate]
                                        target:self
                                        action:@selector(timeWasSelected:element:)
                                        origin:sender];
}


- (void)timeWasSelected:(NSDate *)selectedTime element:(id)element
{
    UIButton *button = (UIButton *)element;
    [button setTitle:[self setTimeText:selectedTime] forState:UIControlStateNormal];
    if (button.tag == 1) {
        self.quietTimeFromDate = selectedTime;
    } else {
        self.quietTimeToDate = selectedTime;
    }
}

-(void)setChatLabelText:(BOOL)publicChat
{
    self.chatNotificationLabel.text = publicChat ?
        @"Anyone on Workclub can send you a chat message" :
        @"Only people in your contacts can send you a chat message";
}

- (NSString *)setTimeText:(NSDate *)timeValue
{
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc]init];
    timeFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    timeFormatter.dateFormat = @"h:mm a";
    NSString *timeString = [timeFormatter stringFromDate: timeValue];

    return timeString;
}

- (IBAction)gearPressed:(UIButton *)sender
{
    [self dismissPushModalViewControllerFromLeftSegue];
}

- (IBAction)contactsOnlyChatSwitchChanged:(id)sender
{
    [self setChatLabelText:self.contactsOnlyChatSwitch.on];
}

- (IBAction)notificationSwitchChanged:(CPSwitch *)sender
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         if ([self.timeFrameCell.subviews count] > 1) {
                             UIView *contentView = [self.timeFrameCell.subviews objectAtIndex:1];
                             contentView.alpha = sender.on ? 1.0 : 0.5;
                         }
                         self.timeFrameCell.userInteractionEnabled = sender.on;
                     }];
}

@end
