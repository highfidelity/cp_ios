//
//  OAMutableURLRequest.m
//  OAuthConsumer
//
//  Created by Jon Crosby on 10/19/07.
//  Copyright 2007 Kaboomerang LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "OAMutableURLRequest.h"

@interface OAMutableURLRequest (Private)
- (void)_generateTimestamp;
- (void)_generateNonce;
- (NSString *)_signatureBaseString;
@end

@implementation OAMutableURLRequest
@synthesize signature, nonce, verifier;

#pragma mark init

- (id)initWithURL:(NSURL *)aUrl
		 consumer:(OAConsumer *)aConsumer
			token:(OAToken *)aToken
            realm:(NSString *)aRealm
         verifier:(NSString *)aVerifier
signatureProvider:(id<OASignatureProviding, NSObject>)aProvider 
{
    if ((self = [super initWithURL:aUrl
                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                   timeoutInterval:10.0]))
	{    
		consumer = aConsumer;
		
		// empty token for Unauthorized Request Token transaction
		if (aToken == nil)
			token = [[OAToken alloc] init];
		else
			token = aToken;
		
		if (aRealm == nil)
			realm = [[NSString alloc] initWithString:@""];
		else 
			realm = aRealm;
		
		// default to HMAC-SHA1
		if (aProvider == nil)
			signatureProvider = [[OAHMAC_SHA1SignatureProvider alloc] init];
		else 
			signatureProvider = aProvider;
        
        if (aVerifier == nil)
            verifier = @"";
        else
            verifier = aVerifier;
		
		[self _generateTimestamp];
		[self _generateNonce];
	}
    return self;
}

- (id)initWithURL:(NSURL *)aUrl
		 consumer:(OAConsumer *)aConsumer
			token:(OAToken *)aToken
            realm:(NSString *)aRealm
signatureProvider:(id<OASignatureProviding>)aProvider {
    if ((self = [super initWithURL:aUrl
           cachePolicy:NSURLRequestReloadIgnoringCacheData
	   timeoutInterval:10.0])) {
    
		consumer = aConsumer;
		
		// empty token for Unauthorized Request Token transaction
		if (aToken == nil) {
			token = [[OAToken alloc] init];
		} else {
			token = aToken;
		}
		
		if (aRealm == nil) {
			realm = @"";
		} else {
			realm = [aRealm copy];
		}
		  
		// default to HMAC-SHA1
		if (aProvider == nil) {
			signatureProvider = [[OAHMAC_SHA1SignatureProvider alloc] init];
		} else {
			signatureProvider = aProvider;
		}
		
		[self _generateTimestamp];
		[self _generateNonce];
	}
    
    return self;
}

// Setting a timestamp and nonce to known
// values can be helpful for testing
- (id)initWithURL:(NSURL *)aUrl
		 consumer:(OAConsumer *)aConsumer
			token:(OAToken *)aToken
            realm:(NSString *)aRealm
signatureProvider:(id<OASignatureProviding>)aProvider
            nonce:(NSString *)aNonce
        timestamp:(NSString *)aTimestamp {
    if ((self = [self initWithURL:aUrl consumer:aConsumer token:aToken realm:aRealm signatureProvider:aProvider])) {
      nonce = [aNonce copy];
      timestamp = [aTimestamp copy];
    }
    
    return self;
}

- (void)setOAuthParameterName:(NSString*)parameterName withValue:(NSString*)parameterValue
{
	assert(parameterName && parameterValue);
	
	if (extraOAuthParameters == nil) {
		extraOAuthParameters = [NSMutableDictionary new];
	}
	
	[extraOAuthParameters setObject:parameterValue forKey:parameterName];
}


- (void)prepare 
{
    
    // sign
	// Secrets must be urlencoded before concatenated with '&'
	// TODO: if later RSA-SHA1 support is added then a little code redesign is needed
    NSString *tokenSecret = token.secret ? token.secret : @"";    
    NSString *tokenSecretAndConsumerSecret = [NSString stringWithFormat:@"%@&%@",
                                              [consumer.secret encodedURLString],
                                              [tokenSecret encodedURLString]];
    
    signature = [signatureProvider signClearText:[self _signatureBaseString]
                                      withSecret:tokenSecretAndConsumerSecret];

//    signature = [signatureProvider signClearText:[self _signatureBaseString]
//                                      withSecret:[NSString stringWithFormat:@"%@&%@",
//                                                  consumer.secret,
//                                                  token.secret ? token.secret : @""]];

    
    //
    //    signature = [signatureProvider signClearText:[self _signatureBaseString]
    //                                      withSecret:[NSString stringWithFormat:@"%@&%@",
    //												  [consumer.secret encodedURLString],
    //                                                  [token.secret encodedURLString]]];
    
    // set OAuth headers
    NSString *oauthToken;
    
    if ([token.key isEqualToString:@""] || !token.key)
        oauthToken = @""; // not used on Request Token transactions
    else
        oauthToken = [NSString stringWithFormat:@"oauth_token=\"%@\", ", [token.key encodedURLString]];
	
	NSMutableString *extraParameters = [NSMutableString string];
	
	// Adding the optional parameters in sorted order isn't required by the OAuth spec, but it makes it possible to hard-code expected values in the unit tests.
	for(NSString *parameterName in [[extraOAuthParameters allKeys] sortedArrayUsingSelector:@selector(compare:)])
	{
		[extraParameters appendFormat:@", %@=\"%@\"",
		 [parameterName encodedURLString],
		 [[extraOAuthParameters objectForKey:parameterName] encodedURLString]];
	}	
    
    NSString *oauthHeader;
    
    if (verifier) {
        oauthHeader = [NSString stringWithFormat:@"OAuth realm=\"%@\", oauth_consumer_key=\"%@\", oauth_nonce=\"%@\", oauth_signature_method=\"%@\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", %@oauth_verifier=\"%@\", oauth_version=\"1.0\"%@",
                       [realm encodedURLString],
                       [consumer.key encodedURLString],
                       nonce,
                       [[signatureProvider name] encodedURLString],
                       [signature encodedURLString],
                       timestamp,
                       oauthToken,
                       verifier,
                       extraParameters];
    }
    else {
        oauthHeader = [NSString stringWithFormat:@"OAuth realm=\"%@\", oauth_callback=\"%@\", oauth_consumer_key=\"%@\", %@oauth_signature_method=\"%@\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", oauth_version=\"1.0\"%@",
                       [realm encodedURLString],
                       @"candp://linkedin",
                       [consumer.key encodedURLString],
                       oauthToken,
                       [[signatureProvider name] encodedURLString],
                       [signature encodedURLString],
                       timestamp,
                       nonce,
                       extraParameters];
    }
	
//    NSLog(@"oauthHeader: %@", oauthHeader);
    
    [self setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
}

- (void)_generateTimestamp {
    timestamp = [[NSString alloc]initWithFormat:@"%d", time(NULL)];
}

- (void)_generateNonce {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    //NSMakeCollectable(theUUID);
    nonce = (__bridge NSString *)string;
}

NSInteger normalize(id obj1, id obj2, void *context)
{
    NSArray *nameAndValue1 = [obj1 componentsSeparatedByString:@"="];
    NSArray *nameAndValue2 = [obj2 componentsSeparatedByString:@"="];
    
    NSString *name1 = [nameAndValue1 objectAtIndex:0];
    NSString *name2 = [nameAndValue2 objectAtIndex:0];
    
    NSComparisonResult comparisonResult = [name1 compare:name2];
    if (comparisonResult == NSOrderedSame) {
        NSString *value1 = [nameAndValue1 objectAtIndex:1];
        NSString *value2 = [nameAndValue2 objectAtIndex:1];
        
        comparisonResult = [value1 compare:value2];
    }
    
    return comparisonResult;
}


- (NSString *)_signatureBaseString {
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // build a sorted array of both request parameters and OAuth header parameters
	NSDictionary *tokenParameters = [token parameters];
	// 6 being the number of OAuth params in the Signature Base String
	NSArray *parameters = [self parameters];
	NSMutableArray *parameterPairs = [[NSMutableArray alloc] initWithCapacity:(5 + [parameters count] + [tokenParameters count])];
    
	OARequestParameter *parameter;

    if (!verifier) {
        parameter = [[OARequestParameter alloc] initWithName:@"oauth_callback" value:@"candp://linkedin"];
        [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
    }

	parameter = [[OARequestParameter alloc] initWithName:@"oauth_consumer_key" value:consumer.key];
	
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
	parameter = [[OARequestParameter alloc] initWithName:@"oauth_signature_method" value:[signatureProvider name]];
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
	parameter = [[OARequestParameter alloc] initWithName:@"oauth_timestamp" value:timestamp];
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
	parameter = [[OARequestParameter alloc] initWithName:@"oauth_nonce" value:nonce];
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];

    if (verifier) {
        parameter = [[OARequestParameter alloc] initWithName:@"oauth_verifier" value:verifier];
        [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
    }

	parameter = [[OARequestParameter alloc] initWithName:@"oauth_version" value:@"1.0"] ;
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];

	for(NSString *k in tokenParameters) {
		[parameterPairs addObject:[[OARequestParameter requestParameter:k value:[tokenParameters objectForKey:k]] URLEncodedNameValuePair]];
	}
    
	if (![[self valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"multipart/form-data"]) {
		for (OARequestParameter *param in parameters) {
			[parameterPairs addObject:[param URLEncodedNameValuePair]];
		}
	}
    
    // Oauth Spec, Section 3.4.1.3.2 "Parameters Normalization    
    NSArray *sortedPairs = [parameterPairs sortedArrayUsingFunction:normalize context:NULL];

    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];
    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    return [NSString stringWithFormat:@"%@&%@&%@",
            [self HTTPMethod],
            [[[self URL] URLStringWithoutQuery] encodedURLParameterString],
            [normalizedRequestParameters encodedURLString]];
}

@end
