//
//  AppDelegate.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/3/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "AppDelegate.h"
#import "FHSTwitterEngine.h"

@interface AppDelegate () <DBRestClientDelegate, DBSessionDelegate, FHSTwitterEngineAccessTokenDelegate, FHSFacebookDelegate>

@end

@implementation AppDelegate

- (void)reloadMainTableView {
    [[NSNotificationCenter defaultCenter]postNotificationName:@"reloadTableView" object:nil];
}

// Redo with NSPredicates
- (void)removeFacebookFromTimeline {
    [[[Cache sharedCache]timeline]filterUsingPredicate:[NSPredicate predicateWithFormat:@"class != %@",[Status class]]];
    
   /* NSMutableArray *timeline = [[Cache sharedCache]timeline];
    
    [timeline filterUsingPredicate:[NSPredicate predicateWithFormat:@"class != Status"]];
    
    for (NSDictionary *dict in timeline) {
        if ([dict[@"social_network_name"] isEqualToString:@"facebook"]) {
            [[[Cache sharedCache]timeline]removeObject:dict];
        }
    }*/
}

- (void)removeTwitterFromTimeline {
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

- (void)showSuccessHUDWithCompletedTitle:(BOOL)shouldSayCompleted {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.window animated:YES];
    hud.mode = MBProgressHUDModeCustomView;
    hud.labelText = shouldSayCompleted?@"Completed":@"Success";
    hud.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Checkmark"]];
    [hud hide:YES afterDelay:1.5];
}

- (void)showHUDWithTitle:(NSString *)title {
    [MBProgressHUD hideAllHUDsForView:self.window animated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.window animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = title;
}

- (void)hideHUD {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [MBProgressHUD hideAllHUDsForView:self.window animated:YES];
}

- (void)setTitleOfVisibleHUD:(NSString *)newTitle {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.window];
    hud.labelText = newTitle;
}

- (void)showSelfHidingHudWithTitle:(NSString *)title {
    [MBProgressHUD hideAllHUDsForView:self.window animated:YES];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.window animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = title;
    [hud hide:YES afterDelay:1.5];
}

//
// Facebook
//

- (void)facebookDidExtendAccessToken {
    [self saveFBAccessToken:FHSFacebook.shared.accessToken andExpirationDate:FHSFacebook.shared.expirationDate];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"FBButtonNotif" object:nil];
}

- (void)facebookDidLogin {
    [self saveFBAccessToken:FHSFacebook.shared.accessToken andExpirationDate:FHSFacebook.shared.expirationDate];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"FBButtonNotif" object:nil];
}

- (void)facebookDidNotLogin:(BOOL)cancelled {
    if (!cancelled) {
        [self clearFriends];
     //   [self clearFBAccessToken];
        qAlert(@"Login Failed", @"Please try again.");
    }
}

- (void)clearFBAccessToken {
    [Keychain removeObjectForKey:kFacebookAccessTokenKey];
}

/*- (void)tryLoginFromSavedCreds {
    if (FHSFacebook.shared.isSessionValid) {
        return;
    }
    
    NSDictionary *creds = [Keychain objectForKey:kFacebookAccessTokenKey];
    FHSFacebook.shared.accessToken = creds[@"access_token"];
    FHSFacebook.shared.expirationDate = creds[@"expiration_date"];
    FHSFacebook.shared.tokenDate = creds[@"token_date"];
    FHSFacebook.shared.user = [FacebookUser facebookUserWithDictionary:creds[@"user"]];
}*/

- (void)saveFBAccessToken:(NSString *)accessToken andExpirationDate:(NSDate *)date {
    [Keychain setObject:@{@"access_token": accessToken, @"expiration_date": date } forKey:kFacebookAccessTokenKey];
}

- (void)logoutFacebook {
    [self clearFBAccessToken];
    [self clearFriends];
    [FHSFacebook.shared invalidateSession];
}

- (void)loginFacebook {
    if (!FHSFacebook.shared.isSessionValid) {
        [FHSFacebook.shared authorizeWithPermissions:@[@"read_stream", @"friends_status", @"publish_stream", @"friends_photos", @"user_photos", @"friends_online_presence",  @"user_online_presence"]];
    }
}

- (void)clearFriends {
    [[[Cache sharedCache]facebookFriends]removeAllObjects];
}

//
// FHSTwitterEngine access token delegate methods
//

- (NSString *)loadAccessToken {
    return [Keychain objectForKey:kTwitterAccessTokenKey];
}

- (void)storeAccessToken:(NSString *)accessToken {
    [Keychain setObject:accessToken forKey:kTwitterAccessTokenKey];
}


//
// Dropbox
//

- (void)restClient:(DBRestClient*)client loadedAccountInfo:(DBAccountInfo *)info {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[NSNotificationCenter defaultCenter]postNotificationName:@"dropboxLoggedInUser" object:info.displayName];
}

- (void)restClient:(DBRestClient *)client loadAccountInfoFailedWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([FHSTwitterEngine isConnectedToInternet]) {
        qAlert(@"Authorization Failure", @"Please verify your login credentials and retry login.");
    } else {
        qAlert(@"Authorization Failure", @"Please check your internet connection and retry login.");
    }
}

//
//
// AppDelegate
//
//
	
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen]bounds]];
    self.viewController = [[ViewController alloc]init];
    _window.rootViewController = _viewController;
    [_window makeKeyAndVisible];

    [[Cache sharedCache]loadCaches];
    
    [FHSFacebook.shared setAppID:@"314352998657355"];
    [FHSFacebook.shared setDelegate:self];
    
    [[FHSTwitterEngine sharedEngine]permanentlySetConsumerKey:kOAuthConsumerKey andSecret:kOAuthConsumerSecret];
    [[FHSTwitterEngine sharedEngine]setDelegate:self];
    
    if (![[FHSTwitterEngine sharedEngine]isAuthorized]) {
        [[FHSTwitterEngine sharedEngine]loadAccessToken];
    }
    
    if ([[Cache sharedCache]timeline].count > 0) {
        if (!FHSFacebook.shared.isSessionValid) {
            [self removeFacebookFromTimeline];
        }
        
        if (![[FHSTwitterEngine sharedEngine]isAuthorized]) {
            [self removeTwitterFromTimeline];
        }
    }
    
    [FHSFacebook.shared extendAccessTokenIfNeeded];
    
    DBSession *session = [[DBSession alloc]initWithAppKey:@"9fxkta36zv81dc6" appSecret:@"6xbgfmggidmb66a" root:kDBRootAppFolder];
	session.delegate = self;
	[DBSession setSharedSession:session];

    self.restClient = [[DBRestClient alloc]initWithSession:[DBSession sharedSession]];
    _restClient.delegate = self;
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[url.scheme substringToIndex:2]isEqualToString:@"fb"]) {
        return [FHSFacebook.shared handleOpenURL:url];
    } else {
        if ([[DBSession sharedSession]handleOpenURL:url]) {
            if ([[DBSession sharedSession]isLinked]) {
                [_restClient loadAccountInfo];
            }
            return YES;
        }
        return NO;
    }
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[Cache sharedCache]cache];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter]postNotificationName:kEnteringForegroundNotif object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
}

@end
