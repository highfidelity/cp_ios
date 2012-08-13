//
//  ResumeVisibilityViewController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 6/14/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ResumeVisibilityViewController.h"
#import "ActionSheetStringPicker.h"

@interface ResumeVisibilityViewController ()

@property (strong, nonatomic) NSArray *resumeVisibilityOptions;
@property (strong, nonatomic) NSArray *resumeVisibilityOptionsKeys;
@property (strong, nonatomic) NSString *originalProfileURLVisibility;
@property (strong, nonatomic) User *user;
@property (weak, nonatomic) IBOutlet UIButton *resumeVisibilityButton;


- (IBAction)resumeVisibilityButtonClick:(id)sender;
- (void)updateResumeVisibilityButtonText;
- (void)saveResumeVisibility;

@end

@implementation ResumeVisibilityViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.originalProfileURLVisibility = self.user.profileURLVisibility;
    
    self.resumeVisibilityOptions = [NSArray arrayWithObjects:
                                    @"Only people logged in",
                                    @"Allow anyone",
                                    nil];
    
    self.resumeVisibilityOptionsKeys = [NSArray arrayWithObjects:
                                        @"loggedin",
                                        @"global",
                                        nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.user = [CPUserDefaultsHandler currentUser];
    
    self.resumeVisibilityButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    
    [self updateResumeVisibilityButtonText];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self saveResumeVisibility];
}

#pragma mark - actions

- (IBAction)resumeVisibilityButtonClick:(id)sender {
    NSUInteger initialSelection = [self.resumeVisibilityOptionsKeys indexOfObject:self.user.profileURLVisibility];
    if (NSNotFound == initialSelection || initialSelection >= [self.resumeVisibilityOptions count]) {
        initialSelection = 0;
    }
    
    [ActionSheetStringPicker showPickerWithTitle:@"Resume Visibility"
                                            rows:self.resumeVisibilityOptions
                                initialSelection:initialSelection
                                          target:self
                                   successAction:@selector(resumeVisibilityOptionsSuccessAction:element:)
                                    cancelAction:nil
                                          origin:sender];
}

- (void)resumeVisibilityOptionsSuccessAction:(NSNumber *)selectedIndex element:(UIButton *)element {
    self.user.profileURLVisibility = [self.resumeVisibilityOptionsKeys objectAtIndex:[selectedIndex unsignedIntegerValue]];
    [self updateResumeVisibilityButtonText];
}

#pragma mark - private

- (void)updateResumeVisibilityButtonText {
    NSUInteger visibilityKeyIndex = [self.resumeVisibilityOptionsKeys indexOfObject:self.user.profileURLVisibility];
    if (NSNotFound != visibilityKeyIndex && visibilityKeyIndex < [self.resumeVisibilityOptions count]) {
        [self.resumeVisibilityButton setTitle:[self.resumeVisibilityOptions objectAtIndex:visibilityKeyIndex]
                                     forState:UIControlStateNormal];
    } else {
        [self.resumeVisibilityButton setTitle:@"" forState:UIControlStateNormal];
    }
}

- (void)saveResumeVisibility {
    if (self.originalProfileURLVisibility != self.user.profileURLVisibility) {
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
        [parameters setValue:self.user.profileURLVisibility forKey:@"profileURL_visibility"];
        
        [CPapi setUserProfileDataWithDictionary:parameters
                                  andCompletion:nil];
    }
}

@end
