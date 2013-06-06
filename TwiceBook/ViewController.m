//
//  ViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/3/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ViewController.h"
#import "NSString+URLEncoding.h"

@implementation ViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    self.theTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-44)];
    _theTableView.delegate = self;
    _theTableView.dataSource = self;
    [self.view addSubview:_theTableView];
    [self.view bringSubviewToFront:_theTableView];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"TwoFace"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(showCompose)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Prefs" style:UIBarButtonItemStyleBordered target:self action:@selector(showPrefs)];
    [bar pushNavigationItem:topItem animated:NO];
    
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(90, 0, 160, 44);
    [button addTarget:self action:@selector(showVersion) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    [self.view bringSubviewToFront:button];
    
    [self loadTimelineViewDidLoadThreaded];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadTableView) name:@"reloadTableView" object:nil];
    
    self.pull = [[PullToRefreshView alloc]initWithScrollView:_theTableView];
    [_pull setDelegate:self];
    [_theTableView addSubview:_pull];
}

//
// Finished fetching posts and statuses
//

- (void)clearImageCachesIfNecessary {
    double time = [[NSDate date]timeIntervalSince1970];
    double previousTime = [[NSUserDefaults standardUserDefaults]doubleForKey:@"previousClearTime"];
    double remainder = time-previousTime; 
    if (remainder > 172800) { // 2 days (172800 seconds)
        [[NSUserDefaults standardUserDefaults]setDouble:time forKey:@"previousClearTime"];
        [Cache clearImageCache];
        [[NSFileManager defaultManager]removeItemAtPath:[Settings invalidUsersCachePath] error:nil];
    }
}

- (void)reflectAction {
    
    finishedLoadingTwitter = YES;
    facebookDone = YES;
    
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            [self clearImageCachesIfNecessary];
        }
    });

    [self sortedTimeline];

    [self.pull finishedLoading];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    
    __block NSMutableArray *invalidUsers = [[Cache sharedCache]invalidUsers];
    
    if (invalidUsers.count > 0) {
        NSString *protectedUserString = [@"@" stringByAppendingString:[invalidUsers componentsJoinedByString:@", @"]];
        protectedUserString = [protectedUserString substringToIndex:protectedUserString.length-3];
        NSString *message = [NSString stringWithFormat:@"The following users are invalid or have their tweets protected:\n\n%@\n\n Would you like to remove them from your watched list?",protectedUserString];
        
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Protected Users" message:message completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
            
            if (buttonIndex == 0) {
                NSMutableDictionary *cachedUsers = [NSMutableDictionary dictionaryWithContentsOfFile:[Settings invalidUsersCachePath]];
                
                if (cachedUsers.count > 0) {
                    [cachedUsers removeObjectsForKeys:invalidUsers];
                    [cachedUsers writeToFile:[Settings invalidUsersCachePath] atomically:YES];
                }
            }
            
            if (buttonIndex == 1) {
                NSMutableArray *addedUsers = [Settings addedTwitterUsernames];
                NSMutableArray *selectedUsers = [Settings selectedTwitterUsernames];
                
                for (NSString *obj in invalidUsers) {
                    if ([addedUsers containsObject:obj]) {
                        [addedUsers removeObject:obj];
                        
                        if ([[[Cache sharedCache]twitterFriends]containsObject:obj]) {
                            [[[Cache sharedCache]twitterFriends]removeObject:obj];
                        }
                    }
                    
                    if ([selectedUsers containsObject:obj]) {
                        [selectedUsers removeObject:obj];
                    }
                }

                [[NSUserDefaults standardUserDefaults]setObject:addedUsers forKey:kAddedUsernamesListKey];
                [[NSUserDefaults standardUserDefaults]setObject:selectedUsers forKey:kSelectedUsernamesListKey];
            }
        } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Remove", nil];
        [av show];
        [[[Cache sharedCache]invalidUsers]removeAllObjects];
    }
    
    if (errorEncounteredWhileLoading) {
        qAlert(@"Errors Encountered", @"There were some errors while fetching some tweets and statuses.");
    }
}

- (BOOL)isLoadingPosts {
    AppDelegate *ad = [Settings appDelegate];
    
    BOOL facebookDoneD = facebookDone;
    BOOL twitterDone = finishedLoadingTwitter;
    
    if (![ad.facebook isSessionValid]) {
        facebookDoneD = YES;
    }
    
    if (![[FHSTwitterEngine sharedEngine]isAuthorized]) {
        twitterDone = YES;
    }
    
    if (facebookDoneD && twitterDone) {
        return NO;
    }
    return YES;
}

- (void)reflectCompletedFetchingIfDoneFetching {
    if (![self isLoadingPosts]) {
        [self reflectAction];
    }
}


//
// Facebook Posts
//

- (void)fetchPostsForIDs:(NSArray *)identifiers {
    
    if (identifiers.count == 0) {
        facebookDone = YES;
        return;
    }
    
    facebookDone = NO;
    
    AppDelegate *ad = [Settings appDelegate];
    
    NSString *reqString = @"[";
    
    for (NSString *identifier in identifiers) {
        NSString *req = [NSString stringWithFormat:@"{\"method\":\"GET\",\"relative_url\":\"%@/feed?&date_format=U&limit=25\"}",identifier];
        
        if ([identifiers indexOfObject:identifier] != (int)identifiers.count-1) {
            req = [req stringByAppendingString:@","];
        }
        reqString = [reqString stringByAppendingString:req];
    }
    
    reqString = [reqString stringByAppendingString:@"]"];
    
    NSString *string = [NSString stringWithFormat:@"https://graph.facebook.com/?batch=%@&access_token=%@",[reqString URLEncodedString],ad.facebook.accessToken];
    
    NSURL *url = [NSURL URLWithString:string];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            facebookDone = YES;
            errorEncounteredWhileLoading = YES;
        } else {
            id parsedJSONResponse = removeNull([NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);
            [self parseResult:parsedJSONResponse];
        }
    }];
}

- (void)parseResult:(id)result {
    
    if ([result objectForKey:@"error"]) {
        errorEncounteredWhileLoading = YES;
        return;
    }
    
    for (NSDictionary *dictionary in result) {
        id parsedJSONResponse = removeNull([NSJSONSerialization JSONObjectWithData:[[dictionary objectForKey:@"body"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil]);
        
        NSMutableArray *parsedPosts = [NSMutableArray array];
        
        NSDictionary *postsDict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)parsedJSONResponse];
        NSMutableArray *data = [postsDict objectForKey:@"data"];
        
        for (NSMutableDictionary *post in data) {
            
            if ([post objectForKey:@"error"]) {
                errorEncounteredWhileLoading = YES;
                continue;
            }
            
            NSMutableDictionary *minusComments = [post mutableCopy];
            [minusComments removeObjectForKey:@"comments"];
            
            Status *status = [Status statusWithDictionary:minusComments];

            if (!([(NSString *)[post objectForKey:@"story"]length] > 0 && [status.type isEqualToString:@"status"])) {
                BOOL shouldAddPost = YES;
                
                if (status.message.length == 0) {
                    
                    if ([status.type isEqualToString:@"link"]) {
                        if (status.link.length == 0) {
                            shouldAddPost = NO;
                        }
                    }
                    
                    if ([status.type isEqualToString:@"photo"]) {
                        if (status.objectIdentifier.length == 0) {
                            shouldAddPost = NO;
                        }
                    }
                    
                    if ([status.type isEqualToString:@"status"]) {
                        shouldAddPost = NO;
                    }
                }
                
                if (shouldAddPost) {
                    [parsedPosts addObject:status];
                }
            }
        }
        [[[Cache sharedCache]timeline]addObjectsFromArray:parsedPosts];
        NSLog(@"Facebook: %d statuses fetched",parsedPosts.count);
    }
    facebookDone = YES;
    [self reflectCompletedFetchingIfDoneFetching];
}

//
// Timeline Loading methods
//

- (void)reloadCommon {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    errorEncounteredWhileLoading = NO;
    
    AppDelegate *ad = [Settings appDelegate];
        
    if (!ad.facebook) {
        [ad startFacebook];
    } else {
        if (![ad.facebook isSessionValid]) {
            [ad tryLoginFromSavedCreds];
        }
    }
    
    if (![[FHSTwitterEngine sharedEngine]isAuthorized]) {
        [[FHSTwitterEngine sharedEngine]loadAccessToken];
    }
    
    if (![FHSTwitterEngine isConnectedToInternet]) {
        [_pull finishedLoading];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        return;
    }

    if (![[FHSTwitterEngine sharedEngine]isAuthorized] && ![ad.facebook isSessionValid]) {
        [_pull finishedLoading];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        return;
    }
    
    [[[Cache sharedCache]timeline]removeAllObjects];
    [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)reloadCommonFetching {
    NSMutableArray *usernameArrayTwitter = [Settings selectedTwitterUsernames];
    NSArray *usernameArrayFacebook = [[Settings selectedFacebookFriends]allKeys];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    if (![FHSTwitterEngine isConnectedToInternet]) {
        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [_pull finishedLoading];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        return;
    }
    
    if (usernameArrayTwitter.count == 0 && usernameArrayFacebook.count == 0) {
        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [_pull finishedLoading];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    } else {
        
        if ([[FHSTwitterEngine sharedEngine]isAuthorized]) {
            [self getTweetsForUsernames:usernameArrayTwitter];
        }
        
        if ([[[Settings appDelegate]facebook]isSessionValid]) {
            [self fetchPostsForIDs:usernameArrayFacebook];
        }
    }
}

// 
// PullToRefreshView Delegate
//

- (void)pullToRefreshViewWasShown:(PullToRefreshView *)view {
    NSString *subtitle = @"";
    AppDelegate *ad = [Settings appDelegate];
    
    NSMutableArray *usernameArrayTwitter = [Settings selectedTwitterUsernames];
    NSArray *usernameArrayFacebook = [[Settings selectedFacebookFriends]allKeys];
    
    BOOL twitterIsAuthorized = [[FHSTwitterEngine sharedEngine]isAuthorized] && (usernameArrayTwitter.count > 0);
    BOOL facebookIsSessionValid = [ad.facebook isSessionValid] && (usernameArrayFacebook.count > 0);
    
    if (twitterIsAuthorized && !facebookIsSessionValid) {
        subtitle = @"Twitter";
    }
    
    if (!twitterIsAuthorized && facebookIsSessionValid) {
        subtitle = @"Facebook";
    }
    
    if (twitterIsAuthorized && facebookIsSessionValid) {
        subtitle = @"Twitter and Facebook";
    }
    
    if (!twitterIsAuthorized && !facebookIsSessionValid) {
        subtitle = @"Nothing to Load";
    }

    [_pull setSubtitleText:subtitle];
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    [self reloadCommon];
    
    if (![[FHSTwitterEngine sharedEngine]isAuthorized] && ![[[Settings appDelegate]facebook]isSessionValid]) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        return;
    }
    
    if (![FHSTwitterEngine isConnectedToInternet]) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        return;
    }
    
    [self reloadCommonFetching];
}

//
// Threaded Timeline Loading Methods
//

- (void)loadTimelineViewDidLoadThreaded {
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            
        
            dispatch_sync(GCDMainThread, ^{
                @autoreleasepool {
                    [self reloadCommon];
                    
                    if ([[Cache sharedCache]timeline].count > 0) {

                        AppDelegate *ad = [Settings appDelegate];
                        
                        if (![ad.facebook isSessionValid]) {
                            [ad removeFacebookFromTimeline];
                        }
                        
                        if (![[FHSTwitterEngine sharedEngine]isAuthorized]) {
                            [ad removeTwitterFromTimeline];
                        }
                        
                        [_pull finishedLoading];
                    }
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                }
            });
        }
    });
}

- (void)reloadTableView {
    [_theTableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    if ([[Cache sharedCache]timeline].count == 0) {
        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }
}

//
// Former IBActions
//

- (void)showVersion {
    AboutViewController *vc = [[AboutViewController alloc]init];
    [self presentModalViewController:vc animated:YES];
}

- (void)showPrefs {
    NewPrefs *p = [[NewPrefs alloc]init];
    [self presentModalViewController:p animated:YES];
}

- (void)showCompose {
    
    UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:@"Compose" completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {

        if ([[actionSheet buttonTitleAtIndex:buttonIndex]isEqualToString:@"Tweet"]) {
            ReplyViewController *composer = [[ReplyViewController alloc]initWithTweet:nil];
            [self presentModalViewController:composer animated:YES];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex]isEqualToString:@"Status"]) {
            ReplyViewController *composer = [[ReplyViewController alloc]initWithTweet:nil];
            composer.isFacebook = YES;
            [self presentModalViewController:composer animated:YES];
        }
        
    } cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    AppDelegate *ad = [Settings appDelegate];
    
    BOOL twitter = [[FHSTwitterEngine sharedEngine]isAuthorized];
    BOOL facebook = [ad.facebook isSessionValid];
    
    if (twitter) {
        [as addButtonWithTitle:@"Tweet"];
    }
    
    if (facebook) {
        [as addButtonWithTitle:@"Status"];
    }
    
    if (!facebook && !twitter) {
        as.title = @"Please log in";
        [as addButtonWithTitle:@"OK"];
        as.cancelButtonIndex = 1;
    } else {
        [as addButtonWithTitle:@"Cancel"];
        as.cancelButtonIndex = as.numberOfButtons-1;
    }
    
    [as showInView:ad.window];
}

//
// Timeline Methods
//

- (void)sortedTimeline {
    NSMutableArray *array = [[Cache sharedCache]timeline];
    NSMutableDictionary *the = [NSMutableDictionary dictionary];
    
    for (id item in array) {
        NSString *numberInArray = [NSString stringWithFormat:@"%d",(int)[array indexOfObject:item]];
        NSString *time = [NSString stringWithFormat:@"%f",[[item createdAt]timeIntervalSince1970]];
        [the setObject:numberInArray forKey:time];
    }
    
    NSMutableArray *arrayZ = [NSMutableArray arrayWithArray:[the allKeys]]; // contains sorted dates, use to fetch number in arrays
    [arrayZ sortUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"doubleValue" ascending:NO]]];
    NSMutableArray *penultimateArray = [NSMutableArray array]; // the other half of the NSMutableDictiony *the (the objects). Use this to finish off the sorting

    for (NSString *number in arrayZ) {
        [penultimateArray addObject:[the objectForKey:number]];
    }
    
    NSMutableArray *final = [NSMutableArray array]; // date sorted timeline!!! (backwards)
    
    for (NSString *string in penultimateArray) {
        [final addObject:[array objectAtIndex:[string intValue]]]; // array obj.. was timeline obj...
    }
    
    [[[Cache sharedCache]timeline]removeAllObjects];
    [[[Cache sharedCache]timeline]addObjectsFromArray:final];
}

// 
// Tweet Fetching Methods
//

- (void)getTweetsForUsernames:(NSArray *)usernames {
    
    finishedLoadingTwitter = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            
            NSMutableArray *tweets = [NSMutableArray array];
            
            NSMutableArray *usedTweetsFromCache = [NSMutableArray array];
            
            NSMutableArray *nonTimelineTweets = [[Cache sharedCache]nonTimelineTweets];
            
            for (NSString *username in usernames) {
                
                NSLog(@"TWITTER: Starting User: %@",username);
                
                id fetched = [[FHSTwitterEngine sharedEngine]getTimelineForUser:username isID:NO count:3];
                
                if ([fetched isKindOfClass:[NSError class]]) {
                    if ([(NSError *)fetched code] == 404) {
                        [[[Cache sharedCache]invalidUsers]addObject:username];
                    }
                }
                
                if ([fetched isKindOfClass:[NSArray class]]) {
                    
                    NSLog(@"TWITTER: fetched: %u",[(NSArray *)fetched count]);
                    
                    for (NSDictionary *dict in fetched) {
                        
                        Tweet *tweet = [Tweet tweetWithDictionary:dict];
                        
                        if (!tweet.inReplyToTweetIdentifier.length == 0) {
                            
                            id retrievedTweet = nil;
                            
                            if (nonTimelineTweets.count > 0) {
                                for (NSDictionary *dict in nonTimelineTweets) {
                                    if ([tweet.inReplyToTweetIdentifier isEqualToString:[dict objectForKey:@"in_reply_to_status_id_str"]]) {
                                        retrievedTweet = dict;
                                        break;
                                    }
                                }
                            }
                            
                            if (retrievedTweet == nil) {
                                retrievedTweet = [[FHSTwitterEngine sharedEngine]getDetailsForTweet:tweet.inReplyToTweetIdentifier];
                            }
                            
                            if ([retrievedTweet isKindOfClass:[NSDictionary class]]) {
                                Tweet *irt = [Tweet tweetWithDictionary:retrievedTweet];
                                [usedTweetsFromCache addObject:irt];
                                [tweets addObject:irt];
                                NSLog(@"TWITTER: Fetched Contextual Tweet: %@",irt.inReplyToTweetIdentifier);
                            } else if ([retrievedTweet isKindOfClass:[NSError class]]) {
                                errorEncounteredWhileLoading = YES;
                            }
                        }
                        
                        [tweets addObject:tweet];
                    }
                    
                    NSLog(@" ");
                    NSLog(@"-----------------------");
                    NSLog(@" ");
                }
            }
            
            [[[Cache sharedCache]nonTimelineTweets]removeAllObjects];
            [[[Cache sharedCache]nonTimelineTweets]addObjectsFromArray:usedTweetsFromCache];
            
            int duplicateCount = (tweets.count-[tweets arrayByRemovingDuplicates].count);
            
            if (duplicateCount > 0) {
                NSLog(@"TWITTER: Deleted %d duplicate tweets",duplicateCount);
                [tweets removeDuplicates];
            }

            [[[Cache sharedCache]timeline]addObjectsFromArray:tweets];

            finishedLoadingTwitter = YES;
            
            dispatch_sync(GCDMainThread, ^{
                @autoreleasepool {
                    [self reflectCompletedFetchingIfDoneFetching];
                };
            });
        };
    });
}


//
// UITableView Delegate
//

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableArray *timeline = [[Cache sharedCache]timeline];
    
    if (timeline.count > 0) {
        
        id item = [timeline objectAtIndex:indexPath.row];
        NSString *cellText = nil;
        
        if ([item isKindOfClass:[Status class]]) {
            Status *status = (Status *)item;
            cellText = (status.message.length > 0)?status.message:status.type;
        } else if ([item isKindOfClass:[Tweet class]]) {
            cellText = [(Tweet *)item text];
        }
        
        if (cellText.length > 140) {
            cellText = [[cellText substringToIndex:140]stringByAppendingString:@"..."];
        }

        CGSize labelSize = [cellText sizeWithFont:[UIFont systemFontOfSize:17] constrainedToSize:CGSizeMake(280, 1000) lineBreakMode:UILineBreakModeWordWrap];
        return labelSize.height+35;
    }
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int count = [[Cache sharedCache]timeline].count;
    return (count == 0)?1:count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * const CellIdentifier = @"Cell";

    AdditionalLabelCell *cell = (AdditionalLabelCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[AdditionalLabelCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
 
    cell.textLabel.highlightedTextColor = [UIColor blackColor];  
    cell.detailTextLabel.highlightedTextColor = [UIColor blackColor];
    
    cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:17];
    
    NSMutableArray *timeline = [[Cache sharedCache]timeline];
    
    if (oneIsCorrect(_pull.state == kPullToRefreshViewStateLoading, timeline.count == 0)) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.additionalLabel.text = nil;
        
        AppDelegate *ad = [Settings appDelegate];
        
        if (![[FHSTwitterEngine sharedEngine]isAuthorized]) {
            [ad loadAccessToken];
        }
            
        if (![ad.facebook isSessionValid]) {
            [ad tryLoginFromSavedCreds];
        }
        
        if (![[FHSTwitterEngine sharedEngine]isAuthorized] && ![ad.facebook isSessionValid]) {
            cell.textLabel.text = @"Not Logged in.";
            cell.detailTextLabel.text = @"You need to login in Prefs.";
        } else {
            if (oneIsCorrect([[[Settings selectedFacebookFriends]allKeys]count] > 0, [[Settings selectedTwitterUsernames]count] > 0)) {
                if (_pull.state == kPullToRefreshViewStateNormal) {
                    cell.textLabel.text = @"No Data";
                    cell.detailTextLabel.text = @"Please pull down to refresh.";
                } else {
                    cell.textLabel.text = @"Loading...";
                    cell.detailTextLabel.text = nil;
                }
            } else {
                cell.textLabel.text = @"No Users Selected";
                cell.detailTextLabel.text = @"Select users to watch in Prefs.";
            }
        }
    } else {
        
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        id tweetOrStatus = [timeline objectAtIndex:indexPath.row];

        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if ([tweetOrStatus isKindOfClass:[Status class]]) {
            Status *status = (Status *)tweetOrStatus;
            cell.additionalLabel.text = @"Facebook    ";
            cell.additionalLabel.textColor = [UIColor colorWithRed:59.0/255.0 green:89.0/255.0 blue:152.0/255.0 alpha:1.0];
            cell.textLabel.text = status.from.name;
            cell.detailTextLabel.text = status.message;
            
            if (cell.detailTextLabel.text.length == 0) {
                cell.detailTextLabel.text = [status.type stringByCapitalizingFirstLetter];
            }
            
        } else if ([tweetOrStatus isKindOfClass:[Tweet class]]) {
            Tweet *tweet = (Tweet *)tweetOrStatus;
            cell.additionalLabel.text = @"Twitter    ";
            cell.additionalLabel.textColor = [UIColor colorWithRed:64.0/255.0 green:153.0/255.0 blue:1 alpha:1.0];
            cell.textLabel.text = tweet.user.name;
            cell.detailTextLabel.text = tweet.text;
        }

        if (cell.detailTextLabel.text.length > 140) {
            cell.detailTextLabel.text = [[cell.detailTextLabel.text substringToIndex:140]stringByAppendingString:@"..."];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [_theTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSMutableArray *timeline = [[Cache sharedCache]timeline];
    
    if (timeline.count == 0) {
        return;
    }

    NSString *labelText = [_theTableView cellForRowAtIndexPath:indexPath].textLabel.text;
    
    if (([labelText isEqualToString:@"Not Logged in."] || [labelText isEqualToString:@"Loading..."] || [labelText isEqualToString:@"No Users Selected"])) {
        return;
    }
    
    id tappedItem = [timeline objectAtIndex:indexPath.row];
    
    if ([tappedItem isKindOfClass:[Status class]]) {
        PostDetailViewController *p = [[PostDetailViewController alloc]initWithPost:tappedItem];
        [self presentModalViewController:p animated:YES];
    } else if ([tappedItem isKindOfClass:[Tweet class]]) {
        TweetDetailViewController *d = [[TweetDetailViewController alloc]initWithTweet:tappedItem];
        [self presentModalViewController:d animated:YES];
    }
}

@end
