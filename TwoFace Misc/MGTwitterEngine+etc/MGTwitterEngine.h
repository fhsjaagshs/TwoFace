//
//  MGTwitterEngine.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 10/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

#import "MGTwitterEngineDelegate.h"
#import "MGTwitterParserDelegate.h"

@interface MGTwitterEngine : NSObject <MGTwitterParserDelegate> {
    __weak NSObject <MGTwitterEngineDelegate> *_delegate;
    NSString *_username;
    NSString *_password;
    NSMutableDictionary *_connections;   // MGTwitterHTTPURLConnection objects
    NSString *_clientName;
    NSString *_clientVersion;
    NSString *_clientURL;
    NSString *_clientSourceToken;
	NSString *_APIDomain;
    BOOL _secureConnection;
	BOOL _clearsCookies;
}

#pragma mark Class management

// Constructors
+ (MGTwitterEngine *)twitterEngineWithDelegate:(NSObject *)delegate;
- (MGTwitterEngine *)initWithDelegate:(NSObject *)delegate;

// Configuration and Accessors
+ (NSString *)version; // returns the version of MGTwitterEngine
- (NSString *)username;
- (NSString *)password;
- (void)setUsername:(NSString *)username password:(NSString *)password;
- (NSString *)clientName; // see README.txt for info on clientName/Version/URL/SourceToken
- (NSString *)clientVersion;
- (NSString *)clientURL;
- (NSString *)clientSourceToken;
- (void)setClientName:(NSString *)name version:(NSString *)version URL:(NSString *)url token:(NSString *)token;
- (NSString *)APIDomain;
- (void)setAPIDomain:(NSString *)domain;
- (BOOL)usesSecureConnection; // YES = uses HTTPS, default is YES
- (void)setUsesSecureConnection:(BOOL)flag;
- (BOOL)clearsCookies; // YES = deletes twitter.com cookies when setting username/password, default is NO (see README.txt)
- (void)setClearsCookies:(BOOL)flag;

// Connection methods
- (int)numberOfConnections;
- (NSArray *)connectionIdentifiers;
- (void)closeConnection:(NSString *)identifier;
- (void)closeAllConnections;

// Utility methods
- (NSString *)getImageAtURL:(NSString *)urlString; // gets any image at any URL, Does not require auth. Images are sent to -imageReceived:forRequest: method.

#pragma mark REST API methods

// ======================================================================================================
// Twitter REST API methods
// See documentation at: https://dev.twitter.com/docs/api
// All methods below return a unique connection identifier.
// ======================================================================================================

// Status methods
- (NSString *)getPublicTimeline; // statuses/public_timeline
- (NSString *)getFollowedTimelineSinceID:(unsigned long)sinceID startingAtPage:(int)pageNum count:(int)count; // statuses/friends_timeline
- (NSString *)getFollowedTimelineSinceID:(unsigned long)sinceID withMaximumID:(unsigned long)maxID startingAtPage:(int)pageNum count:(int)count; // statuses/friends_timeline
- (NSString *)getUserTimelineFor:(NSString *)username sinceID:(unsigned long)sinceID startingAtPage:(int)pageNum count:(int)count; // statuses/user_timeline & statuses/user_timeline/user
- (NSString *)getUserTimelineFor:(NSString *)username sinceID:(unsigned long)sinceID withMaximumID:(unsigned long)maxID startingAtPage:(int)pageNum count:(int)count; // statuses/user_timeline & statuses/user_timeline/user
- (NSString *)getUpdate:(unsigned long)updateID; // statuses/show
- (NSString *)sendUpdate:(NSString *)status; // statuses/update
- (NSString *)sendUpdate:(NSString *)status inReplyTo:(unsigned long)updateID; // statuses/update
- (NSString *)sendUpdate:(NSString *)status withImageData:(NSData *)data; // statuses/update_with_media
- (NSString *)getRepliesStartingAtPage:(int)pageNum; // statuses/mentions
- (NSString *)getRepliesSinceID:(unsigned long)sinceID startingAtPage:(int)pageNum count:(int)count; // statuses/mentions
- (NSString *)getRepliesSinceID:(unsigned long)sinceID withMaximumID:(unsigned long)maxID startingAtPage:(int)pageNum count:(int)count; // statuses/mentions
- (NSString *)deleteUpdate:(unsigned long)updateID; // statuses/destroy

- (NSString *)sendRetweet:(unsigned long)updateID; // statuses/retweet
- (NSString *)getRetweets:(unsigned long)updateID; // statuses/retweets
- (NSString *)getRetweets:(unsigned long)updateID count:(int)count; // statuses/retweets


// User methods
- (NSString *)getRecentlyUpdatedFriendsFor:(NSString *)username startingAtPage:(int)pageNum; // statuses/friends & statuses/friends/user
- (NSString *)getFollowersIncludingCurrentStatus:(BOOL)flag; // statuses/followers
- (NSString *)getUserInformationFor:(NSString *)usernameOrID; // users/show
- (NSString *)getUserInformationForEmail:(NSString *)email; // users/show


// Direct Message methods
- (NSString *)getDirectMessagesSinceID:(unsigned long)sinceID startingAtPage:(int)pageNum; // direct_messages
- (NSString *)getDirectMessagesSinceID:(unsigned long)sinceID withMaximumID:(unsigned long)maxID startingAtPage:(int)pageNum count:(int)count; // direct_messages
- (NSString *)getSentDirectMessagesSinceID:(unsigned long)sinceID startingAtPage:(int)pageNum; // direct_messages/sent
- (NSString *)getSentDirectMessagesSinceID:(unsigned long)sinceID withMaximumID:(unsigned long)maxID startingAtPage:(int)pageNum count:(int)count; // direct_messages/sent
- (NSString *)sendDirectMessage:(NSString *)message to:(NSString *)username; // direct_messages/new
- (NSString *)deleteDirectMessage:(unsigned long)updateID;// direct_messages/destroy


// Friendship methods
- (NSString *)enableUpdatesFor:(NSString *)username; // friendships/create (follow username)
- (NSString *)disableUpdatesFor:(NSString *)username; // friendships/destroy (unfollow username)
- (NSString *)isUser:(NSString *)username1 receivingUpdatesFor:(NSString *)username2; // friendships/exists (test if username1 follows username2)
- (NSString *)getFollowingIncludingCurrentStatus:(BOOL)flag; // statuses/friends


// Account methods
- (NSString *)checkUserCredentials; // account/verify_credentials
- (NSString *)endUserSession; // account/end_session
- (NSString *)setNotificationsDeliveryMethod:(NSString *)method; // account/update_delivery_device
- (NSString *)getRateLimitStatus; // account/rate_limit_status


// Favorite methods
- (NSString *)getFavoriteUpdatesFor:(NSString *)username startingAtPage:(int)pageNum; // favorites
- (NSString *)markUpdate:(unsigned long)updateID asFavorite:(BOOL)flag; // favorites/create, favorites/destroy


// Notification methods
- (NSString *)enableNotificationsFor:(NSString *)username; // notifications/follow
- (NSString *)disableNotificationsFor:(NSString *)username; // notifications/leave


// Block methods
- (NSString *)block:(NSString *)username; // blocks/create
- (NSString *)unblock:(NSString *)username; // blocks/destroy


// Help methods
- (NSString *)testService; // help/test
- (NSString *)getDowntimeSchedule; // help/downtime_schedule (undocumented)


@end
