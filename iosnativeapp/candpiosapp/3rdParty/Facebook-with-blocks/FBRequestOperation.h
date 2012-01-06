//
//  Facebook+Blocks.h
//  Facebook+Blocks
//
//  Created by David Mojdehi on 1/4/12.
//  Copyright (c) 2012 Mindful Bear Apps, All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class FBRequestOperation;
@class FBRequest;

typedef void	 (^FBCompletionBlock)(FBRequestOperation*, id, NSError*);

///////////////////////////////////////////////////////////////////////////

@interface FBRequestOperation : NSBlockOperation<FBRequestDelegate>

@property (nonatomic, strong) FBRequest *request;
@property (nonatomic, copy) FBCompletionBlock completionHandler;

+ (id)operationWithBlock:(void (^)(void))block
		   andCompletion:(void (^)(FBRequestOperation*, id, NSError*)) completion;

@end


////////////////////////////////////////////////////////////////////////////////
