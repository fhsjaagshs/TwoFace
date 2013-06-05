//
//  AppDelegate.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/3/12.
//  Copyright (c) 2012 Nawthaniel Symer. All rights reserved.
//

// Potential New name: PrimaFacie

#import <UIKit/UIKit.h>

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

- (void)makeSureUsernameListArraysAreNotNil; // Probs gonna be replaced by something in the cache
- (void)reloadMainTableView;

//
// Facebook
//

// HUD View methods
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
// Dropbox Sync
//

@property (strong, nonatomic) DBRestClient *restClient;

- (void)dropboxSync;
- (void)resetDropboxSync;

@end
