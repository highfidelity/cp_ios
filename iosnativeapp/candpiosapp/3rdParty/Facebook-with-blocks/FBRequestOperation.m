//
//  Facebook+Blocks.h
//  Facebook+Blocks
//
//  Created by David Mojdehi on 1/4/12.
//  Copyright (c) 2012 Mindful Bear Apps, All rights reserved.
//

#import "Facebook.h"
#import "FBRequestOperation.h"
#import "SBJson.h"




@implementation FBRequestOperation

@synthesize request, completionHandler;
+ (id)operationWithBlock:(void (^)(void))block
		   andCompletion:(void (^)(FBRequestOperation*, id, NSError*)) completion
{
	FBRequestOperation *op = [[FBRequestOperation alloc] init];
	[op addExecutionBlock:block];
	op.completionHandler = completion;
	return op;
}


/**
 * Called when an error prevents the request from completing successfully.
 */
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error
{
	if(completionHandler)
		completionHandler(self, nil, error);
}

/**
 * Called when a request returns and its response has been parsed into
 * an object.
 *
 * The resulting object may be a dictionary, an array, a string, or a number,
 * depending on thee format of the API response.
 */
- (void)request:(FBRequest *)request didLoad:(id)result
{
	if(completionHandler)
		completionHandler(self, result, nil);
	
}


@end
