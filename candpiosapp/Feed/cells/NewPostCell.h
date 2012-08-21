//
//  NewPostCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "PostBaseCell.h"
#import "HPGrowingTextView.h"

@interface NewPostCell : PostBaseCell

@property (weak, nonatomic) IBOutlet HPGrowingTextView *growingTextView;

@end
