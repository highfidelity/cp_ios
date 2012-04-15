//
//  JobCategoryViewController.h
//  candpiosapp
//
//  Created by Stojce Slavkovski on 14.4.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JobCategoryViewController : UIViewController
@property (weak) User * user;

@property (weak, nonatomic) IBOutlet UIButton *majorCategoryButton;
@property (weak, nonatomic) IBOutlet UIButton *minorCategoryButton;

- (IBAction)majorCategoryButtonClick:(id)sender;
- (IBAction)minorCategoryButtonClick:(id)sender;
@end
