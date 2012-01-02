//
//  UserSubview.h
//  candpiosapp
//
//  Created by David Mojdehi on 1/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^ButtonActionBlock)(NSDictionary* cellConfig);

@interface UserSubview : UIView
{
	void (^tapAction)();
	
	
}

-(void)setup:(NSString*)imageUrl name:(NSString*)name buttonTapped:(void (^)(void))tapAction;

-(void)setImageUrl:(NSString*)url;
-(void)setName:(NSString*)name;
@end
