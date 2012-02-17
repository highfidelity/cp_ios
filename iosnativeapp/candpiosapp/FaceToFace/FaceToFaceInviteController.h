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

@property (nonatomic, strong) User *greeter;
@property (weak, nonatomic) IBOutlet UILabel *greeterNickname;
@property (weak, nonatomic) IBOutlet UIImageView *greeterImage;

- (IBAction)acceptF2F;
- (IBAction)declineF2F;

@end
