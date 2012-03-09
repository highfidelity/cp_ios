//
//  BalanceViewController.h
//  candpiosapp
//
//  Created by Stojce Slavkovski on 23.2.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BalanceViewController : UIViewController <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate>
{

@private
    BOOL isFlipped;
    BOOL loading;
    NSArray *transactions;
}

@property (weak, nonatomic) IBOutlet UITableView *transTableView;
@property (weak, nonatomic) IBOutlet UILabel *userBalance;
@property (weak, nonatomic) IBOutlet UIImageView *pullIcon;
@property (weak, nonatomic) IBOutlet UILabel *pullDownLabel;
@property (weak, nonatomic) IBOutlet UILabel *updateTimeLabel;

- (void)loadTransactionData;

@end
