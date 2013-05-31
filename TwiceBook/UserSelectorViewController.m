//
//  UserSelectorViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 1/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "UserSelectorViewController.h"

#define fqlFriendsOrdered @"SELECT name,uid,last_name FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me()) order by last_name"

@implementation UserSelectorViewController

- (id)initWithIsFacebook:(BOOL)isfacebook isImmediateSelection:(BOOL)isimdtselection {
    if (self = [super init]) {
        self.isFacebook = isfacebook;
        self.isImmediateSelection = isimdtselection;
    }
    return self;
}

- (id)initWithIsFacebook:(BOOL)isfacebook {
    if (self = [super init]) {
        self.isFacebook = isfacebook;
        self.isImmediateSelection = NO;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    [self.view setBackgroundColor:[UIColor underPageBackgroundColor]];
    self.theTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-88)];
    self.theTableView.delegate = self;
    self.theTableView.dataSource = self;
    [self.view addSubview:self.theTableView];
    [self.view bringSubviewToFront:self.theTableView];
    
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Select Users"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(back)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Reset" style:UIBarButtonItemStyleBordered target:self action:@selector(resetSelectedUsers)];
    [self.navBar pushNavigationItem:topItem animated:NO];
    
    [self.view addSubview:self.navBar];
    [self.view bringSubviewToFront:self.navBar];
    
    if (self.isImmediateSelection) {
        self.theTableView.frame = CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-44);
    } else {
        UIToolbar *bottomBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-44, screenBounds.size.width, 44)];
        
        if (!self.isFacebook) {
            UIBarButtonItem *bbi = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAddUsernameDialogue)];
            bbi.style = UIBarButtonItemStyleBordered;
            bottomBar.items = [NSArray arrayWithObjects:[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], bbi,nil];
        }
        
        [self.view addSubview:bottomBar];
        [self.view bringSubviewToFront:bottomBar];
        
        self.counter = [[UILabel alloc]initWithFrame:bottomBar.frame];
        self.counter.backgroundColor = [UIColor clearColor];
        self.counter.textAlignment = UITextAlignmentCenter;
        self.counter.textColor = [UIColor whiteColor];
        self.counter.font = [UIFont boldSystemFontOfSize:19];
        self.counter.shadowColor = [UIColor blackColor];
        self.counter.shadowOffset = CGSizeMake(0, -1);
        [self.view addSubview:self.counter];
        [self.view bringSubviewToFront:self.counter];
    }
}

// Facebook Stuff

- (void)loadCachedFriendsOrderedArray {
    self.orderedFriendsArray = [NSMutableArray arrayWithContentsOfFile:[kCachesDirectory stringByAppendingPathComponent:@"orderedFacebookFriends.plist"]];
}

- (void)cacheFriendsOrderedArray {
    NSString *loadPath = [kCachesDirectory stringByAppendingPathComponent:@"orderedFacebookFriends.plist"];
    [self.orderedFriendsArray writeToFile:loadPath atomically:YES];
}

- (void)clearFriends {
    AppDelegate *ad = kAppDelegate;
    [ad.facebookFriendsDict removeAllObjects];
    [ad cacheFetchedFacebookFriends];
    [ad removeFacebookFromTimeline];
}

- (void)loadFacebookFriends {
    
    AppDelegate *ad = kAppDelegate;

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me/fql?access_token=%@&q=%@",ad.facebook.accessToken, encodeForURL(fqlFriendsOrdered)]];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"GET"];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        [self enableButtons];

        if (error) {
            NSString *FBerr = [error localizedDescription];
            NSString *message = (FBerr.length == 0)?@"Confirm that you are logged in correctly and try again.":FBerr;
            qAlert(@"Facebook Error", message);
        } else {
            id parsedJSONResponse = removeNull([NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);
            
            AppDelegate *ad = kAppDelegate;
            
            if (self.orderedFriendsArray.count == 0) {
                self.orderedFriendsArray = [NSMutableArray array];
            }
            
            if (ad.facebookFriendsDict.allKeys.count == 0) {
                ad.facebookFriendsDict = [NSMutableDictionary dictionary];
            }
            
            if ([parsedJSONResponse isKindOfClass:[NSDictionary class]]) {
                [self clearFriends];
                
                NSArray *data = [(NSDictionary *)parsedJSONResponse objectForKey:@"data"];
                
                for (int i = 0; i < data.count; i++) {
                    NSString *username = [NSString stringWithString:[[data objectAtIndex:i]objectForKey:@"name"]];
                    
                    if ([ad.facebookFriendsDict.allValues containsObject:username]) {
                        username = [username stringByAppendingString:@" "];
                    }
                    
                    NSString *identifier = [NSString stringWithFormat:@"%@",[[data objectAtIndex:i]objectForKey:@"uid"]];
                    [ad.facebookFriendsDict setValue:username forKey:identifier];
                    
                    [self.orderedFriendsArray addObject:username];
                }
                
                [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                
                [self cacheFriendsOrderedArray];
                [ad cacheFetchedFacebookFriends];
            }
        }
    }];
}

// Twitter stuff
- (void)cacheIDtoUsernameDict:(NSDictionary *)dict {
    NSString *cachePath = [kCachesDirectory stringByAppendingPathComponent:@"twitter_username_lookup_dict.plist"];
    [dict writeToFile:cachePath atomically:YES];
}

- (NSMutableDictionary *)loadCachedUsernameLookupDict {
    return [NSMutableDictionary dictionaryWithContentsOfFile:[kCachesDirectory stringByAppendingPathComponent:@"twitter_username_lookup_dict.plist"]];
}

- (void)updateListTwitter {
    
    AppDelegate *ad = kAppDelegate;
    
    NSMutableArray *addedUsernames = addedUsernamesListArray;
    NSMutableArray *usernames = usernamesListArray;
    
    NSMutableArray *unmodifiedTwitterUsernamesList = [NSMutableArray arrayWithContentsOfFile:[kCachesDirectory stringByAppendingPathComponent:@"cached_list_twitter_friends.plist"]];

    // Update added array
    for (id object in [usernames mutableCopy]) {
        if (![unmodifiedTwitterUsernamesList containsObject:object]) {
            if (![addedUsernames containsObject:object]) {
                [addedUsernames addObject:object];
            }
        }
    }

    for (id object in [addedUsernames mutableCopy]) {
        if ([unmodifiedTwitterUsernamesList containsObject:object]) {
            [addedUsernames removeObject:object]; // its a user
        } else {
            if (![ad.theFetchedUsernames containsObject:object]) {
                [ad.theFetchedUsernames addObject:object];
            }
        }
    }
    
    [[NSUserDefaults standardUserDefaults]setObject:addedUsernames forKey:addedUsernamesListKey];
    [ad.theFetchedUsernames sortUsingSelector:@selector(caseInsensitiveCompare:)];
    [ad cacheFetchedUsernames];
}

- (void)fetchFriends {
    
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            
            AppDelegate *ad = kAppDelegate;
            id retIDs = [ad.engine getFriendsIDs];
            if ([retIDs isKindOfClass:[NSError class]]) {
                NSError *theError = (NSError *)retIDs;
                dispatch_sync(GCDMainThread, ^{
                    @autoreleasepool {
                        qAlert([NSString stringWithFormat:@"Error %d",theError.code], theError.domain);
                    }
                });
            } else if ([retIDs isKindOfClass:[NSDictionary class]]) {
                NSArray *ids = [(NSDictionary *)retIDs objectForKey:@"ids"];
                
                BOOL succeeeded = YES;
                
                NSMutableArray *usernames = [NSMutableArray array];
                NSMutableArray *idsToLookUp = [NSMutableArray array];
                NSMutableDictionary *finalCachedUsernamesDict = [NSMutableDictionary dictionary];
                NSMutableDictionary *cachedUsernamesLookupDict = [self loadCachedUsernameLookupDict];
                
                for (NSString *identifier in ids) {
                    if ([cachedUsernamesLookupDict.allKeys containsObject:identifier]) {
                        NSString *theUsernameFromCache = [cachedUsernamesLookupDict objectForKey:identifier];
                        [finalCachedUsernamesDict setObject:theUsernameFromCache forKey:identifier];
                        [usernames addObject:theUsernameFromCache];
                    } else {
                        [idsToLookUp addObject:identifier];
                    }
                }
                
                if (idsToLookUp.count > 0) {
                    NSArray *idConcatStrings = [ad.engine generateRequestStringsFromArray:idsToLookUp];
                    
                    for (NSString *idconcatstr in idConcatStrings) {
                        id usersRet = [ad.engine lookupUsers:[idconcatstr componentsSeparatedByString:@","] areIDs:YES];
                        
                        if ([usersRet isKindOfClass:[NSError class]]) {
                            NSError *theError = (NSError *)usersRet;
                            dispatch_sync(GCDMainThread, ^{
                                @autoreleasepool {
                                    qAlert([NSString stringWithFormat:@"Error %d",theError.code], theError.domain);
                                }
                            });
                            succeeeded = NO;
                            break;
                        } else if ([usersRet isKindOfClass:[NSArray class]]) {
                            NSArray *userDicts = (NSArray *)usersRet;
                            for (NSDictionary *dict in userDicts) {
                                NSString *screen_name = [dict objectForKey:@"screen_name"];
                                NSString *user_id = [dict objectForKey:@"id_str"];
                                [finalCachedUsernamesDict setObject:screen_name forKey:user_id];
                                [usernames addObject:screen_name];
                            }
                        }
                    }
                }
                
                if (succeeeded) {
                    [ad makeSureUsernameListArraysAreNotNil];
                    [ad.theFetchedUsernames removeAllObjects];
                    [ad.theFetchedUsernames addObjectsFromArray:usernames];
                    [ad.theFetchedUsernames sortUsingSelector:@selector(caseInsensitiveCompare:)];
                    [ad.theFetchedUsernames writeToFile:[kCachesDirectory stringByAppendingPathComponent:@"cached_list_twitter_friends.plist"] atomically:YES];
                    [self cacheIDtoUsernameDict:finalCachedUsernamesDict];
                }
            }
            
            dispatch_sync(GCDMainThread, ^{
                @autoreleasepool {
                    [self enableButtons];
                }
            });
        }
    });
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    
    if (![FHSTwitterEngine isConnectedToInternet]) {
        [self.pull finishedLoading];
        qAlert(@"Friends Error", @"The Internet connection appears to be offline.");
        return;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.navBar.topItem.leftBarButtonItem.enabled = NO;
    self.navBar.topItem.rightBarButtonItem.enabled = NO;
    
    if (self.isFacebook) {
        [self loadFacebookFriends];
    } else {
        [self fetchFriends];
    }
}

- (void)pullToRefreshViewWasShown:(PullToRefreshView *)view {
    [self.pull setSubtitleText:self.isFacebook?@"Facebook Friends":@"Twitter Friends"];
}

- (void)updateCounter {
    NSArray *array = self.isFacebook?[kSelectedFriendsDictionary allKeys]:usernamesListArray;
    self.counter.text = [NSString stringWithFormat:@"%d/5",array.count];
}

- (void)resetSelectedUsers {
    
    AppDelegate *ad = kAppDelegate;
    
    if (self.isFacebook) {
        NSMutableDictionary *selectedDictionary = kSelectedFriendsDictionary;
        NSMutableDictionary *deletedDictionary = kDBSyncDeletedFBDict;
        
        [deletedDictionary addEntriesFromDictionary:selectedDictionary];
        [[NSUserDefaults standardUserDefaults]setObject:deletedDictionary forKey:kDBSyncDeletedFBDictKey];
        
        [selectedDictionary removeAllObjects];
        [[NSUserDefaults standardUserDefaults]setObject:selectedDictionary forKey:kSelectedFriendsDictionaryKey];
        
        [ad removeFacebookFromTimeline];
    } else {
        NSMutableArray *usernames = usernamesListArray;
        NSMutableArray *addedUsernames = addedUsernamesListArray;
        NSMutableArray *deletedArray = kDBSyncDeletedTArray;
        
        for (id username in usernames) {
            if ([self.savedSelectedArrayTwitter containsObject:username]) {
                if (![deletedArray containsObject:username]) {
                    [deletedArray addObject:username];
                }
            }
        }
        
        [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
        
        [ad.theFetchedUsernames removeObjectsInArray:addedUsernames];
        [addedUsernames removeAllObjects];
        [[NSUserDefaults standardUserDefaults]setObject:addedUsernames forKey:addedUsernamesListKey];
        
        [usernames removeAllObjects];
        [[NSUserDefaults standardUserDefaults]setObject:usernames forKey:usernamesListKey];
        [ad removeTwitterFromTimeline];
    }
    
    [ad reloadMainTableView];
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self updateCounter];
}

- (void)showAddUsernameDialogue {
    
    NSMutableArray *usernames = usernamesListArray;

    if (usernames.count >= 5) {
        [self flashLabelWithDelay:0.0f];
        return;
    }
    
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Add User to Watch" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *avTF = [av textFieldAtIndex:0];
    [avTF setPlaceholder:@"Enter @username..."];
    [avTF setKeyboardAppearance:UIKeyboardAppearanceAlert];
    [avTF setAutocorrectionType:UITextAutocorrectionTypeNo];
    [avTF setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [avTF setReturnKeyType:UIReturnKeyGo];
    [avTF setClearButtonMode:UITextFieldViewModeWhileEditing];
    [av show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.firstOtherButtonIndex == buttonIndex) {
        [self manuallyAddUsername:[[alertView textFieldAtIndex:0]text]];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if ([alertView textFieldAtIndex:0].text.length > 0) {
        return YES;
    }
    return NO;
}

- (void)flashLabelWithDelay:(float)delay {
    [self.counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:delay];
    [self.counter performSelector:@selector(setTextColor:) withObject:[UIColor whiteColor] afterDelay:delay+0.1];
    [self.counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:delay+0.2];
    [self.counter performSelector:@selector(setTextColor:) withObject:[UIColor whiteColor] afterDelay:delay+0.3];
    [self.counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:delay+0.4];
    [self.counter performSelector:@selector(setTextColor:) withObject:[UIColor whiteColor] afterDelay:delay+0.5];
}

- (void)manuallyAddUsername:(NSString *)username {
    
    if (username.length == 0) {
        return;
    }

    NSMutableArray *usernames = usernamesListArray;
    
    if (usernames.count < 5) {
        
        NSString *usernameToAdd = [username copy];
        
        if ([usernameToAdd hasPrefix:@"@"]) {
            usernameToAdd = [usernameToAdd substringFromIndex:1];
        }
        
        AppDelegate *ad = kAppDelegate;
        
        NSMutableArray *deletedArray = kDBSyncDeletedTArray;
        if ([deletedArray containsObject:usernameToAdd]) {
            [deletedArray removeObject:usernameToAdd];
            [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
        }

        if (![ad.theFetchedUsernames containsObject:usernameToAdd]) {
            NSMutableArray *addedUsernames = addedUsernamesListArray;
            [addedUsernames addObject:usernameToAdd];
            [[NSUserDefaults standardUserDefaults]setObject:addedUsernames forKey:addedUsernamesListKey];
            [ad.theFetchedUsernames addObject:usernameToAdd];
            [ad.theFetchedUsernames sortUsingSelector:@selector(caseInsensitiveCompare:)];
        }
        
        if (![usernames containsObject:usernameToAdd]) {
            [usernames addObject:usernameToAdd];
            [[NSUserDefaults standardUserDefaults]setObject:usernames forKey:usernamesListKey];
        }
        
        [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        
    } else {
        [self flashLabelWithDelay:0.0f];
    }
    [self updateCounter];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    AppDelegate *ad = kAppDelegate;
    int count = self.isFacebook?ad.facebookFriendsDict.allKeys.count:ad.theFetchedUsernames.count;
    return (count > 0)?count:1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellUS";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    AppDelegate *ad = kAppDelegate;

    if (self.isFacebook) {
        
        NSDictionary *selectedDictionary = kSelectedFriendsDictionary;

        if (self.orderedFriendsArray.count == 0) {
            self.orderedFriendsArray = [NSMutableArray array];
            if (ad.facebookFriendsDict.allValues.count == 0) {
                ad.facebookFriendsDict = [NSMutableDictionary dictionary];
            }
            cell.textLabel.text = @"No friends loaded...";
            return cell;
        }
        
        if (ad.facebookFriendsDict.allValues.count == 0) {
            if (self.orderedFriendsArray.count == 0) {
                self.orderedFriendsArray = [NSMutableArray array];
            }
            ad.facebookFriendsDict = [NSMutableDictionary dictionary];
            cell.textLabel.text = @"No friends loaded...";
            return cell;
        }
        
        NSString *theValue = [self.orderedFriendsArray objectAtIndex:indexPath.row];
        int indexOfKey = [ad.facebookFriendsDict.allValues indexOfObject:theValue];
        
        if ([ad.facebookFriendsDict.allValues containsObject:theValue]) {
            if (indexOfKey < INT_MAX) {
                NSString *secondValue = [ad.facebookFriendsDict.allKeys objectAtIndex:indexOfKey];
                if ([selectedDictionary.allKeys containsObject:secondValue]) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
        }
        cell.textLabel.text = theValue;
    } else {
        
        if (ad.theFetchedUsernames.count == 0) {
            ad.theFetchedUsernames = [NSMutableArray array];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = @"No usernames loaded...";
            return cell;
        }
        
        NSString *username = [ad.theFetchedUsernames objectAtIndex:indexPath.row];
        
        if ([usernamesListArray containsObject:username]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        cell.textLabel.text = [@"@" stringByAppendingString:username];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    AppDelegate *ad = kAppDelegate;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self updateCounter];
    
    if (self.isFacebook) {
        UITableViewCell *cell = [self.theTableView cellForRowAtIndexPath:indexPath];

        NSMutableDictionary *selectedDictionary = kSelectedFriendsDictionary;
        NSMutableDictionary *deletedDictionary = kDBSyncDeletedFBDict;
        
        NSString *selectedObject = [self.orderedFriendsArray objectAtIndex:indexPath.row];
        int correctedRow = [ad.facebookFriendsDict.allValues indexOfObject:selectedObject];
        
        if (correctedRow == INT_MAX) {
            return;
        }
        
        NSString *identifier = [ad.facebookFriendsDict.allKeys objectAtIndex:correctedRow];
        
        if (self.isImmediateSelection) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"passFriendID" object:identifier];
            [self dismissModalViewControllerAnimated:YES];
            return;
        }
        
        if (![selectedDictionary.allKeys containsObject:identifier]) {
            if (selectedDictionary.allKeys.count < 5) {
                NSString *name = [ad.facebookFriendsDict.allValues objectAtIndex:correctedRow];
                [selectedDictionary setValue:name forKey:identifier];
                [[NSUserDefaults standardUserDefaults]setObject:selectedDictionary forKey:kSelectedFriendsDictionaryKey];
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                if ([deletedDictionary.allKeys containsObject:identifier]) {
                    [deletedDictionary removeObjectForKey:identifier];
                    [[NSUserDefaults standardUserDefaults]setObject:deletedDictionary forKey:kDBSyncDeletedFBDictKey];
                }
            } else {
                [self flashLabelWithDelay:0.0f];
            }
        } else {
            
            if ([self.savedFriendsDict.allKeys containsObject:identifier]) {
                [deletedDictionary setObject:[selectedDictionary objectForKey:identifier] forKey:identifier];
                [[NSUserDefaults standardUserDefaults]setObject:deletedDictionary forKey:kDBSyncDeletedFBDictKey];
            }
            
            if ([selectedDictionary.allKeys containsObject:identifier]) {
                [selectedDictionary removeObjectForKey:identifier];
                [[NSUserDefaults standardUserDefaults]setObject:selectedDictionary forKey:kSelectedFriendsDictionaryKey];
            }
            
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    } else {
        NSMutableArray *usernames = usernamesListArray;
        NSString *username = [ad.theFetchedUsernames objectAtIndex:indexPath.row];
        
        if (self.isImmediateSelection) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"passFriendID" object:username];
            [self dismissModalViewControllerAnimated:YES];
        }
        
        if (![usernames containsObject:username]) { // Selecting the username
            if (usernames.count < 5) {
                [usernames addObject:username];
                [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
                
                NSMutableArray *deletedArray = kDBSyncDeletedTArray;
                
                if ([deletedArray containsObject:username]) {
                    [deletedArray removeObject:username];
                    [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
                }
                
                [[NSUserDefaults standardUserDefaults]setObject:usernames forKey:usernamesListKey];
            } else {
                [self flashLabelWithDelay:0.5f];
            }
            
        } else { // deselecting the username
            
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
            
            NSMutableArray *addedUsernames = addedUsernamesListArray;
            
            if ([self.savedSelectedArrayTwitter containsObject:username]) {
                NSMutableArray *deletedArray = kDBSyncDeletedTArray;
                if (![deletedArray containsObject:username]) {
                    [deletedArray addObject:username];
                    [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
                }
            }
            
            if ([usernames containsObject:username]) {
                [usernames removeObject:username];
                [[NSUserDefaults standardUserDefaults]setObject:usernames forKey:usernamesListKey];
            }
            
            if ([addedUsernames containsObject:username]) {
                [addedUsernames removeObject:username];
                [[NSUserDefaults standardUserDefaults]setObject:addedUsernames forKey:addedUsernamesListKey];
                [ad.theFetchedUsernames removeObject:username];
                [self.theTableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section], nil] withRowAnimation:UITableViewRowAnimationLeft];
            }
        }
    }
    [self updateCounter];
}

- (void)enableButtons {
    [kAppDelegate hideHUD];
    self.navBar.topItem.leftBarButtonItem.enabled = YES;
    self.navBar.topItem.rightBarButtonItem.enabled = YES;
    [self.pull finishedLoading];
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *ad = kAppDelegate;
    
    [ad makeSureUsernameListArraysAreNotNil];
    
    self.pull = [[PullToRefreshView alloc]initWithScrollView:self.theTableView];
    [self.pull setDelegate:self];
    [self.theTableView addSubview:self.pull];
    
    if (self.isFacebook) {
        
        if (![ad.facebook isSessionValid]) {
            [ad tryLoginFromSavedCreds];
        }
        
        if (self.isImmediateSelection) {
            self.navBar.topItem.title = @"Select Friend";
        } else {
            self.navBar.topItem.title = @"Select Friends";
        }
        
        self.savedFriendsDict = kSelectedFriendsDictionary;
        
        [self loadCachedFriendsOrderedArray];
        
        if (!self.orderedFriendsArray) {
            self.orderedFriendsArray = [NSMutableArray array];
            [ad.facebookFriendsDict removeAllObjects];
        }
        
        if (ad.facebookFriendsDict.allKeys.count == 0) {
            if ([ad.facebook isSessionValid]) {
                [ad showHUDWithTitle:@"Loading..."];
                [self loadFacebookFriends];
            }
        }
    } else {
        
        if (_isImmediateSelection) {
            _navBar.topItem.title = @"Select User";
        } else {
            _navBar.topItem.title = @"Select Users";
        }
        
        if (![ad.engine isAuthorized]) {
            [ad.engine loadAccessToken];
        }
        
        _savedSelectedArrayTwitter = usernamesListArray;
        
        if (ad.theFetchedUsernames.count == 0) {
            if ([ad.engine isAuthorized]) {
                [ad showHUDWithTitle:@"Loading..."];
                [self fetchFriends];
            }
        } else {
            [self updateListTwitter];
        }
    }
    
    [self updateCounter];
}

- (void)back {
    [self dismissModalViewControllerAnimated:YES];
}

@end
