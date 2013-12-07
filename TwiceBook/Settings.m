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
NSString * const kSelectedUsernamesListKey = @"usernames_twitter";
NSString * const kAddedUsernamesListKey = @"addedUsernames_twitter";
NSString * const kSelectedFriendsDictionaryKey = @"FBSelectedFriendsDict";
NSString * const kDBSyncDeletedTArrayKey = @"DBSyncDeletedTwitterArray";
NSString * const kDBSyncDeletedFBDictKey = @"DBSyncDeletedFBDict";
NSString * const kEnteringForegroundNotif = @"enterForeground";
NSString * const kFacebookAppID = @"314352998657355";
NSString * const kFacebookAccessTokenKey = @"kFacebookAccessTokenKey";
NSString * const kTwitterAccessTokenKey = @"kTwitterAccessTokenKey";

@implementation Settings

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

+ (NSString *)usernameLookupCachePath {
    return [[Settings cachesDirectory]stringByAppendingPathComponent:@"twitter_username_lookup_dict.plist"];
}

+ (NSString *)draftsPath {
    return [[Settings documentsDirectory]stringByAppendingPathComponent:@"drafts.plist"];
}

+ (NSMutableArray *)drafts {
    NSMutableArray *loaded = [NSMutableArray arrayWithContentsOfFile:[Settings draftsPath]];
    return (loaded.count == 0)?@[].mutableCopy:loaded;
}

+ (NSMutableArray *)selectedTwitterUsernames {
    NSArray *loaded = [[NSUserDefaults standardUserDefaults]objectForKey:kSelectedUsernamesListKey];
    return ((loaded.count == 0)?@[]:loaded).mutableCopy;
}

+ (NSMutableArray *)addedTwitterUsernames {
    NSArray *loaded = [[NSUserDefaults standardUserDefaults]objectForKey:kAddedUsernamesListKey];
    return ((loaded.count == 0)?@[]:loaded).mutableCopy;
}

+ (NSMutableDictionary *)selectedFacebookFriends {
    NSDictionary *loaded = [[NSUserDefaults standardUserDefaults]objectForKey:kSelectedFriendsDictionaryKey];
    return ((loaded.count == 0)?@{}:loaded).mutableCopy;
}

+ (NSMutableArray *)dropboxDeletedTwitterArray {
    NSArray *loaded = [[NSUserDefaults standardUserDefaults]objectForKey:kDBSyncDeletedTArrayKey];
    return ((loaded.count == 0)?@[]:loaded).mutableCopy;
}

+ (NSMutableDictionary *)dropboxDeletedFacebookDictionary {
    NSDictionary *loaded = [[NSUserDefaults standardUserDefaults]objectForKey:kDBSyncDeletedFBDictKey];
    return ((loaded.count == 0)?@{}:loaded).mutableCopy;
}

+ (void)reloadMainTableView {
    [[NSNotificationCenter defaultCenter]postNotificationName:@"reloadTableView" object:nil];
}

+ (void)removeFacebookFromTimeline {
    [[[Cache sharedCache]timeline]filterUsingPredicate:[NSPredicate predicateWithFormat:@"class != %@",[Status class]]];
    
    /* NSMutableArray *timeline = [[Cache sharedCache]timeline];
     
     for (NSDictionary *dict in timeline) {
     if ([dict[@"social_network_name"] isEqualToString:@"facebook"]) {
     [[[Cache sharedCache]timeline]removeObject:dict];
     }
     }*/
}

+ (void)removeTwitterFromTimeline {
    [[[Cache sharedCache]timeline]filterUsingPredicate:[NSPredicate predicateWithFormat:@"class != %@",[Tweet class]]];
    /*NSMutableArray *timeline = [[Cache sharedCache]timeline].mutableCopy;
     
     for (NSDictionary *dict in timeline) {
     if ([dict[@"social_network_name"] isEqualToString:@"twitter"]) {
     [[[Cache sharedCache]timeline]removeObject:dict];
     }
     }*/
}

//
// HUD management Methods
//

+ (void)showSuccessHUDWithCompletedTitle:(BOOL)shouldSayCompleted {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:Settings.appDelegate.window animated:YES];
    hud.mode = MBProgressHUDModeCustomView;
    hud.labelText = shouldSayCompleted?@"Completed":@"Success";
    hud.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Checkmark"]];
    [hud hide:YES afterDelay:1.5];
}

+ (void)showHUDWithTitle:(NSString *)title {
    [MBProgressHUD hideAllHUDsForView:Settings.appDelegate.window animated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:Settings.appDelegate.window animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = title;
}

+ (void)hideHUD {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [MBProgressHUD hideAllHUDsForView:Settings.appDelegate.window animated:YES];
}

+ (void)setTitleOfVisibleHUD:(NSString *)newTitle {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:Settings.appDelegate.window];
    hud.labelText = newTitle;
}

+ (void)showSelfHidingHudWithTitle:(NSString *)title {
    [MBProgressHUD hideAllHUDsForView:Settings.appDelegate.window animated:YES];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:Settings.appDelegate.window animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = title;
    [hud hide:YES afterDelay:1.5];
}

@end
