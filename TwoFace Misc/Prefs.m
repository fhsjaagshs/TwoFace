//
//  Prefs.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/3/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "Prefs.h"

@implementation Prefs

@synthesize twitterSigninButton, facebookSigninButton, twitterNameLabel, facebookNameLabel;

- (IBAction)showTwitterAuth:(id)sender {
    AppDelegate *ad = kAppDelegate;
    
    if ([ad.engine isAuthorized]) {
        // logout
        [ad.theFetchedUsernames removeAllObjects];
        [ad cacheFetchedUsernames];
        [ad.engine clearAccessToken];
        [ad removeTwitterFromTimeline];
        [twitterSigninButton setTitle:@"Sign into Twitter" forState:UIControlStateNormal];
        [ad reloadMainTableView];
    } else {
        // login
        [ad.engine clearAccessToken];
        [ad.engine showOAuthLoginControllerFromViewController:self];
    }
    [self setTwitterNameLabelText];
}

- (IBAction)clearCaches {
    [kAppDelegate clearImageCache];
}

- (IBAction)showFriendSelector {
    IntermediateUserSelectorViewController *iusvc = [[IntermediateUserSelectorViewController alloc]initWithAutoNib];
    [self presentModalViewController:iusvc animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    AppDelegate *ad = kAppDelegate;
    
    if ([ad.engine isAuthorized]) {
        [twitterSigninButton setTitle:@"Log out of Twitter" forState:UIControlStateNormal];
    } else {
        [twitterSigninButton setTitle:@"Sign into Twitter" forState:UIControlStateNormal];
    }
    
    if ([ad.facebook isSessionValid]) {
        [facebookSigninButton setTitle:@"Log out of Facebook" forState:UIControlStateNormal];
    } else {
        [facebookSigninButton setTitle:@"Sign into Facebook" forState:UIControlStateNormal];
    }
    
    if (facebookNameLabel.text.length == 0) {
        [self setFacebookNameLabelText];
    }
    
    [self setTwitterNameLabelText];
}

- (IBAction)signinFacebook:(id)sender {
    AppDelegate *ad = kAppDelegate;
    
    BOOL isLoggedIn = [ad.facebook isSessionValid];
    if (isLoggedIn) {
        [facebookSigninButton setTitle:@"Sign into Facebook" forState:UIControlStateNormal];
        [ad logoutFacebook];
        [ad removeFacebookFromTimeline];
        [ad reloadMainTableView];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"fbName"];
        [facebookNameLabel setText:@""];
        isAlreadyGettingName = NO;
    } else {
        [ad loginFacebook];
    }
}

- (IBAction)showSyncMenu {
    SyncingViewController *ics = [[SyncingViewController alloc]initWithAutoNib];
    [self presentModalViewController:ics animated:YES];
}

- (IBAction)close:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"FBButtonNotif" object:nil];
}

- (void)refreshFacebookButton {

    if ([[kAppDelegate facebook] isSessionValid]) {
        [facebookSigninButton setTitle:@"Log out of Facebook" forState:UIControlStateNormal];
        [self setFacebookNameLabelText];
    } else {
        [facebookSigninButton setTitle:@"Sign into Facebook" forState:UIControlStateNormal];
        [facebookNameLabel setText:@""];
        isAlreadyGettingName = NO;
    }
}

- (void)setFacebookNameLabelText {
    NSString *fbUsername = [[NSUserDefaults standardUserDefaults]objectForKey:@"fbName"];
    if (fbUsername == nil || fbUsername.length == 0) {
        [facebookNameLabel setText:@""];
        dispatch_async(GCDBackgroundThread, ^{
            @autoreleasepool {
                if (!isAlreadyGettingName) {
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                    NSString *theName = [kAppDelegate getFacebookUsernameSync];
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    [[NSUserDefaults standardUserDefaults]setObject:theName forKey:@"fbName"];
                    [self setFacebookNameLabelText];
                }
                isAlreadyGettingName = YES;
            }
        });
    } else {
        [facebookNameLabel setText:fbUsername];
        isAlreadyGettingName = NO;
    }
}

- (void)setTwitterNameLabelText {
    
    NSString *username = [kAppDelegate engine].loggedInUsername;
    
    if (username == nil || username.length == 0) {
        [twitterNameLabel setText:@""];
    } else {
        [twitterNameLabel setText:[NSString stringWithFormat:@"@%@",username]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refreshFacebookButton) name:@"FBButtonNotif" object:nil];
}

@end
