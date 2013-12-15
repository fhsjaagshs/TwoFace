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

@interface UserSelectorViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>



//
//
// TODO: Follow users directly in app
//
//


@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UITableView *theTableView;
@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) UILabel *counter;

@property (nonatomic, assign) BOOL isVisible;

// Twitter
@property (strong, nonatomic) NSMutableArray *savedSelectedArrayTwitter;

// Facebook
@property (strong, nonatomic) NSMutableDictionary *savedSelectedFriendsDict;
@property (nonatomic, strong) NSMutableDictionary *facebookFriends;
@property (nonatomic, strong) NSMutableArray *orderedFacebookUIDs;

@end

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
    self.view.backgroundColor = [UIColor whiteColor];
    self.theTableView = [[UITableView alloc]initWithFrame:screenBounds];
    _theTableView.delegate = self;
    _theTableView.dataSource = self;
    _theTableView.clipsToBounds = NO;
    _theTableView.contentInset = _isImmediateSelection?UIEdgeInsetsMake(64, 0, 0, 0):UIEdgeInsetsMake(64, 0, 44, 0);
    _theTableView.scrollIndicatorInsets = _isImmediateSelection?UIEdgeInsetsMake(64, 0, 0, 0):UIEdgeInsetsMake(64, 0, 44, 0);
    [self.view addSubview:_theTableView];
    
    self.refreshControl = [[UIRefreshControl alloc]initWithFrame:CGRectMake(0, -64, 320, 64)];
    [_refreshControl addTarget:self action:@selector(refreshUsers) forControlEvents:UIControlEventValueChanged];
    [_theTableView addSubview:_refreshControl];
    
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Select Users"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(back)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Reset" style:UIBarButtonItemStyleBordered target:self action:@selector(resetSelectedUsers)];
    [_navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:_navBar];
    
    if (!_isImmediateSelection) {
        UIToolbar *bottomBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-44, screenBounds.size.width, 44)];
        
        if (!_isFacebook) {
            UIBarButtonItem *bbi = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(disableButtons)];
            bbi.style = UIBarButtonItemStyleBordered;
            bottomBar.items = @[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], bbi];
        }
        
        [self.view addSubview:bottomBar];
        
        self.counter = [[UILabel alloc]initWithFrame:bottomBar.frame];
        _counter.backgroundColor = [UIColor clearColor];
        _counter.textAlignment = NSTextAlignmentCenter;
        _counter.textColor = [UIColor blackColor];
        _counter.font = [UIFont boldSystemFontOfSize:19];
        [self.view addSubview:_counter];
    }
    
    if (_isFacebook) {
        _navBar.topItem.title = @"Facebook Friends";
        
        self.savedSelectedFriendsDict = [Settings selectedFacebookFriends];
        
        NSMutableArray *orderedFacebookUIDsTemp = [NSMutableArray array];
        self.facebookFriends = [Cache.shared facebookFriendsFromCache:&orderedFacebookUIDsTemp];
        self.orderedFacebookUIDs = [NSMutableArray array];
        [_orderedFacebookUIDs addObjectsFromArray:orderedFacebookUIDsTemp];
        
        if (_facebookFriends.count == 0) {
            if (FHSFacebook.shared.isSessionValid) {
                [self disableButtons];
                [self loadFacebookFriends];
            }
        }
    } else {
        _navBar.topItem.title = @"Twitter Friends";
        
        if (![[FHSTwitterEngine sharedEngine]isAuthorized]) {
            [[FHSTwitterEngine sharedEngine]loadAccessToken];
        }
        
        self.savedSelectedArrayTwitter = [Settings selectedTwitterUsernames];
        
        if (Cache.shared.twitterFriends.count == 0) {
            if ([[FHSTwitterEngine sharedEngine]isAuthorized]) {
                [self disableButtons];
                [self fetchFriends];
            }
        }
    }
    
    [self updateCounter];
}

// Facebook Stuff

- (void)loadFacebookFriends {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me/fql?access_token=%@&q=%@",FHSFacebook.shared.accessToken, fqlFriendsOrdered.fhs_URLEncode]];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"GET"];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [self enableButtons];

        if (error) {
            NSString *FBerr = error.localizedDescription;
            NSString *message = (FBerr.length == 0)?@"Confirm that you are logged in correctly and try again.":FBerr;
            qAlert(@"Facebook Error", message);
        } else {
            id parsedJSONResponse = removeNull([NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);

            if ([parsedJSONResponse isKindOfClass:[NSError class]]) {
                NSString *FBerr = [parsedJSONResponse localizedDescription];
                NSString *message = (FBerr.length == 0)?@"Confirm that you are logged in correctly and try again.":FBerr;
                qAlert(@"Facebook Error", message);
            } else if ([parsedJSONResponse isKindOfClass:[NSDictionary class]]) {
                NSArray *data = ((NSDictionary *)parsedJSONResponse)[@"data"];
                [_orderedFacebookUIDs removeAllObjects];
                [_facebookFriends removeAllObjects];

                for (NSDictionary *dict in data) {
                    NSString *identifier = [NSString stringWithFormat:@"%@",dict[@"uid"]];
                    _facebookFriends[identifier] = dict[@"name"];
                    [_orderedFacebookUIDs addObject:identifier];
                }
                
                [Cache.shared cacheFacebookDicts:data];
                [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }];
}

- (void)fetchFriends {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            id retIDs = [[FHSTwitterEngine sharedEngine]getFriendsIDs];
            if ([retIDs isKindOfClass:[NSError class]]) {
                NSError *theError = (NSError *)retIDs;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        qAlert([NSString stringWithFormat:@"Error %d",theError.code], theError.localizedDescription);
                    }
                });
            } else if ([retIDs isKindOfClass:[NSDictionary class]]) {
                NSArray *ids = ((NSDictionary *)retIDs)[@"ids"];
                NSMutableArray *idsToLookUp = [NSMutableArray array];
                
                for (NSString *identifier in ids) {
                    if (!Cache.shared.twitterFriends[identifier]) {
                        [idsToLookUp addObject:identifier];
                    }
                }
                
                BOOL failed = NO;
            
                if (idsToLookUp.count > 0) {
                    NSArray *idConcatStrings = [[FHSTwitterEngine sharedEngine]generateRequestStringsFromArray:idsToLookUp];
                    
                    for (NSString *idconcatstr in idConcatStrings) {
                        if (!FHSTwitterEngine.isConnectedToInternet) {
                            break;
                        }
                        
                        id usersRet = [[FHSTwitterEngine sharedEngine]lookupUsers:[idconcatstr componentsSeparatedByString:@","] areIDs:YES];
                        
                        if ([usersRet isKindOfClass:[NSError class]]) {
                            failed = YES;
                        } else if ([usersRet isKindOfClass:[NSArray class]]) {
                            NSArray *userDicts = (NSArray *)usersRet;
                            for (NSDictionary *dict in userDicts) {
                                NSString *screen_name = dict[@"screen_name"];
                                NSString *user_id = dict[@"id_str"];
                                Cache.shared.twitterFriends[user_id] = screen_name;
                            }
                        }
                    }
                }
                
                if (failed) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            qAlert(@"Twitter Error", @"Failed to look up some usernames.");
                        }
                    });
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

- (void)refreshUsers {
    if (![FHSTwitterEngine isConnectedToInternet]) {
        [_refreshControl endRefreshing];
        qAlert(@"Friends Error", @"The Internet connection appears to be offline.");
        return;
    }
    
    [self disableButtons];
    
    if (_isFacebook) {
        [self loadFacebookFriends];
    } else {
        [self fetchFriends];
    }
}

- (void)updateCounter {
    _counter.text = [NSString stringWithFormat:@"%d/5",_isFacebook?Settings.selectedFacebookFriends.count:Settings.selectedTwitterUsernames.count];
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
        NSMutableArray *deletedArray = [Settings dropboxDeletedTwitterArray];
        
        for (id username in usernames) {
            if ([_savedSelectedArrayTwitter containsObject:username]) {
                if (![deletedArray containsObject:username]) {
                    [deletedArray addObject:username];
                }
            }
        }
        
        [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
        [[NSUserDefaults standardUserDefaults]setObject:[NSMutableArray array] forKey:kAddedUsernamesListKey];
        [[NSUserDefaults standardUserDefaults]setObject:[NSMutableArray array] forKey:kSelectedUsernamesListKey];
        [Settings removeTwitterFromTimeline];
    }
    
    [Settings reloadMainTableView];
    [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self updateCounter];
}

- (void)flashLabelWithDelay:(float)delay {
    [_counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:delay];
    [_counter performSelector:@selector(setTextColor:) withObject:[UIColor blackColor] afterDelay:delay+0.1];
    [_counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:delay+0.2];
    [_counter performSelector:@selector(setTextColor:) withObject:[UIColor blackColor] afterDelay:delay+0.3];
    [_counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:delay+0.4];
    [_counter performSelector:@selector(setTextColor:) withObject:[UIColor blackColor] afterDelay:delay+0.5];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int count = _isFacebook?_facebookFriends.count:Cache.shared.twitterFriends.count;
    return (count > 0)?count:(_refreshControl.isRefreshing?0:1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellUS";
    
    UserSelectorCell *cell = (UserSelectorCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UserSelectorCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    if (_isFacebook) {
        if (any( _facebookFriends.count == 0, _orderedFacebookUIDs.count == 0)) {
            cell.textLabel.text = @"No friends loaded...";
            return cell;
        }

        cell.user_id = _orderedFacebookUIDs[indexPath.row];
        cell.username = _facebookFriends[cell.user_id];
        cell.accessoryType = (Settings.selectedFacebookFriends[cell.user_id] != nil)?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
        cell.textLabel.text = cell.username;
    } else {
        if (Cache.shared.twitterFriends.count == 0) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = @"No usernames loaded...";
            return cell;
        }
        
        cell.user_id = Cache.shared.twitterFriends.allKeys[indexPath.row];
        cell.username = Cache.shared.twitterFriends[cell.user_id];
        cell.accessoryType = [Settings.selectedTwitterUsernames containsObject:cell.username]?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
        cell.textLabel.text = [@"@" stringByAppendingString:cell.username];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UserSelectorCell *cell = (UserSelectorCell *)[_theTableView cellForRowAtIndexPath:indexPath];
    
    [self updateCounter];
    
    if (_isFacebook) {
        NSMutableDictionary *selectedDictionary = [Settings selectedFacebookFriends];
        NSMutableDictionary *deletedDictionary = [Settings dropboxDeletedFacebookDictionary];

        NSString *identifier = cell.user_id;
        
        if (_isImmediateSelection) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"passFriendID" object:identifier];
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
        }
        
        if (!selectedDictionary[identifier]) {
            if (selectedDictionary.count < 5) {
                selectedDictionary[identifier] = cell.username;
                [[NSUserDefaults standardUserDefaults]setObject:selectedDictionary forKey:kSelectedFriendsDictionaryKey];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                if (deletedDictionary[identifier]) {
                    [deletedDictionary removeObjectForKey:identifier];
                    [[NSUserDefaults standardUserDefaults]setObject:deletedDictionary forKey:kDBSyncDeletedFBDictKey];
                }
            } else {
                [self flashLabelWithDelay:0.0f];
            }
        } else {
            if (_savedSelectedFriendsDict[identifier]) {
                deletedDictionary[identifier] = selectedDictionary[identifier];
                [[NSUserDefaults standardUserDefaults]setObject:deletedDictionary forKey:kDBSyncDeletedFBDictKey];
            }
            
            if (selectedDictionary[identifier]) {
                [selectedDictionary removeObjectForKey:identifier];
                [[NSUserDefaults standardUserDefaults]setObject:selectedDictionary forKey:kSelectedFriendsDictionaryKey];
            }

            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else {
        NSMutableArray *selectedUsernames = [Settings selectedTwitterUsernames];

        if (_isImmediateSelection) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"passFriendID" object:cell.username];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        
        if (![selectedUsernames containsObject:cell.username]) { // Selecting the username
            if (selectedUsernames.count < 5) {
                [selectedUsernames addObject:cell.username];
                [[NSUserDefaults standardUserDefaults]setObject:selectedUsernames forKey:kSelectedUsernamesListKey];
                
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                
                NSMutableArray *deletedArray = [Settings dropboxDeletedTwitterArray];
                
                if ([deletedArray containsObject:cell.username]) {
                    [deletedArray removeObject:cell.username];
                    [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
                }
            } else {
                [self flashLabelWithDelay:0.5f];
            }
        } else { // deselecting the username
            cell.accessoryType = UITableViewCellAccessoryNone;

            if ([_savedSelectedArrayTwitter containsObject:cell.username]) {
                NSMutableArray *deletedArray = [Settings dropboxDeletedTwitterArray];
                if (![deletedArray containsObject:cell.username]) {
                    [deletedArray addObject:cell.username];
                    [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
                }
            }
            
            if ([selectedUsernames containsObject:cell.username]) {
                [selectedUsernames removeObject:cell.username];
                [[NSUserDefaults standardUserDefaults]setObject:selectedUsernames forKey:kSelectedUsernamesListKey];
            }
        }
    }
    [self updateCounter];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.isVisible = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.isVisible = YES;
     NSLog(@"%f",_theTableView.contentInset.top);
    if (_navBar.topItem.rightBarButtonItem.enabled == NO && !_refreshControl.isRefreshing) {
        [_theTableView setContentOffset:CGPointMake(0, -64) animated:YES];
        [_refreshControl beginRefreshing];
        [_theTableView reloadData];
    }
}

- (void)disableButtons {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    _navBar.topItem.leftBarButtonItem.enabled = NO;
    _navBar.topItem.rightBarButtonItem.enabled = NO;
    
    if (_isVisible) {
        [_theTableView setContentOffset:CGPointMake(0, -128) animated:YES];
        [_refreshControl beginRefreshing];
        [_theTableView reloadData];
        [self performSelector:@selector(enableButtons) withObject:nil afterDelay:1.5f];
    }
}

- (void)enableButtons {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    _navBar.topItem.leftBarButtonItem.enabled = YES;
    _navBar.topItem.rightBarButtonItem.enabled = YES;
    [_refreshControl endRefreshing];
    [_theTableView setContentOffset:CGPointMake(0, -60) animated:YES];
    [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
