//
//  Settings.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/4/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Settings.h"
#import "AppDelegate.h"

NSString * const kOAuthConsumerKey = @"ZII6ta1CbVKy8TnBNaasAQ";
NSString * const kOAuthConsumerSecret = @"b6cqaoefVkKZsWFVxiD32o6AUjaf0oAcsJHxHz1E";
NSString * const kSelectedusernamesListKey = @"usernames_twitter";
NSString * const kAddedUsernamesListKey = @"addedUsernames_twitter";
NSString * const kSelectedFriendsDictionaryKey = @"FBSelectedFriendsDict";
NSString * const kDBSyncDeletedTArrayKey = @"DBSyncDeletedTwitterArray";
NSString * const kDBSyncDeletedFBDictKey = @"DBSyncDeletedFBDict";
NSString * const kEnteringForegroundNotif = @"enterForeground";
NSString * const kFacebookAppID = @"314352998657355";

@implementation Settings

/*+ (Settings *)sharedSettings {
    static Settings *sharedSettings;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSettings = [[Settings alloc]init];
    });
    return sharedSettings;
}*/

+ (AppDelegate *)appDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication]delegate];
}

+ (NSString *)documentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)cachesDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)invalidUsersCachePath {
    return [[Settings cachesDirectory]stringByAppendingPathComponent:@"invalid_users.plist"];
}

+ (NSString *)tweetCachePath {
    return [[Settings cachesDirectory]stringByAppendingPathComponent:@"cached_tweets.plist"];
}

+ (NSMutableArray *)tweetCache {
    return [NSMutableArray arrayWithContentsOfFile:[Settings tweetCachePath]];
}

+ (NSString *)usernameLookupCachePath {
    return [[Settings cachesDirectory]stringByAppendingPathComponent:@"twitter_username_lookup_dict.plist"];
}

+ (NSString *)draftsPath {
    return [[Settings documentsDirectory]stringByAppendingPathComponent:@"drafts.plist"];
}

+ (NSMutableArray *)drafts {
    return [NSMutableArray arrayWithContentsOfFile:[Settings draftsPath]];
}

+ (NSMutableArray *)selectedTwitterUsernames {
    return [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:kSelectedUsernamesListKey]];
}

+ (NSMutableArray *)addedTwitterUsernames {
    return [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:kAddedUsernamesListKey]];
}

+ (NSMutableDictionary *)selectedFacebookFriends {
    return [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults]objectForKey:kSelectedFriendsDictionaryKey]];
}

+ (NSMutableArray *)dropboxDeletedTwitterArray {
    return [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:kDBSyncDeletedTArrayKey]];
}

+ (NSMutableDictionary *)dropboxDeletedFacebookDictionary {
    return [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults]objectForKey:kDBSyncDeletedFBDictKey]];
}



@end