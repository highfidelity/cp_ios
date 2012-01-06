//
//  Facebook+Blocks.h
//  Facebook+Blocks
//
//  Created by David Mojdehi on 1/4/12.
//  Copyright (c) 2012 Mindful Bear Apps, All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Facebook.h"
#import "FBRequestOperation.h"

@class FBRequestOperation;

@interface Facebook(Blocks) 

- (FBRequestOperation*)requestWithParams:(NSMutableDictionary *)params
					andCompletionHandler:(void (^)(FBRequestOperation*, id, NSError*)) clientHandler;

- (FBRequestOperation*)requestWithMethodName:(NSString *)methodName
								   andParams:(NSMutableDictionary *)params
							   andHttpMethod:(NSString *)httpMethod
						andCompletionHandler:(void (^)(FBRequestOperation*, id, NSError*)) clientHandler;

- (FBRequestOperation*)requestWithGraphPath:(NSString *)graphPath
					   andCompletionHandler:(void (^)(FBRequestOperation*, id, NSError*)) clientHandler;

- (FBRequestOperation*)requestWithGraphPath:(NSString *)graphPath
								  andParams:(NSMutableDictionary *)params
					   andCompletionHandler:(void (^)(FBRequestOperation*, id, NSError*)) clientHandler;

- (FBRequestOperation*)requestWithGraphPath:(NSString *)graphPath
								  andParams:(NSMutableDictionary *)params
							  andHttpMethod:(NSString *)httpMethod
					   andCompletionHandler:(void (^)(FBRequestOperation*, id, NSError*)) clientHandler;


@end

