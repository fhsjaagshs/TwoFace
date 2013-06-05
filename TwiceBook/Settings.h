//
//  Settings.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/4/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

// Twitter
extern NSString * const kOAuthConsumerKey;
extern NSString * const kOAuthConsumerSecret;
extern NSString * const kSelectedUsernamesListKey;
extern NSString * const kAddedUsernamesListKey;

// Facebook
extern NSString * const kSelectedFriendsDictionaryKey;
extern NSString * const kFacebookAppID;

// Dropbox
extern NSString * const kDBSyncDeletedTArrayKey;
extern NSString * const kDBSyncDeletedFBDictKey;

extern NSString * const kEnteringForegroundNotif;

@class AppDelegate;

@interface Settings : NSObject

+ (AppDelegate *)appDelegate;
+ (NSString *)documentsDirectory;
+ (NSString *)cachesDirectory;
+ (NSString *)invalidUsersCachePath;
+ (NSString *)tweetCachePath;
+ (NSMutableArray *)tweetCache;
+ (NSString *)usernameLookupCachePath;
+ (NSString *)draftsPath;
+ (NSMutableArray *)drafts;
+ (NSMutableArray *)selectedTwitterUsernames;
+ (NSMutableArray *)addedTwitterUsernames;
+ (NSMutableDictionary *)selectedFacebookFriends;
+ (NSMutableArray *)dropboxDeletedTwitterArray;
+ (NSMutableDictionary *)dropboxDeletedFacebookDictionary;

@end
