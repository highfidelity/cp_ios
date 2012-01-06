//
//  Facebook+Blocks.m
//  Facebook+Blocks
//
//  Created by David Mojdehi on 1/4/12.
//  Copyright (c) 2012 Mindful Bear Apps, All rights reserved.
//

#import "Facebook+Blocks.h"
#import "FBRequestOperation.h"

@implementation Facebook(Blocks)


// In the code below, the 'op' variable is retained deliberately,
// as FBRequests do *not* retain their delegates
// disable the clag warning about this
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"


/**
 * Make a request to Facebook's REST API with the given
 * parameters. One of the parameter keys must be "method" and its value
 * should be a valid REST server API method.
 *
 * See http://developers.facebook.com/docs/reference/rest/
 *
 * @param parameters
 *            Key-value pairs of parameters to the request. Refer to the
 *            documentation: one of the parameters must be "method".
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FBRequest*
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequestOperation*)requestWithParams:(NSMutableDictionary *)params
		   andCompletionHandler:(void (^)(FBRequestOperation*, id, NSError*)) clientHandler
{
	FBRequestOperation *op = [[FBRequestOperation alloc]init];
	op.completionHandler = clientHandler;
	__weak Facebook *weakSelf = self;
	[op addExecutionBlock:^{
								FBRequest *request = [weakSelf requestWithParams:params 
																	 andDelegate:op];
								op.request = request;
							} ];

	return op;
	
}

- (FBRequestOperation*)requestWithMethodName:(NSString *)methodName
								   andParams:(NSMutableDictionary *)params
							   andHttpMethod:(NSString *)httpMethod
						andCompletionHandler:(void (^)(FBRequestOperation*, id, NSError*)) clientHandler
{
	FBRequestOperation *op = [[FBRequestOperation alloc]init];
	op.completionHandler = clientHandler;
	__weak Facebook *weakSelf = self;
	[op addExecutionBlock:^{
		FBRequest *request = [weakSelf requestWithMethodName:methodName
												   andParams:params
											   andHttpMethod:httpMethod
												 andDelegate:op ];
		op.request = request;
	} ];
	
	return op;
	
}


- (FBRequestOperation*)requestWithGraphPath:(NSString *)graphPath
					   andCompletionHandler:(void (^)(FBRequestOperation*, id, NSError*)) clientHandler
{
	FBRequestOperation *op = [[FBRequestOperation alloc]init];
	op.completionHandler = clientHandler;
	__weak Facebook *weakSelf = self;
	[op addExecutionBlock:^{
		FBRequest *request = [weakSelf requestWithGraphPath:graphPath
												andDelegate:op];
		op.request = request;
	}];
	
	return op;
	
}






- (FBRequestOperation*)requestWithGraphPath:(NSString *)graphPath
								  andParams:(NSMutableDictionary *)params
					   andCompletionHandler:(void (^)(FBRequestOperation*, id, NSError*)) clientHandler
{
	FBRequestOperation *op = [[FBRequestOperation alloc]init];
	op.completionHandler = clientHandler;
	__weak Facebook *weakSelf = self;
	[op addExecutionBlock:^{
		FBRequest *request = [weakSelf requestWithGraphPath:graphPath
												  andParams:params
												andDelegate:op];
		op.request = request;
	}];
	
	return op;
	
}

- (FBRequestOperation*)requestWithGraphPath:(NSString *)graphPath
								  andParams:(NSMutableDictionary *)params
							  andHttpMethod:(NSString *)httpMethod
					   andCompletionHandler:(void (^)(FBRequestOperation*, id, NSError*)) clientHandler
{
	FBRequestOperation *op = [[FBRequestOperation alloc]init];
	op.completionHandler = clientHandler;
	__weak Facebook *weakSelf = self;
	[op addExecutionBlock:^{
		FBRequest *request = [weakSelf requestWithGraphPath:graphPath
												  andParams:params
											  andHttpMethod:httpMethod
												andDelegate:op];
		op.request = request;
	}];
	
	return op;
	
}
#pragma clang diagnostic pop



@end
