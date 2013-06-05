//
//  AppDelegate.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/3/12.
//  Copyright (c) 2012 Nawthaniel Symer. All rights reserved.
//

// Potential New name: PrimaFacie

#import <UIKit/UIKit.h>

//
// All headers in Prefix.pch
//

// Cache paths
/*#define invalidUsersCachePath [kCachesDirectory stringByAppendingPathComponent:@"cached_invalid_users.plist"]
#define contextualTweetCachePath [kCachesDirectory stringByAppendingPathComponent:@"cached_replied_to_tweets.plist"]
#define usernamesListCachePath [kCachesDirectory stringByAppendingPathComponent:@"twitter_username_lookup_dict.plist"]

// General
#define kAppDelegate (AppDelegate *)[[UIApplication sharedApplication]delegate]
#define kDocumentsDirectory [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
#define kCachesDirectory [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]

// Main Table View

// Twitter OAuth keys
extern NSString * const kOAuthConsumerKey;
extern NSString * const kOAuthConsumerSecret;

// Twitter
extern NSString * const usernamesListKey;
extern NSString * const addedUsernamesListKey;

#define usernamesListArray [[NSMutableArray alloc]initWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:usernamesListKey]]
#define addedUsernamesListArray [[NSMutableArray alloc]initWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:addedUsernamesListKey]]

// Facebook
extern NSString * const kSelectedFriendsDictionaryKey;

#define kSelectedFriendsDictionary [[NSMutableDictionary alloc]initWithDictionary:[[NSUserDefaults standardUserDefaults]objectForKey:kSelectedFriendsDictionaryKey]]

// Dropbox Sync
extern NSString * const kDBSyncDeletedTArrayKey;
extern NSString * const kDBSyncDeletedFBDictKey;

#define kDBSyncDeletedTArray [[NSMutableArray alloc]initWithArray:[[NSUserDefaults standardUserDefaults]objectForKey:kDBSyncDeletedTArrayKey]]
#define kDBSyncDeletedFBDict [[NSMutableDictionary alloc]initWithDictionary:[[NSUserDefaults standardUserDefaults]objectForKey:kDBSyncDeletedFBDictKey]]

#define kDraftsPath [kDocumentsDirectory stringByAppendingPathComponent:@"drafts.plist"]
#define kDraftsArray [[NSMutableArray alloc]initWithContentsOfFile:kDraftsPath]


extern NSString * const kFacebookAppID;

// App State Notifs

extern NSString * const kEnteringForegroundNotif;*/

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, FBSessionDelegate, DBRestClientDelegate, DBSessionDelegate, FHSTwitterEngineAccessTokenDelegate> {
    NSString *savedRev;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ViewController *viewController;

//
// picTwitter image URL handling
//

- (void)setImageURL:(NSString *)imageURL forLinkURL:(NSString *)linkURL;
- (NSString *)getImageURLForLinkURL:(NSString *)linkURL;

//
// Twitter
//

//@property (nonatomic, strong) FHSTwitterEngine *engine;
@property (nonatomic, strong) NSMutableArray *theFetchedUsernames;

- (void)makeSureUsernameListArraysAreNotNil;

- (void)reloadMainTableView;
- (void)clearImageCache;

//
// Facebook
//

// Blocker View methods
//- (void)showBlockerView;
//- (void)removeBlockerView;
- (void)showHUDWithTitle:(NSString *)title;
- (void)hideHUD;
- (void)setTitleOfVisibleHUD:(NSString *)newTitle;
- (void)showSelfHidingHudWithTitle:(NSString *)title;
- (void)showSuccessHUDWithCompletedTitle:(BOOL)shouldSayCompleted;

// Login methods
- (void)loginFacebook;
- (void)logoutFacebook;
- (void)startFacebook;
- (void)tryLoginFromSavedCreds;
- (NSString *)getFacebookUsernameSync;


@property (strong, nonatomic) Facebook *facebook;
@property (nonatomic, strong) NSMutableDictionary *facebookFriendsDict;


//
// Timeline management
//

- (void)removeFacebookFromTimeline;
- (void)removeTwitterFromTimeline;
- (NSMutableArray *)getCachedTimeline;
- (void)cacheTimeline;

//
// Fetched Users Caching
//

- (void)cacheFetchedUsernames;
- (NSMutableArray *)getCachedFetchedUsernames;
- (void)cacheFetchedFacebookFriends;
- (NSMutableDictionary *)getCachedFetchedFacebookFriends;

//
// Keychain
//

@property (strong, nonatomic) KeychainItemWrapper *keychain;

- (void)resetKeychain;


//
// Dropbox Sync
//

@property (strong, nonatomic) DBRestClient *restClient;

- (void)dropboxSync;
- (void)resetDropboxSync;

@end
