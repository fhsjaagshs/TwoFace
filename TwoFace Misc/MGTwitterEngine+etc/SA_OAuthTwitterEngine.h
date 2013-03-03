//
//  SA_OAuthTwitterEngine.h
//
//  Created by Ben Gottlieb on 24 July 2009.
//  Copyright 2009 Stand Alone, Inc.
//
//  Some code and concepts taken from examples provided by 
//  Matt Gemmell, Chris Kimpton, and Isaiah Carew
//  See ReadMe for further attributions, copyrights and license info.
//

#import "MGTwitterEngine.h"

#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "OARequestParameter.h"
#import "OADataFetcher.h"
#import "OAToken.h"

@protocol SA_OAuthTwitterEngineDelegate
@optional
- (void)storeCachedTwitterOAuthData:(NSString *)data forUsername:(NSString *)username; // stores the creds returned by Twitter
- (NSString *)cachedTwitterOAuthDataForUsername:(NSString *)username; // returns stored creds so the user doesn't have to revalidate
- (void)twitterOAuthConnectionFailedWithData:(NSData *)data; 
@end


@interface SA_OAuthTwitterEngine : MGTwitterEngine {
	NSString	*_consumerSecret;
	NSString	*_consumerKey;
	NSURL		*_requestTokenURL;
	NSURL		*_accessTokenURL;
	NSURL		*_authorizeURL;


	NSString	*_pin;

	OAConsumer	*_consumer;
	OAToken		*_requestToken;
	OAToken		*_accessToken; 
}

@property (nonatomic, strong) NSString *consumerSecret, *consumerKey;
@property (nonatomic, strong) NSURL *requestTokenURL, *accessTokenURL, *authorizeURL; // you shouldn't need to touch these. Just in case...
@property (nonatomic, readonly) BOOL OAuthSetup;

+ (SA_OAuthTwitterEngine *) OAuthTwitterEngineWithDelegate: (NSObject *) delegate;
- (SA_OAuthTwitterEngine *) initOAuthWithDelegate: (NSObject *) delegate;
- (BOOL)isAuthorized;
- (void)requestAccessToken;
- (void)requestRequestToken;
- (void)clearAccessToken;
- (void)reAuthorizeFromCachedOAuthData;
- (BOOL)isAuthorizedOriginal;
- (void)requestRequestTokenSync;
- (OAToken *)getAccessToken;
- (OAToken *)getRequestToken;

@property (nonatomic, strong)  NSString	*pin;
@property (weak, nonatomic, readonly) NSURLRequest *authorizeURLRequest;
@property (weak, nonatomic, readonly) OAConsumer *consumer;

@end
