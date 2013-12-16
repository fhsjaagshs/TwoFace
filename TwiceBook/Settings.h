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
extern NSString * const kTwitterAccessTokenKey;

// Facebook
extern NSString * const kSelectedFriendsDictionaryKey;
extern NSString * const kFacebookAppID;
extern NSString * const kFacebookAccessTokenKey;

// Dropbox
extern NSString * const kDBSyncDeletedTArrayKey;
extern NSString * const kDBSyncDeletedFBDictKey;

extern NSString * const kEnteringForegroundNotif;

@class AppDelegate;

@interface Settings : NSObject

+ (AppDelegate *)appDelegate;

+ (NSString *)documentsDirectory;
+ (NSString *)cachesDirectory;
+ (NSMutableArray *)selectedTwitterUsernames;
+ (NSMutableDictionary *)selectedFacebookFriends;
+ (NSMutableArray *)dropboxDeletedTwitterArray;
+ (NSMutableDictionary *)dropboxDeletedFacebookDictionary;

+ (void)reloadMainTableView;

+ (void)showHUDWithTitle:(NSString *)title;
+ (void)hideHUD;
+ (void)setTitleOfVisibleHUD:(NSString *)newTitle;
+ (void)showSelfHidingHudWithTitle:(NSString *)title;
+ (void)showSuccessHUDWithCompletedTitle:(BOOL)shouldSayCompleted;

+ (void)removeFacebookFromTimeline;
+ (void)removeTwitterFromTimeline;

@end
