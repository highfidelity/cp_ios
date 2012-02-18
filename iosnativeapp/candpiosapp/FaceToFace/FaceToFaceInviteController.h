//
//  FaceToFaceInviteController.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/14.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface FaceToFaceInviteController : UIViewController

@property (nonatomic, strong) User *user;
@property (nonatomic, strong) NSString *passwordMode;
@property (weak, nonatomic) IBOutlet UILabel *userNickname;
@property (weak, nonatomic) IBOutlet UIImageView *userImage;
@property (weak, nonatomic) IBOutlet UILabel *f2fText;
@property (weak, nonatomic) IBOutlet UIButton *f2fAcceptButton;
@property (weak, nonatomic) IBOutlet UIButton *f2fDeclineButton;
@property (weak, nonatomic) IBOutlet UILabel *f2fActionCaption;
@property (weak, nonatomic) IBOutlet UITextField *f2fPassword;

- (IBAction)acceptF2F;
- (IBAction)declineF2F;
- (IBAction)f2fSubmitPassword;

@end
