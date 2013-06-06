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

- (void)reloadMainTableView;

// HUD View methods
- (void)showHUDWithTitle:(NSString *)title;
- (void)hideHUD;
- (void)setTitleOfVisibleHUD:(NSString *)newTitle;
- (void)showSelfHidingHudWithTitle:(NSString *)title;
- (void)showSuccessHUDWithCompletedTitle:(BOOL)shouldSayCompleted;

// Facebook
@property (strong, nonatomic) Facebook *facebook;

- (void)loginFacebook;
- (void)logoutFacebook;
- (void)startFacebook;
- (void)tryLoginFromSavedCreds;
- (NSString *)getFacebookUsernameSync;

// Timeline management
- (void)removeFacebookFromTimeline;
- (void)removeTwitterFromTimeline;

// Dropbox Sync
@property (strong, nonatomic) DBRestClient *restClient;

- (void)dropboxSync;
- (void)resetDropboxSync;

@end
