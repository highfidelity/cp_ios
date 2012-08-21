//
//  CPTouchableView.h
//  candpiosapp
//
//  Created by Stojce Slavkovski on 29.6.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CPTouchViewDelegate
- (void) touchUp:(id)sender;
@end

@interface CPTouchableView : UIView 

@property (weak, nonatomic) id delegate;

@end
