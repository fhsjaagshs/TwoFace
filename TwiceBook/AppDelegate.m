//
//  AppDelegate.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/3/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate

- (void)reloadMainTableView {
    [[NSNotificationCenter defaultCenter]postNotificationName:@"reloadTableView" object:nil];
}

- (void)removeFacebookFromTimeline {
    NSMutableArray *timeline = [[Cache sharedCache]timeline];
    
    for (NSDictionary *dict in timeline) {
        if ([[dict objectForKey:@"social_network_name"] isEqualToString:@"facebook"]) {
            [[[Cache sharedCache]timeline]removeObject:dict];
        }
    }
}

- (void)removeTwitterFromTimeline {

    NSMutableArray *timeline = [[Cache sharedCache]timeline];
    
    for (NSDictionary *dict in timeline) {
        if ([[dict objectForKey:@"social_network_name"] isEqualToString:@"twitter"]) {
            [[[Cache sharedCache]timeline]removeObject:dict];
        }
    }
}

- (void)makeSureUsernameListArraysAreNotNil {
    
    NSMutableArray *blankArray = [NSMutableArray array];
    NSMutableDictionary *blankDict = [NSMutableDictionary dictionary];
    
    if ([Settings dropboxDeletedFacebookDictionary].allKeys.count == 0) {
        [[NSUserDefaults standardUserDefaults]setObject:blankDict forKey:kDBSyncDeletedFBDictKey];
    }
    
    if ([Settings dropboxDeletedTwitterArray].count == 0) {
        [[NSUserDefaults standardUserDefaults]setObject:blankArray forKey:kDBSyncDeletedTArrayKey];
    }

    if ([Settings selectedFacebookFriends].allKeys.count == 0) {
        [[NSUserDefaults standardUserDefaults]setObject:blankDict forKey:kSelectedFriendsDictionaryKey];
    }
    
    if ([Settings addedTwitterUsernames].count == 0) {
        [[NSUserDefaults standardUserDefaults]setObject:blankArray forKey:kAddedUsernamesListKey];
    }

    if ([Settings selectedTwitterUsernames].count == 0) {
        [[NSUserDefaults standardUserDefaults]setObject:blankArray forKey:kSelectedUsernamesListKey];
    }
}


//
// HUD management Methods
//

- (void)showSuccessHUDWithCompletedTitle:(BOOL)shouldSayCompleted {
    UIImage *checkmarkImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"Checkmark" ofType:@"png"]];
    UIImageView *checkmark = [[UIImageView alloc]initWithImage:checkmarkImage];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.window animated:YES];
    hud.mode = MBProgressHUDModeCustomView;
    hud.labelText = shouldSayCompleted?@"Completed":@"Success";
    hud.customView = checkmark;
    [hud hide:YES afterDelay:1.5];
}

- (void)showHUDWithTitle:(NSString *)title {
    [self hideHUD];
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
    [self hideHUD];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.window animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = title;
    [hud hide:YES afterDelay:1.5];
}


//
// Facebook
//

- (void)clearSavedToken {
    [[Keychain sharedKeychain]setObject:@"" forKey:(__bridge id)kSecValueData];
}

- (void)tryLoginFromSavedCreds {
    if ([self.facebook isSessionValid]) {
        return;
    }

    NSString *keychainData = (NSString *)[[Keychain sharedKeychain]objectForKey:(__bridge id)kSecValueData];
    NSArray *components = [keychainData componentsSeparatedByString:@" "];
    
    if (components.count < 2) {
        return;
    }
    
    NSTimeInterval sinceUNIXEpoch = [(NSString *)[components objectAtIndex:1]doubleValue];
    
    NSString *accessToken = (NSString *)[components objectAtIndex:0];
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSince1970:sinceUNIXEpoch];

    if (accessToken && expirationDate) {
        _facebook.accessToken = accessToken;
        _facebook.expirationDate = expirationDate;
    }
}

- (void)saveAccessToken:(NSString *)accessToken andExpirationDate:(NSDate *)date {
    NSTimeInterval sinceUNIXEpoch = [date timeIntervalSince1970];
    NSString *dateString = [NSString stringWithFormat:@"%f",sinceUNIXEpoch];
    NSString *finalString = [NSString stringWithFormat:@"%@ %@",accessToken,dateString];
    [[Keychain sharedKeychain]setObject:finalString forKey:(__bridge id)kSecValueData];
}

- (void)logoutFacebook {
    [self clearSavedToken];
    [self clearFriends];
    [self.facebook logout:self];
}

- (void)loginFacebook {
    
    if ([self.facebook isSessionValid]) {
        return;
    }
    
    [self tryLoginFromSavedCreds];
    
    if (![self.facebook isSessionValid]) {
        [self.facebook authorize:[NSArray arrayWithObjects:@"read_stream", @"friends_status", @"publish_stream", @"friends_photos", @"user_photos", @"friends_online_presence",  @"user_online_presence", nil]];
    } 
}

- (void)startFacebook {
    self.facebook = [[Facebook alloc]initWithAppId:@"314352998657355" andDelegate:self];
    [self tryLoginFromSavedCreds];
}

- (void)clearFriends {
    [[[Cache sharedCache]facebookFriends]removeAllObjects];
}

- (NSString *)getFacebookUsernameSync {
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@",self.facebook.accessToken]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSError *err = nil;
    NSURLResponse *resp = nil;
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:&err];
    
    if (resp != nil && err == nil) {
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableContainers error:nil];
        return [responseDict objectForKey:@"name"];
    }
    
    return @"";
}

- (void)fbDidNotLogin:(BOOL)cancelled {
    [self clearFriends];
    [self clearSavedToken];
    if (!cancelled) {
        qAlert(@"Login Failed", @"Please try again.");
    }
}

- (void)fbDidLogin {
    [self saveAccessToken:self.facebook.accessToken andExpirationDate:self.facebook.expirationDate];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"FBButtonNotif" object:nil];
}

- (void)fbDidLogout {
    [self clearFriends];
    [self clearSavedToken];
}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {
    [self saveAccessToken:accessToken andExpirationDate:expiresAt];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"FBButtonNotif" object:nil];
}

- (void)fbSessionInvalidated {
    [self hideHUD];
    [self clearSavedToken];
    [self clearFriends];
    
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Facebook Login Expired" message:@"Do you wish to reauthenticate?" completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        if (buttonIndex == 0) {
            [self loginFacebook];
        }
    } cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [av show];
}

- (NSDictionary*)parseURLParams:(NSString *)query {
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
    return params;
}


//
// FHSTwitterEngine access token delegate methods
//

- (NSString *)loadAccessToken {
    return (NSString *)[[Keychain sharedKeychain]objectForKey:(__bridge id)kSecAttrAccount];
}

- (void)storeAccessToken:(NSString *)accessToken {
    [[Keychain sharedKeychain]setObject:accessToken forKey:(__bridge id)kSecAttrAccount];
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

- (void)uploadSyncFile {
    [self.restClient uploadFile:@"selectedUsernameSync.plist" toPath:@"/" withParentRev:savedRev fromPath:[[Settings documentsDirectory]stringByAppendingPathComponent:@"selectedUsernameSync.plist"]];
}

- (void)downloadSyncFile {
    [self.restClient loadFile:@"/selectedUsernameSync.plist" intoPath:[[Settings documentsDirectory]stringByAppendingPathComponent:@"selectedUsernameSync.plist"]];
}

- (NSMutableDictionary *)getSyncDict {
    return [NSMutableDictionary dictionaryWithContentsOfFile:[[Settings documentsDirectory]stringByAppendingPathComponent:@"selectedUsernameSync.plist"]];
}

- (void)checkForSyncingFile {
    NSString *path = [[Settings documentsDirectory]stringByAppendingPathComponent:@"selectedUsernameSync.plist"];
    if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]createFileAtPath:path contents:nil attributes:nil];
    }
}

- (void)mainSyncStep {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableDictionary *cloudData = [self getSyncDict];
    
    if (cloudData.allKeys.count == 0) {
        cloudData = [[NSMutableDictionary alloc]init];
    }
    
    id fdc = [cloudData objectForKey:kSelectedFriendsDictionaryKey];
    id autc = [cloudData objectForKey:kAddedUsernamesListKey];
    id utc = [cloudData objectForKey:kSelectedUsernamesListKey];
    id ddc = [cloudData objectForKey:@"deleted_dict_facebook"];
    id dac = [cloudData objectForKey:@"deleted_array_twitter"];
    
    id fdl = [defaults objectForKey:kSelectedFriendsDictionaryKey];
    id autl = [defaults objectForKey:kAddedUsernamesListKey];
    id utl = [defaults objectForKey:kSelectedUsernamesListKey];
    
    
    //
    // Facebook Selected Friends
    //
    
    NSMutableDictionary *remoteFriendsDict = [[NSMutableDictionary alloc]initWithDictionary:(NSMutableDictionary *)fdc];
    NSMutableDictionary *localFriendsDict = [[NSMutableDictionary alloc]initWithDictionary:(NSMutableDictionary *)fdl];
    NSMutableDictionary *cloudDeletionDict = [[NSMutableDictionary alloc]initWithDictionary:(NSMutableDictionary *)ddc]; // from sync-before-this-sync

    NSMutableDictionary *deleteDict = [Settings dropboxDeletedFacebookDictionary];

    for (id key in cloudDeletionDict.allKeys) {
        [localFriendsDict removeObjectForKey:key];
        if ([remoteFriendsDict.allKeys containsObject:key]) {
            [remoteFriendsDict removeObjectForKey:key];
        }
    }
    
    for (id key in deleteDict.allKeys) {
        [remoteFriendsDict removeObjectForKey:key];
        if ([localFriendsDict.allKeys containsObject:key]) {
            [localFriendsDict removeObjectForKey:key];
        }
    }
    
    [cloudDeletionDict removeAllObjects];
    
    [cloudDeletionDict addEntriesFromDictionary:deleteDict];
    
    [cloudData setObject:cloudDeletionDict forKey:@"deleted_dict_facebook"];
    
    [deleteDict removeAllObjects];
    [[NSUserDefaults standardUserDefaults]setObject:deleteDict forKey:kDBSyncDeletedFBDictKey];
    
    NSMutableDictionary *combinedDict = [[NSMutableDictionary alloc]init];
    [combinedDict addEntriesFromDictionary:remoteFriendsDict];
    [combinedDict addEntriesFromDictionary:localFriendsDict];
    
    [cloudData setObject:combinedDict forKey:kSelectedFriendsDictionaryKey];
    [defaults setObject:combinedDict forKey:kSelectedFriendsDictionaryKey];

    //
    // Twitter Added Users
    //
    
    NSMutableArray *combinedArray = [[NSMutableArray alloc]init];
    NSMutableArray *autcA = [[NSMutableArray alloc]initWithArray:(NSMutableArray *)autc];
    NSMutableArray *autlA = [[NSMutableArray alloc]initWithArray:(NSMutableArray *)autl];
    
    NSMutableArray *deleteArray = [Settings dropboxDeletedTwitterArray];
    
    NSMutableArray *cloudDeleteArray = [[NSMutableArray alloc]initWithArray:(NSMutableArray *)dac];
    
    for (id obj in deleteArray) {
        if ([autcA containsObject:obj]) {
            [autcA removeObject:obj];
        }
    }
    
    for (id obj in cloudDeleteArray) {
        if ([autlA containsObject:obj]) {
            [autlA removeObject:obj];
        }
    }
    
    [combinedArray addObjectsFromArray:autcA];
    [combinedArray addObjectsFromArray:autlA];
    
    NSMutableArray *finalArray = [[NSMutableArray alloc]init];
    
    for (id obj in combinedArray) {
        if (![finalArray containsObject:obj]) {
            [finalArray addObject:obj];
        }
    }
    
    [cloudData setObject:finalArray forKey:kAddedUsernamesListKey];
    [defaults setObject:finalArray forKey:kAddedUsernamesListKey];
    
    //
    // Twitter Selected Users
    //
    
    NSMutableArray *combinedArrayF = [NSMutableArray array];
    
    NSMutableArray *selectedUsersTCloud = [NSMutableArray arrayWithArray:(NSMutableArray *)utc];
    NSMutableArray *selectedUsersTLocal = [NSMutableArray arrayWithArray:(NSMutableArray *)utl];
    
    for (id obj in deleteArray) {
        if ([selectedUsersTCloud containsObject:obj]) {
            [selectedUsersTCloud removeObject:obj];
        }
    }
    
    for (id obj in cloudDeleteArray) {
        if ([selectedUsersTLocal containsObject:obj]) {
            [selectedUsersTLocal removeObject:obj];
        }
    }
    
    [cloudDeleteArray removeAllObjects];
    [cloudDeleteArray addObjectsFromArray:deleteArray];
    [cloudData setObject:cloudDeleteArray forKey:@"deleted_array_twitter"];
    
    [deleteArray removeAllObjects];
    [[NSUserDefaults standardUserDefaults]setObject:deleteArray forKey:kDBSyncDeletedTArrayKey];
    
    [combinedArrayF addObjectsFromArray:selectedUsersTCloud];
    [combinedArrayF addObjectsFromArray:selectedUsersTLocal];
    
    NSMutableArray *finalArrayF = [[NSMutableArray alloc]init];
    
    for (id obj in combinedArrayF) {
        if (![finalArrayF containsObject:obj]) {
            [finalArrayF addObject:obj];
        }
    }
    
    [cloudData setObject:finalArrayF forKey:@"usernames_twitter"];
    [defaults setObject:finalArrayF forKey:@"usernames_twitter"];

    [defaults synchronize];
    [cloudData writeToFile:[[Settings documentsDirectory]stringByAppendingPathComponent:@"selectedUsernameSync.plist"] atomically:YES];
    [self uploadSyncFile];
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath {
    [self hideHUD];
    savedRev = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSDate *date = [NSDate date];
    [[NSUserDefaults standardUserDefaults]setObject:date forKey:@"lastSyncedDateKey"];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"lastSynced" object:nil];
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    [self hideHUD];
    savedRev = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    qAlert(@"Syncing Error", @"TwoFace failed to sync your selected users.");
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath {
    [self mainSyncStep];
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    [self hideHUD];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    qAlert(@"Syncing Error", @"TwoFace failed to sync your selected users.");
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {

    NSMutableArray *filenames = [[NSMutableArray alloc]init];
    
    for (DBMetadata *item in metadata.contents) {
        NSString *theFileName = item.filename;
        [filenames addObject:theFileName];
        if ([theFileName isEqualToString:@"selectedUsernameSync.plist"]) {
            savedRev = item.rev;
        }
    }
    
    [[NSFileManager defaultManager]removeItemAtPath:[[Settings documentsDirectory] stringByAppendingPathComponent:@"selectedUsernameSync.plist"] error:nil];
    
    if ([filenames containsObject:@"selectedUsernameSync.plist"]) {
        [self checkForSyncingFile]; // makes sure that the selectedUsernameSync.plist is there
        [self downloadSyncFile];
    } else {
        [self mainSyncStep];
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    [self hideHUD];
    [[NSFileManager defaultManager]removeItemAtPath:[[Settings documentsDirectory]stringByAppendingPathComponent:@"selectedUsernameSync.plist"] error:nil];
    qAlert(@"Syncing Error", @"TwoFace failed to sync your selected users.");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)restClient:(DBRestClient *)client deletedPath:(NSString *)path {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self hideHUD];
}

- (void)restClient:(DBRestClient *)client deletePathFailedWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self hideHUD];
    if (error.code != 404) {
        [[NSFileManager defaultManager]removeItemAtPath:[[Settings documentsDirectory]stringByAppendingPathComponent:@"selectedUsernameSync.plist"] error:nil];
        qAlert(@"Error Resetting Dropbox Sync", @"TwoFace failed to delete the data stored on Dropbox.");
    }
}

- (void)dropboxSync {
    [self showHUDWithTitle:@"Syncing..."];
    [self.restClient loadMetadata:@"/"];
}

- (void)resetDropboxSync {
    [self showHUDWithTitle:@"Resetting Sync..."];
    [[NSUserDefaults standardUserDefaults]setObject:[[NSMutableArray alloc]init] forKey:kDBSyncDeletedTArrayKey];
    [[NSUserDefaults standardUserDefaults]setObject:[[NSMutableDictionary alloc]init] forKey:kDBSyncDeletedFBDictKey];
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"lastSyncedDateKey"];
    [self.restClient deletePath:@"/selectedUsernameSync.plist"];
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
    
    [self makeSureUsernameListArraysAreNotNil];
    [[Cache sharedCache]loadCaches];
    
    self.window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen]bounds]];
    self.viewController = [[ViewController alloc]init];
    _window.rootViewController = _viewController;
    [_window makeKeyAndVisible];
    
    [[Keychain sharedKeychain]setIdentifier:@"TwoFaceID"];
    
    [[FHSTwitterEngine sharedEngine]permanentlySetConsumerKey:kOAuthConsumerKey andSecret:kOAuthConsumerSecret];
    [[FHSTwitterEngine sharedEngine]setDelegate:self];
    
    DBSession *session = [[DBSession alloc]initWithAppKey:@"9fxkta36zv81dc6" appSecret:@"6xbgfmggidmb66a" root:kDBRootAppFolder];
	session.delegate = self;
	[DBSession setSharedSession:session];

    self.restClient = [[DBRestClient alloc]initWithSession:[DBSession sharedSession]];
    _restClient.delegate = self;
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if ([[[url scheme]substringToIndex:2]isEqualToString:@"fb"]) {
        return [self.facebook handleOpenURL:url];
    } else {
        if ([[DBSession sharedSession]handleOpenURL:url]) {
            if ([[DBSession sharedSession]isLinked]) {
                [self.restClient loadAccountInfo];
            }
            return YES;
        }
        return NO;
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[Cache sharedCache]cache];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    if (![[FHSTwitterEngine sharedEngine]isAuthorized]) {
        [[FHSTwitterEngine sharedEngine]loadAccessToken];
    }
    
    if (![self.facebook isSessionValid]) {
        [self tryLoginFromSavedCreds];
    }
    [[NSNotificationCenter defaultCenter]postNotificationName:kEnteringForegroundNotif object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
}

@end
