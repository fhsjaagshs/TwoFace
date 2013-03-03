//
//  TwitterUserSelector.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/17/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "TwitterUserSelector.h"
#import "OAuthConsumer.h"

@implementation TwitterUserSelector

@synthesize theTableView, counter, reset, back, savedSelectedArray;

- (void)cacheIDtoUsernameDict:(NSDictionary *)dict {
    NSString *cachePath = [kCachesDirectory stringByAppendingPathComponent:@"twitter_username_lookup_dict.plist"];
    [dict writeToFile:cachePath atomically:YES];
}

- (NSMutableDictionary *)loadCachedUsernameLookupDict {
    NSString *cachePath = [kCachesDirectory stringByAppendingPathComponent:@"twitter_username_lookup_dict.plist"];
    return [NSMutableDictionary dictionaryWithContentsOfFile:cachePath];
}

- (NSArray *)genIDString:(NSArray *)idsArray {
    
    int count = idsArray.count;

    NSMutableArray *reqStrs = [[NSMutableArray alloc]init];
    
    int remainder = fmod(count, 99);
    
    int numberOfStrings = (count-remainder)/99;
    
    for (int i = 0; i < numberOfStrings; i++) {
        NSString *reqString = @"";

        for (int ii = 0; ii < 99; ii++) {
            
            // i*99 -> the number of 99's completed
            // ii -> the number indicating the progress into the current 99
            int lol = (i*99)+ii;
            
            // handle getting the correct string
            NSString *currentID = [[idsArray objectAtIndex:lol]stringByAppendingString:@","];
            
            // append the string
            reqString = [reqString stringByAppendingString:currentID];
        }
        
        BOOL isLastCharAComma = ([[reqString substringFromIndex:reqString.length-1]isEqualToString:@","]);
        
        if (isLastCharAComma) {
            reqString = [reqString substringToIndex:reqString.length-1];
        }
        
        [reqStrs addObject:reqString];
    }
    
    if (numberOfStrings*99 < count) {
        NSString *reqString = @"";
        
        for (int iii = 0; iii < remainder; iii++) {
            
            // handle getting the correct string
            NSString *currentID = [[idsArray objectAtIndex:(iii+numberOfStrings*99)]stringByAppendingString:@","];
            
            // append the string
            reqString = [reqString stringByAppendingString:currentID];
        }
        
        BOOL isLastCharAComma = ([[reqString substringFromIndex:reqString.length-1]isEqualToString:@","]);
        
        if (isLastCharAComma) {
            reqString = [reqString substringToIndex:reqString.length-1];
        }
        
        [reqStrs addObject:reqString];
    }
    
    return reqStrs;
}

- (NSArray *)getFriends {
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/friends/ids.json"];
    
    AppDelegate *ad = kAppDelegate;
    
    OARequestParameter *cursor = [[OARequestParameter alloc]initWithName:@"cursor" value:@"-1"];
    OARequestParameter *param = [[OARequestParameter alloc]initWithName:@"user_id" value:ad.engine.loggedInID];
    OARequestParameter *sIDs = [[OARequestParameter alloc]initWithName:@"stringify_ids" value:@"true"];
    
    OAConsumer *consumer = [[OAConsumer alloc]initWithKey:kOAuthConsumerKey secret:kOAuthConsumerSecret];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc]initWithURL:baseURL consumer:consumer token:ad.engine.accessToken realm:nil signatureProvider:nil];

    
    [request setHTTPMethod:@"GET"];
    [request setParameters:[NSArray arrayWithObjects:param, sIDs, cursor, nil]];
    
    [request prepare];
    
    NSError *error = nil;
    NSURLResponse *response = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error) {
        return nil;
    }
    
    id returnedValue = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    
    NSMutableArray *identifiersFromRequest = nil;
    
    if ([returnedValue isKindOfClass:[NSDictionary class]]) {
        id idsRAW = [(NSDictionary *)returnedValue objectForKey:@"ids"];
        if ([idsRAW isKindOfClass:[NSArray class]]) {
            identifiersFromRequest = [NSMutableArray arrayWithArray:(NSArray *)idsRAW];
        }
    }
    
    NSMutableArray *usernames = [[NSMutableArray alloc]init];
    
    NSMutableArray *idsToLookUp = [[NSMutableArray alloc]init];
    
    NSMutableDictionary *cachedUsernamesLookupDict = [self loadCachedUsernameLookupDict];
    
    NSMutableDictionary *finalCachedUsernamesDict = [[NSMutableDictionary alloc]init];
    
    for (NSString *identifier in identifiersFromRequest) {
        if ([cachedUsernamesLookupDict.allKeys containsObject:identifier]) {
            NSString *theUsernameFromCache = [cachedUsernamesLookupDict objectForKey:identifier];
            [finalCachedUsernamesDict setObject:theUsernameFromCache forKey:identifier];
            [usernames addObject:theUsernameFromCache];
        } else {
            [idsToLookUp addObject:identifier];
        }
    }
    
    //NSArray *usernameListStrings = [self genIDString:identifiersFromRequest]; // used to pass the NSMutableArray one
    NSArray *usernameListStrings = [self genIDString:idsToLookUp]; // used to pass the NSMutableArray one
    
    
    // ID string checking

    
    // end ID checking
    
    for (NSString *idListString in [usernameListStrings mutableCopy]) {
        baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/users/lookup.json"];
        
        OARequestParameter *iden = [[OARequestParameter alloc]initWithName:@"user_id" value:idListString];
        OARequestParameter *includeEntities = [[OARequestParameter alloc]initWithName:@"include_entities" value:@"false"];
        
        OAConsumer *consumer = [[OAConsumer alloc]initWithKey:kOAuthConsumerKey secret:kOAuthConsumerSecret];
        
        OAMutableURLRequest *requestTwo = [[OAMutableURLRequest alloc] initWithURL:baseURL consumer:consumer token:ad.engine.accessToken realm:nil signatureProvider:nil];
        
        [requestTwo setHTTPMethod:@"GET"];
        [requestTwo setParameters:[NSArray arrayWithObjects:iden, includeEntities, nil]];
        
        [requestTwo prepare];
        
        NSError *errorr = nil;
        NSURLResponse *responser = nil;
        
        NSData *responseDataTwo = [NSURLConnection sendSynchronousRequest:requestTwo returningResponse:&responser error:&errorr];
        
        if (errorr) {
            return nil;
        }
        
        id parsed = [NSJSONSerialization JSONObjectWithData:responseDataTwo options:NSJSONReadingMutableLeaves error:nil];
        
        if ([parsed isKindOfClass:[NSDictionary class]]) {
            if ([(NSDictionary *)parsed objectForKey:@"error"]) {
                qAlert(@"Error", [parsed objectForKey:@"error"]);
                return nil;
            } else if ([(NSDictionary *)parsed objectForKey:@"errors"]) {
                NSArray *errors = [(NSDictionary *)parsed objectForKey:@"errors"];
                for (id obj in errors) {
                    qAlert([NSString stringWithFormat:@"Error %d",[[obj objectForKey:@"code"]intValue]], [obj objectForKey:@"message"]);
                }
            } else {
                [usernames addObject:[parsed objectForKey:@"screen_name"]];
                [finalCachedUsernamesDict setObject:[parsed objectForKey:@"screen_name"] forKey:[parsed objectForKey:@"id_str"]];
            }
        }
        
        if ([parsed isKindOfClass:[NSMutableArray class]]) {
            NSMutableArray *array = [[NSMutableArray alloc]initWithArray:(NSArray *)parsed];
            for (NSDictionary *dict in [array mutableCopy]) {
                NSString *name = [dict objectForKey:@"screen_name"];
                [usernames addObject:name];
                [finalCachedUsernamesDict setObject:name forKey:[dict objectForKey:@"id_str"]];
            }
        }
    }
    [self cacheIDtoUsernameDict:finalCachedUsernamesDict];
    return usernames;
}

- (void)updateList {
    
    AppDelegate *ad = kAppDelegate;
    
    // ad.theFetchedUsernames: Followers on Twitter
    
    NSMutableArray *one = addedUsernamesListArray; // added users
    NSMutableArray *oldSelectedUsernames = usernamesListArray;
    NSMutableArray *twitterFriends = [NSMutableArray arrayWithContentsOfFile:[kCachesDirectory stringByAppendingPathComponent:@"cached_list_twitter_friends.plist"]];
    
    [oldSelectedUsernames removeObjectsInArray:one]; // usernames that were not manually added on the destination device (device executing this code)
    
    for (id object in [oldSelectedUsernames mutableCopy]) {
        if (![twitterFriends containsObject:object]) { // if "selected" username (if the fetched usernames does not include it)
            if (![one containsObject:object]) {
                [one addObject:object];
            }
        }
    }
    
    for (id object in [one mutableCopy]) {
        if (![twitterFriends containsObject:object]) {
            if (![ad.theFetchedUsernames containsObject:object]) {
                [ad.theFetchedUsernames addObject:object]; // add the manually added to the fetched usernames
            }
        } else {
            // problem!!!!!
            [one removeObject:object]; // remove "manually added" usernames that are now in the username list ("Selectable")
        }
    }
    
    [[NSUserDefaults standardUserDefaults]setObject:one forKey:addedUsernamesListKey];
    
    [ad.theFetchedUsernames sortUsingSelector:@selector(caseInsensitiveCompare:)];
    [ad cacheFetchedUsernames];
}

- (void)fetchFriends {
    
    AppDelegate *ad = kAppDelegate;
    
    NSArray *userInfo = [self getFriends];
    
    NSMutableArray *uniqueArray = [[NSMutableArray alloc]init];
    
    uniqueArray = [NSMutableArray arrayWithArray:[[NSSet setWithArray:userInfo]allObjects]];

    if (userInfo.count == 0) {
        [self performSelectorOnMainThread:@selector(enableButtons) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [ad makeSureUsernameListArraysAreNotNil];
    
    [ad.theFetchedUsernames removeAllObjects];

    for (NSString *string in [userInfo mutableCopy]) {
        [ad.theFetchedUsernames addObject:string];
    }
    
    [ad.theFetchedUsernames writeToFile:[kCachesDirectory stringByAppendingPathComponent:@"cached_list_twitter_friends.plist"] atomically:YES]; // this way you can compare to the ORIGINAL list of friends and not wind up with any data dumb fuckings around
    
    [self updateList];
    
    [self performSelectorOnMainThread:@selector(enableButtons) withObject:nil waitUntilDone:NO];
}

- (void)friendFetchFinished {
    [self enableButtons];
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    [self kickoffUsernameGrab];
}

- (void)pullToRefreshViewWasShown:(PullToRefreshView *)view {
    [pull setSubtitleText:@"Twitter Friends"];
}

- (void)updateCounter {
    NSMutableArray *array = usernamesListArray;
    int count = array.count;
    counter.text = [NSString stringWithFormat:@"%d/5",count];
}

- (IBAction)resetTwitterUsers {
    
    NSMutableArray *usernames = usernamesListArray;
    NSMutableArray *addedUsernames = addedUsernamesListArray;
    
    NSMutableArray *deletedArray = kDBSyncDeletedTArray;
    
    for (id username in [usernames mutableCopy]) {
        
        if ([self.savedSelectedArray containsObject:username]) {
            if ([usernames containsObject:username]) {
                [deletedArray addObject:username];
            }
            
            if ([addedUsernames containsObject:username] && ![deletedArray containsObject:username]) {
                [deletedArray addObject:username];
            }
        }
    }
    [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
    
    AppDelegate *ad = kAppDelegate;
    
    [ad.theFetchedUsernames removeObjectsInArray:addedUsernames];
    [addedUsernames removeAllObjects];
    [[NSUserDefaults standardUserDefaults]setObject:addedUsernames forKey:addedUsernamesListKey];
    
    
    [usernames removeAllObjects];
    [[NSUserDefaults standardUserDefaults]setObject:usernames forKey:usernamesListKey];
    [theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    
    [ad removeTwitterFromTimeline];
    [ad reloadMainTableView];
    
    [self updateCounter];
}

- (IBAction)showAddUsernameAlertView {
    
    NSMutableArray *usernames = usernamesListArray;
    int count = usernames.count;
    
    if (count >= 5) {
        [self flashLabelTableView];
        return;
    }
    
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Add User to Watch" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *avTF = [av textFieldAtIndex:0];
    
    [avTF setPlaceholder:@"Enter username..."];
    [avTF setKeyboardAppearance:UIKeyboardAppearanceAlert];
    [avTF setAutocorrectionType:UITextAutocorrectionTypeNo];
    [avTF setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [avTF setReturnKeyType:UIReturnKeyGo];
    [avTF setClearButtonMode:UITextFieldViewModeWhileEditing];

    [av show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.firstOtherButtonIndex == buttonIndex) {
        NSString *username = [alertView textFieldAtIndex:0].text;
        [self manuallyAddUsername:username];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    NSString *inputText = [alertView textFieldAtIndex:0].text;
    if (inputText.length > 0) {
        return YES;
    } 
        
    return NO;
}

- (void)flashLabel {
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:0.5];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor whiteColor] afterDelay:0.6];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:0.7];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor whiteColor] afterDelay:0.8];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:0.9];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor whiteColor] afterDelay:1.0];
}

- (void)flashLabelTableView {
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:0.0];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor whiteColor] afterDelay:0.1];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:0.2];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor whiteColor] afterDelay:0.3];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:0.4];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor whiteColor] afterDelay:0.5];
}

- (void)manuallyAddUsername:(NSString *)username {

    NSString *usernameToAdd = username;
    
    if ([usernameToAdd hasPrefix:@"@"]) {
        usernameToAdd = [usernameToAdd substringFromIndex:1];
    }
    
    if (usernameToAdd.length == 0) {
        return;
    }
    
    NSMutableArray *deletedArray = kDBSyncDeletedTArray;
    
    if ([deletedArray containsObject:usernameToAdd]) {
        [deletedArray removeObject:usernameToAdd];
    }
    
    [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
    
    NSMutableArray *usernames = usernamesListArray;
    
    if (usernames.count < 5) {
        AppDelegate *ad = kAppDelegate;
        
        if ([ad.theFetchedUsernames containsObject:usernameToAdd]) { // fetched from twitter, but unchecked
            NSMutableArray *usernames = usernamesListArray;

            if (![usernames containsObject:usernameToAdd]) {
                [usernames addObject:usernameToAdd];
                [theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[ad.theFetchedUsernames indexOfObject:usernameToAdd] inSection:0]].accessoryType = UITableViewCellAccessoryCheckmark;
                [[NSUserDefaults standardUserDefaults]setObject:usernames forKey:usernamesListKey];
            }
            return;
        }
        
        if (![ad.theFetchedUsernames containsObject:usernameToAdd]) { // not fetched from twitter
            NSMutableArray *addedUsernames = addedUsernamesListArray;
            [addedUsernames addObject:usernameToAdd];
            [[NSUserDefaults standardUserDefaults]setObject:addedUsernames forKey:addedUsernamesListKey];
        }
        
        [usernames addObject:usernameToAdd];
        [[NSUserDefaults standardUserDefaults]setObject:usernames forKey:usernamesListKey];
        [ad.theFetchedUsernames addObject:usernameToAdd];
        [ad.theFetchedUsernames sortUsingSelector:@selector(caseInsensitiveCompare:)];
        [theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [self flashLabel];
    }
    [self updateCounter];
}

- (void)kickoffUsernameGrab {
    
    if (![FHSTwitterEngine isConnectedToInternet]) {
        if (pull.state != kPullToRefreshViewStateNormal) {
            [pull finishedLoading];
        }
        qAlert(@"Error", @"The Internet connection appears to be offline.");
        return;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [NSThread detachNewThreadSelector:@selector(fetchFriends) toTarget:self withObject:nil];
    
    back.enabled = NO;
    reset.enabled = NO;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    AppDelegate *ad = kAppDelegate;
    int fetched = ad.theFetchedUsernames.count;
    return fetched;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell3";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    AppDelegate *ad = kAppDelegate;
    
    NSString *username = [ad.theFetchedUsernames objectAtIndex:indexPath.row];
    
    NSMutableArray *usernames = usernamesListArray;
    
    if ([usernames containsObject:username]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = [@"@" stringByAppendingString:username];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableArray *usernames = usernamesListArray;
    
    AppDelegate *ad = kAppDelegate;
    NSString *username = [ad.theFetchedUsernames objectAtIndex:indexPath.row];
    
    if (![usernames containsObject:username]) {
        if (usernames.count < 5) {
            [usernames addObject:username];
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
            
            NSMutableArray *deletedArray = kDBSyncDeletedTArray;
            
            if ([usernames containsObject:username]) {
                [deletedArray removeObject:username];
            }
            
            [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
            
            [[NSUserDefaults standardUserDefaults]setObject:usernames forKey:usernamesListKey];
        } else {
            [self flashLabelTableView];
        }
        
    } else {
        
        NSMutableArray *addedUsernames = addedUsernamesListArray;
        NSMutableArray *deletedArray = kDBSyncDeletedTArray;
        
        
        // added and deselected while the window is open
        if (![self.savedSelectedArray containsObject:username]) {
            [usernames removeObject:username];
            [[NSUserDefaults standardUserDefaults]setObject:usernames forKey:usernamesListKey];
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
            [self updateCounter];
            if ([addedUsernames containsObject:username]) {
                [addedUsernames removeObject:username];
                [[NSUserDefaults standardUserDefaults]setObject:addedUsernames forKey:addedUsernamesListKey];
                [ad.theFetchedUsernames removeObject:username];
                [theTableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section], nil] withRowAnimation:UITableViewRowAnimationLeft];
            }
            [theTableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }
        
        if ([usernames containsObject:username]) {
            [deletedArray addObject:username];
        }
        
        if ([addedUsernames containsObject:username] && ![deletedArray containsObject:username]) {
            [deletedArray addObject:username];
        }
        
        [[NSUserDefaults standardUserDefaults]setObject:deletedArray forKey:kDBSyncDeletedTArrayKey];
        
        [usernames removeObject:username];
        
        [[NSUserDefaults standardUserDefaults]setObject:usernames forKey:usernamesListKey];
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        
            
        if ([addedUsernames containsObject:username]) {
            [addedUsernames removeObject:username];
            [[NSUserDefaults standardUserDefaults]setObject:addedUsernames forKey:addedUsernamesListKey];
            [ad.theFetchedUsernames removeObject:username];
            [theTableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section], nil] withRowAnimation:UITableViewRowAnimationLeft];
        }
    }
    
    [self updateCounter];
    [theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)enableButtons {
    [kAppDelegate hideHUD];
    self.back.enabled = YES;
    self.reset.enabled = YES;
    if (pull.state != kPullToRefreshViewStateNormal) {
        [pull finishedLoading];
    }
    [theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [kAppDelegate makeSureUsernameListArraysAreNotNil];
    [self updateCounter];
    
    pull = [[PullToRefreshView alloc]initWithScrollView:theTableView];
    [pull setDelegate:self];
    [theTableView addSubview:pull];

    AppDelegate *ad = kAppDelegate;
    
    if (![ad.engine isAuthorized]) {
        [ad.engine loadAccessToken];
    }
    
    self.savedSelectedArray = usernamesListArray;
    
    if (ad.theFetchedUsernames.count == 0) {
        if ([ad.engine isAuthorized]) {
            [ad showHUDWithTitle:@"Loading..."];
            [self kickoffUsernameGrab];
        }
    } else {
        [self updateList];
    }
}

- (IBAction)back:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
