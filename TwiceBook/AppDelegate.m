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

//
// Facebook
//

- (void)facebookDidExtendAccessToken {
    [[NSNotificationCenter defaultCenter]postNotificationName:@"FBButtonNotif" object:nil];
}

- (void)facebookDidLogin {
    [[NSNotificationCenter defaultCenter]postNotificationName:@"FBButtonNotif" object:nil];
}

- (void)facebookDidNotLogin:(BOOL)cancelled {
    if (!cancelled) {
        [self logoutFacebook];
        qAlert(@"Login Failed", @"Please try logging into Facebook again later.");
    }
}

- (void)logoutFacebook {
    [Core.shared cacheFacebookDicts:nil];
    [FHSFacebook.shared invalidateSession];
}

- (void)loginFacebook {
    if (!FHSFacebook.shared.isSessionValid) {
        [FHSFacebook.shared authorizeWithPermissions:@[@"read_stream", @"friends_status", @"publish_stream", @"friends_photos", @"user_photos", @"friends_online_presence",  @"user_online_presence"]];
    }
}

//
// FHSTwitterEngine access token delegate methods
//

- (NSString *)loadAccessToken {
    return Keychain.shared[kTwitterAccessTokenKey];
}

- (void)storeAccessToken:(NSString *)accessToken {
    Keychain.shared[kTwitterAccessTokenKey] = accessToken;
}

//
// Dropbox
//

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    qAlert(@"Authorization Failure", FHSTwitterEngine.isConnectedToInternet?@"Please verify your login credentials and retry login.":@"Please check your internet connection and retry login.");
}

//
// AppDelegate
//

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc]initWithFrame:UIScreen.mainScreen.bounds];
    self.viewController = [[ViewController alloc]init];
    _window.rootViewController = _viewController;
    [_window makeKeyAndVisible];
    
    [FHSFacebook.shared setAppID:@"314352998657355"];
    [FHSFacebook.shared setDelegate:self];
    
    [[FHSTwitterEngine sharedEngine]permanentlySetConsumerKey:kOAuthConsumerKey andSecret:kOAuthConsumerSecret];
    [[FHSTwitterEngine sharedEngine]setDelegate:self];
    
    if (!FHSTwitterEngine.sharedEngine.isAuthorized) {
        [FHSTwitterEngine.sharedEngine loadAccessToken];
    }
    
    if (Core.shared.timeline.count > 0) {
        if (!FHSFacebook.shared.isSessionValid) {
            [Settings removeFacebookFromTimeline];
        }
        
        if (!FHSTwitterEngine.sharedEngine.isAuthorized) {
            [Settings removeTwitterFromTimeline];
        }
    }
    
    [FHSFacebook.shared extendAccessTokenIfNeeded];
    
    DBSession *session = [[DBSession alloc]initWithAppKey:@"9fxkta36zv81dc6" appSecret:@"6xbgfmggidmb66a" root:kDBRootAppFolder];
	session.delegate = self;
	[DBSession setSharedSession:session];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[url.scheme substringToIndex:2]isEqualToString:@"fb"]) {
        return [FHSFacebook.shared handleOpenURL:url];
    } else {
        if ([DBSession.sharedSession handleOpenURL:url]) {
            if (DBSession.sharedSession.isLinked) {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                [DroppinBadassBlocks loadAccountInfoWithCompletionBlock:^(DBAccountInfo *info, NSError *error) {
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    if (!error) {
                        [[NSNotificationCenter defaultCenter]postNotificationName:@"dropboxLoggedInUser" object:info.displayName];
                    }
                }];
            }
            return YES;
        }
        return NO;
    }
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [Core.shared cache];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [FHSFacebook.shared extendAccessTokenIfNeeded];
    [[NSNotificationCenter defaultCenter]postNotificationName:kEnteringForegroundNotif object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [Core.shared cache];
}

@end
