//
//  UserSelectorViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 1/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "UserSelectorViewController.h"
#import "FHSTwitterEngine.h"

static NSString * const fqlFriendsOrdered = @"SELECT name,uid,last_name FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me()) order by last_name";

@implementation UserSelectorViewController

- (instancetype)initWithIsFacebook:(BOOL)isfacebook isImmediateSelection:(BOOL)isimdtselection {
    if (self = [super init]) {
        self.isFacebook = isfacebook;
        self.isImmediateSelection = isimdtselection;
    }
    return self;
}

- (instancetype)initWithIsFacebook:(BOOL)isfacebook {
    if (self = [super init]) {
        self.isFacebook = isfacebook;
        self.isImmediateSelection = NO;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    self.theTableView = [[UITableView alloc]initWithFrame:screenBounds];
    _theTableView.delegate = self;
    _theTableView.dataSource = self;
    [self.view addSubview:_theTableView];
    
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Select Users"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(back)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Reset" style:UIBarButtonItemStyleBordered target:self action:@selector(resetSelectedUsers)];
    [_navBar pushNavigationItem:topItem animated:NO];
    
    [self.view addSubview:_navBar];
    
    if (_isImmediateSelection) {
        _theTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
        _theTableView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    } else {
        _theTableView.contentInset = UIEdgeInsetsMake(64, 0, 44, 0);
        _theTableView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 44, 0);
        
        UIToolbar *bottomBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-44, screenBounds.size.width, 44)];
        
        if (!_isFacebook) {
            UIBarButtonItem *bbi = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAddUsernameDialogue)];
            bbi.style = UIBarButtonItemStyleBordered;
            bottomBar.items = @[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], bbi];
        }
        
        [self.view addSubview:bottomBar];
        
        self.counter = [[UILabel alloc]initWithFrame:bottomBar.frame];
        _counter.backgroundColor = [UIColor clearColor];
        _counter.textAlignment = UITextAlignmentCenter;
        _counter.textColor = [UIColor blackColor];
        _counter.font = [UIFont boldSystemFontOfSize:19];
        [self.view addSubview:_counter];
    }
    
    self.pull = [[PullToRefreshView alloc]initWithScrollView:_theTableView];
    [_pull setDelegate:self];
    [_theTableView addSubview:_pull];
    
    if (_isFacebook) {
        if (_isImmediateSelection) {
            _navBar.topItem.title = @"Select Friend";
        } else {
            _navBar.topItem.title = @"Select Friends";
        }
        
        self.savedFriendsDict = [Settings selectedFacebookFriends];
        
        [self loadCachedFriendsOrderedArray];
        
        if (!_orderedFriendsArray) {
            self.orderedFriendsArray = [NSMutableArray array];
            [Cache.shared.facebookFriends removeAllObjects];
        }
        
        if (Cache.shared.facebookFriends.count == 0) {
            if (FHSFacebook.shared.isSessionValid) {
                [Settings showHUDWithTitle:@"Loading..."];
                [self loadFacebookFriends];
            }
        }
    } else {
        if (_isImmediateSelection) {
            _navBar.topItem.title = @"Select User";
        } else {
            _navBar.topItem.title = @"Select Users";
        }
        
        if (![[FHSTwitterEngine sharedEngine]isAuthorized]) {
            [[FHSTwitterEngine sharedEngine]loadAccessToken];
        }
        
        self.savedSelectedArrayTwitter = [Settings selectedTwitterUsernames];
        
        if (Cache.shared.twitterFriends.count == 0) {
            if ([[FHSTwitterEngine sharedEngine]isAuthorized]) {
                [Settings showHUDWithTitle:@"Loading..."];
                [self fetchFriends];
            }
        } else {
            [self updateListTwitter];
        }
    }
    
    [self updateCounter];
}

// Facebook Stuff

- (void)loadCachedFriendsOrderedArray {
    self.orderedFriendsArray = [NSMutableArray arrayWithContentsOfFile:[[Settings cachesDirectory]stringByAppendingPathComponent:@"orderedFacebookFriends.plist"]];
}

- (void)cacheFriendsOrderedArray {
    NSString *loadPath = [[Settings cachesDirectory]stringByAppendingPathComponent:@"orderedFacebookFriends.plist"];
    [self.orderedFriendsArray writeToFile:loadPath atomically:YES];
}

- (void)clearFriends {
    [[[Cache shared]facebookFriends]removeAllObjects];
    [Settings removeFacebookFromTimeline];
}

- (void)loadFacebookFriends {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me/fql?access_token=%@&q=%@",FHSFacebook.shared.accessToken, fqlFriendsOrdered.fhs_URLEncode]];
    
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
            
            if (_orderedFriendsArray.count == 0) {
                self.orderedFriendsArray = [NSMutableArray array];
            }

            if ([parsedJSONResponse isKindOfClass:[NSDictionary class]]) {
                [self clearFriends];
                
                NSArray *data = ((NSDictionary *)parsedJSONResponse)[@"data"];
                
                for (NSDictionary *dict in data) {
                    NSString *identifier = dict[@"uid"];
                    NSString *name = dict[@"name"];
                    Cache.shared.facebookFriends[identifier] = name;
                }
                
                /*for (int i = 0; i < data.count; i++) {
                    NSString *username = [NSString stringWithString:data[i][@"name"]];
                    
                    if ([[[Cache shared]facebookFriends].allValues containsObject:username]) {
                        username = [username stringByAppendingString:@" "];
                    }
                    
                    NSString *identifier = [NSString stringWithFormat:@"%@",data[i][@"uid"]];
                    [[[Cache shared]facebookFriends]setValue:username forKey:identifier];
                    
                    [_orderedFriendsArray addObject:username];
                }*/
                
                [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                
                [self cacheFriendsOrderedArray];
            }
        }
    }];
}

- (void)updateListTwitter {
    NSMutableArray *addedUsernames = [Settings addedTwitterUsernames];
    NSMutableArray *usernames = [Settings selectedTwitterUsernames];
    
    NSMutableArray *unmodifiedTwitterUsernamesList = [NSMutableArray arrayWithContentsOfFile:[[Settings cachesDirectory]stringByAppendingPathComponent:@"cached_list_twitter_friends.plist"]];

    // Update added array
    for (id object in usernames.mutableCopy) {
        if (![unmodifiedTwitterUsernamesList containsObject:object]) {
            if (![addedUsernames containsObject:object]) {
                [addedUsernames addObject:object];
            }
        }
    }

    for (id object in addedUsernames.mutableCopy) {
        if ([unmodifiedTwitterUsernamesList containsObject:object]) {
            [addedUsernames removeObject:object]; // its a user
        } else {
            if (![[[Cache shared]twitterFriends]containsObject:object]) {
                [[[Cache shared]twitterFriends]addObject:object];
            }
        }
    }
    
    [[NSUserDefaults standardUserDefaults]setObject:addedUsernames forKey:kAddedUsernamesListKey];
    [[[Cache shared]twitterFriends]sortUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void)fetchFriends {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            id retIDs = [[FHSTwitterEngine sharedEngine]getFriendsIDs];
            if ([retIDs isKindOfClass:[NSError class]]) {
                NSError *theError = (NSError *)retIDs;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        qAlert([NSString stringWithFormat:@"Error %d",theError.code], theError.domain);
                    }
                });
            } else if ([retIDs isKindOfClass:[NSDictionary class]]) {
                NSArray *ids = ((NSDictionary *)retIDs)[@"ids"];
                
                NSMutableArray *usernames = [NSMutableArray array];
                NSMutableArray *idsToLookUp = [NSMutableArray array];
                NSMutableDictionary *cachedUsernamesLookupDict = [[Cache shared]twitterIdToUsername];
                
                for (NSString *identifier in ids) {
                    NSString *theUsernameFromCache = cachedUsernamesLookupDict[identifier];
                    if (theUsernameFromCache.length > 0) {
                        Cache.shared.twitterIdToUsername[identifier] = theUsernameFromCache;
                        [usernames addObject:theUsernameFromCache];
                    } else {
                        [idsToLookUp addObject:identifier];
                    }
                }
                
                BOOL succeeded = YES;
                
                if (idsToLookUp.count > 0) {
                    NSArray *idConcatStrings = [[FHSTwitterEngine sharedEngine]generateRequestStringsFromArray:idsToLookUp];
                    
                    for (NSString *idconcatstr in idConcatStrings) {
                        id usersRet = [[FHSTwitterEngine sharedEngine]lookupUsers:[idconcatstr componentsSeparatedByString:@","] areIDs:YES];
                        
                        if ([usersRet isKindOfClass:[NSError class]]) {
                            NSError *theError = (NSError *)usersRet;
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                @autoreleasepool {
                                    qAlert([NSString stringWithFormat:@"Error %d",theError.code], theError.domain);
                                }
                            });
                            succeeded = NO;
                            break;
                        } else if ([usersRet isKindOfClass:[NSArray class]]) {
                            NSArray *userDicts = (NSArray *)usersRet;
                            for (NSDictionary *dict in userDicts) {
                                NSString *screen_name = dict[@"screen_name"];
                                NSString *user_id = dict[@"id_str"];
                                [[Cache shared]twitterIdToUsername][user_id] = screen_name;
                                [usernames addObject:screen_name];
                            }
                        }
                    }
                }
                
                if (succeeded && usernames.count > 0) {
                    Cache.shared.twitterFriends = [usernames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)].mutableCopy;
                }
            }
            
            dispatch_sync(dispatch_get_main_queue(), ^{
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
    NSArray *array = self.isFacebook?[[Settings selectedFacebookFriends]allKeys]:[Settings selectedTwitterUsernames];
    _counter.text = [NSString stringWithFormat:@"%d/5",array.count];
}

- (void)resetSelectedUsers {
    if (_isFacebook) {
        NSMutableDictionary *selectedDictionary = [Settings selectedFacebookFriends];
        NSMutableDictionary *deletedDictionary = [Settings dropboxDeletedFacebookDictionary];
        
        [deletedDictionary addEntriesFromDictionary:selectedDictionary];
        [[NSUserDefaults standardUserDefaults]setObject:deletedDictionary forKey:kDBSyncDeletedFBDictKey];
        
        [selectedDictionary removeAllObjects];
        [[NSUserDefaults standardUserDefaults]setObject:selectedDictionary forKey:kSelectedFriendsDictionaryKey];
        
        [Settings removeFacebookFromTimeline];
    } else {
        NSMutableArray *usernames = [Settings selectedTwitterUsernames];
        NSMutableArray *addedUsernames = [Settings addedTwitterUsernames];
        NSMutableArray *deletedArray = [Settings dropboxDeletedTwitterArray];
        
        for (id username in usernames) {
            if ([_savedSelectedArrayTwitter containsObject:username]) {
                if (![deletedArray containsObject:username]) {
                    [deletedArray addObject:username];
                }
            }
        }
        
        [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
        
        [[[Cache shared]twitterFriends]removeObjectsInArray:addedUsernames];
        [[NSUserDefaults standardUserDefaults]setObject:[NSMutableArray array] forKey:kAddedUsernamesListKey];
        [[NSUserDefaults standardUserDefaults]setObject:[NSMutableArray array] forKey:kSelectedUsernamesListKey];
        [Settings removeTwitterFromTimeline];
    }
    
    [Settings reloadMainTableView];
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self updateCounter];
}

- (void)showAddUsernameDialogue {
    if ([Settings selectedTwitterUsernames].count >= 5) {
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

    if (Settings.selectedTwitterUsernames.count < 5) {
        
        if ([username hasPrefix:@"@"]) {
            username = [username substringFromIndex:1];
        }
        
        NSMutableArray *deletedArray = [Settings dropboxDeletedTwitterArray];
        if ([deletedArray containsObject:username]) {
            [deletedArray removeObject:username];
            [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
        }

        if (![[[Cache shared]twitterFriends]containsObject:username]) {
            NSMutableArray *addedUsernames = [Settings addedTwitterUsernames];
            [addedUsernames addObject:username];
            [[NSUserDefaults standardUserDefaults]setObject:addedUsernames forKey:kAddedUsernamesListKey];
            [[[Cache shared]twitterFriends]addObject:username];
            [[[Cache shared]twitterFriends]sortUsingSelector:@selector(caseInsensitiveCompare:)];
        }
        
        NSMutableArray *usernames = [Settings selectedTwitterUsernames];
        
        if (![usernames containsObject:username]) {
            [usernames addObject:username];
            [[NSUserDefaults standardUserDefaults]setObject:usernames forKey:kSelectedUsernamesListKey];
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
    int count = _isFacebook?Cache.shared.facebookFriends.count:Cache.shared.twitterFriends.count;
    return (count > 0)?count:1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellUS";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;

    if (_isFacebook) {
        NSDictionary *selectedDictionary = [Settings selectedFacebookFriends];

        if (_orderedFriendsArray.count == 0) {
            self.orderedFriendsArray = [NSMutableArray array];
            cell.textLabel.text = @"No friends loaded...";
            return cell;
        }
        
        if (Cache.shared.facebookFriends.count == 0) {
            cell.textLabel.text = @"No friends loaded...";
            return cell;
        }
        
        NSString *theValue = _orderedFriendsArray[indexPath.row];
        int indexOfKey = [[[Cache shared]facebookFriends].allValues indexOfObject:theValue];
        
        if ([[[Cache shared]facebookFriends].allValues containsObject:theValue]) {
            if (indexOfKey < INT_MAX) {
                NSString *secondValue = ([[Cache shared]facebookFriends].allKeys)[indexOfKey];
                if ([selectedDictionary.allKeys containsObject:secondValue]) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
        }
        cell.textLabel.text = theValue;
    } else {
        if (Cache.shared.twitterFriends.count == 0) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = @"No usernames loaded...";
            return cell;
        }
        
        NSString *username = Cache.shared.twitterFriends[indexPath.row];
        cell.accessoryType = [Settings.selectedTwitterUsernames containsObject:username]?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
        cell.textLabel.text = [@"@" stringByAppendingString:username];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self updateCounter];
    
    if (self.isFacebook) {
        UITableViewCell *cell = [_theTableView cellForRowAtIndexPath:indexPath];

        NSMutableDictionary *selectedDictionary = [Settings selectedFacebookFriends];
        NSMutableDictionary *deletedDictionary = [Settings dropboxDeletedFacebookDictionary];
        
        NSString *selectedObject = _orderedFriendsArray[indexPath.row];
        int correctedRow = [Cache.shared.facebookFriends.allValues indexOfObject:selectedObject];
        
        if (correctedRow == INT_MAX) {
            return;
        }
        
        NSString *identifier = Cache.shared.facebookFriends.allKeys[correctedRow];
        
        if (_isImmediateSelection) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"passFriendID" object:identifier];
            [self dismissModalViewControllerAnimated:YES];
            return;
        }
        
        if (![selectedDictionary.allKeys containsObject:identifier]) {
            if (selectedDictionary.allKeys.count < 5) {
                NSString *name = Cache.shared.facebookFriends.allValues[correctedRow];
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
                deletedDictionary[identifier] = selectedDictionary[identifier];
                [[NSUserDefaults standardUserDefaults]setObject:deletedDictionary forKey:kDBSyncDeletedFBDictKey];
            }
            
            if ([selectedDictionary.allKeys containsObject:identifier]) {
                [selectedDictionary removeObjectForKey:identifier];
                [[NSUserDefaults standardUserDefaults]setObject:selectedDictionary forKey:kSelectedFriendsDictionaryKey];
            }
            
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    } else {
        NSMutableArray *usernames = [Settings selectedTwitterUsernames];
        NSString *username = Cache.shared.twitterFriends[indexPath.row];
        
        if (_isImmediateSelection) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"passFriendID" object:username];
            [self dismissModalViewControllerAnimated:YES];
        }
        
        if (![usernames containsObject:username]) { // Selecting the username
            if (usernames.count < 5) {
                [usernames addObject:username];
                [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
                
                NSMutableArray *deletedArray = [Settings dropboxDeletedTwitterArray];
                
                if ([deletedArray containsObject:username]) {
                    [deletedArray removeObject:username];
                    [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
                }
                
                [[NSUserDefaults standardUserDefaults]setObject:usernames forKey:kSelectedUsernamesListKey];
            } else {
                [self flashLabelWithDelay:0.5f];
            }
            
        } else { // deselecting the username
            
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
            
            NSMutableArray *addedUsernames = [Settings addedTwitterUsernames];
            
            if ([self.savedSelectedArrayTwitter containsObject:username]) {
                NSMutableArray *deletedArray = [Settings dropboxDeletedTwitterArray];
                if (![deletedArray containsObject:username]) {
                    [deletedArray addObject:username];
                    [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
                }
            }
            
            if ([usernames containsObject:username]) {
                [usernames removeObject:username];
                [[NSUserDefaults standardUserDefaults]setObject:usernames forKey:kSelectedUsernamesListKey];
            }
            
            if ([addedUsernames containsObject:username]) {
                [addedUsernames removeObject:username];
                [[NSUserDefaults standardUserDefaults]setObject:addedUsernames forKey:kAddedUsernamesListKey];
                [[[Cache shared]twitterFriends]removeObject:username];
                [_theTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            }
        }
    }
    [self updateCounter];
}

- (void)enableButtons {
    [Settings hideHUD];
    _navBar.topItem.leftBarButtonItem.enabled = YES;
    _navBar.topItem.rightBarButtonItem.enabled = YES;
    [_pull finishedLoading];
    [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)back {
    [self dismissModalViewControllerAnimated:YES];
}

@end
