//
//  JobCategoryViewController.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 14.4.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "JobCategoryViewController.h"
#import "ActionSheetStringPicker.h"

@interface JobCategoryViewController ()


@property (weak, nonatomic) IBOutlet UIButton *majorCategoryButton;
@property (weak, nonatomic) IBOutlet UIButton *minorCategoryButton;

- (IBAction)majorCategoryButtonClick:(id)sender;
- (IBAction)minorCategoryButtonClick:(id)sender;


@property (strong, nonatomic) User *user;
@property (strong, nonatomic) NSArray *jobCategories;
- (void)saveUserJobCategories;

@end

@implementation JobCategoryViewController
@synthesize majorCategoryButton = _majorCategoryButton;
@synthesize minorCategoryButton = _minorCategoryButton;
@synthesize jobCategories = _jobCategories;
@synthesize user = _user;


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
    self.user = [CPUserDefaultsHandler currentUser];

    self.jobCategories = [NSArray arrayWithObjects:
                          @"engineering",
                          @"design",
                          @"marketing",
                          @"legal",
                          @"finance",
                          @"admin",
                          @"investor",
                          @"business development",
                          @"other",
                          nil];

    [self majorCategoryButton].titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    [[self majorCategoryButton] setTitle:[self.user majorJobCategory] forState:UIControlStateNormal];
    
    [self minorCategoryButton].titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    [[self minorCategoryButton] setTitle:[self.user minorJobCategory] forState:UIControlStateNormal];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self saveUserJobCategories];
}

- (void)saveUserJobCategories
{
    if ([self.user majorJobCategory] != [[self.majorCategoryButton titleLabel] text] ||
            [self.user minorJobCategory] != [[self.minorCategoryButton titleLabel] text]) {

        [self.user setMajorJobCategory:[[self.majorCategoryButton titleLabel] text]];
        [self.user setMinorJobCategory:[[self.minorCategoryButton titleLabel] text]];

        [SVProgressHUD show];

        [CPapi saveUserMajorJobCategory:[self.user majorJobCategory]
                    andMinorJobCategory:[self.user minorJobCategory]];

    }
}

- (IBAction)majorCategoryButtonClick:(id)sender
{
    [ActionSheetStringPicker showPickerWithTitle:@"Major Job Category"
                                            rows:self.jobCategories
                                initialSelection:[[self jobCategories] indexOfObject:[[self.majorCategoryButton titleLabel] text]]
                                          target:self
                                   successAction:@selector(setText:element:)
                                    cancelAction:nil
                                          origin:sender];
}

- (void)setText:(NSNumber *)selectedIndex element:(UIButton *)element
{
    [element setTitle:[self.jobCategories  objectAtIndex:[selectedIndex unsignedIntegerValue]]
                         forState:UIControlStateNormal];
}

- (IBAction)minorCategoryButtonClick:(id)sender
{
    [ActionSheetStringPicker showPickerWithTitle:@"Minor Job Category"
                                            rows:self.jobCategories
                                initialSelection:[[self jobCategories] indexOfObject:[[self.minorCategoryButton titleLabel] text]]
                                          target:self
                                   successAction:@selector(setText:element:)
                                    cancelAction:nil
                                          origin:sender];
}
@end
