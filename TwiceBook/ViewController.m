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
    self.theTableView.delegate = self;
    self.theTableView.dataSource = self;
    [self.view addSubview:self.theTableView];
    [self.view bringSubviewToFront:self.theTableView];
    
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
    
    self.protectedUsers = [NSMutableArray array];
    
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
        [kAppDelegate clearImageCache];
        [[NSFileManager defaultManager]removeItemAtPath:[kCachesDirectory stringByAppendingPathComponent:@"cached_invalid_users.plist"] error:nil];
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
    
    AppDelegate *ad = kAppDelegate;

    [self sortedTimeline];
    [ad cacheTimeline];

    [self.pull finishedLoading];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    
    if (self.protectedUsers.count > 0) {
        NSString *protectedUserString = @"";
        for (NSString *username in self.protectedUsers) {
            protectedUserString = [protectedUserString stringByAppendingFormat:@"@%@, ",username];
        }
        protectedUserString = [protectedUserString substringToIndex:protectedUserString.length-2];
        NSString *message = [NSString stringWithFormat:@"The following users are invalid or have their tweets protected:\n\n%@\n\n Would you like to remove them from your watched list?",protectedUserString];
        
        __block NSString *userInQuestion = [protectedUserString mutableCopy];
        __block NSMutableArray *protectedUsersBlock = [self.protectedUsers mutableCopy];
        
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Protected Users" message:message completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
            
            if (buttonIndex == 0) {
                NSMutableDictionary *cachedUsers = [NSMutableDictionary dictionaryWithContentsOfFile:[kCachesDirectory stringByAppendingPathComponent:@"cached_invalid_users.plist"]];
                
                if (cachedUsers.count == 0) {
                    cachedUsers = [NSMutableDictionary dictionary];
                } else {
                    [cachedUsers removeObjectForKey:userInQuestion];
                }
                
                [cachedUsers writeToFile:[kCachesDirectory stringByAppendingPathComponent:@"cached_invalid_users.plist"] atomically:YES];
            }
            
            if (buttonIndex == 1) {
                NSMutableArray *addedUsers = addedUsernamesListArray;
                NSMutableArray *selectedUsers = usernamesListArray;
                
                for (NSString *obj in protectedUsersBlock) {
                    if ([addedUsers containsObject:obj]) {
                        [addedUsers removeObject:obj];
                        
                        if ([ad.theFetchedUsernames containsObject:obj]) {
                            [ad.theFetchedUsernames removeObject:obj];
                        }
                    }
                    
                    if ([selectedUsers containsObject:obj]) {
                        [selectedUsers removeObject:obj];
                    }
                }
                
                if (addedUsers.count > 0) {
                    [[NSUserDefaults standardUserDefaults]setObject:addedUsers forKey:addedUsernamesListKey];
                }
                
                if (selectedUsers.count > 0) {
                    [[NSUserDefaults standardUserDefaults]setObject:selectedUsers forKey:usernamesListKey];
                }
            }
        } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Remove", nil];
        [av show];
        [self.protectedUsers removeAllObjects];
    }
    
    if (errorEncounteredWhileLoading) {
        qAlert(@"Errors Encountered", @"There were some errors while fetching some tweets and statuses.");
    }
}

- (BOOL)isLoadingPosts {
    AppDelegate *ad = kAppDelegate;
    
    BOOL facebookDoneD = facebookDone;
    BOOL twitterDone = finishedLoadingTwitter;
    
    if (![ad.facebook isSessionValid]) {
        facebookDoneD = YES;
    }
    
    if (![ad.engine isAuthorized]) {
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
    
    AppDelegate *ad = kAppDelegate;
    
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
    
    for (NSDictionary *dictionary in result) {
        NSString *body = [dictionary objectForKey:@"body"];
        
        NSData *bodydata = [body dataUsingEncoding:NSUTF8StringEncoding];
        
        id parsedJSONResponse = removeNull([NSJSONSerialization JSONObjectWithData:bodydata options:NSJSONReadingMutableContainers error:nil]);
        
        NSMutableArray *parsedPosts = [NSMutableArray array];
        
        NSDictionary *postsDict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)parsedJSONResponse];
        NSMutableArray *data = [postsDict objectForKey:@"data"];
        
        for (NSMutableDictionary *post in data) {
            
            if ([post objectForKey:@"error"]) {
                errorEncounteredWhileLoading = YES;
                continue;
            }
            
            NSMutableDictionary *restructured = [[NSMutableDictionary alloc]init];
            
            NSString *toID = [[[[post objectForKey:@"to"]objectForKey:@"data"]firstObjectA]objectForKey:@"id"];
            NSString *toName = [[[[post objectForKey:@"to"]objectForKey:@"data"]firstObjectA]objectForKey:@"name"];
            NSString *objectID = [post objectForKey:@"object_id"];
            NSString *imageIcon = [post objectForKey:@"icon"];
            NSString *fromName = [[post objectForKey:@"from"]objectForKey:@"name"];
            NSString *fromID = [[post objectForKey:@"from"]objectForKey:@"id"];
            NSString *message = [[post objectForKey:@"message"]stringByTrimmingWhitespace];
            NSString *type = [post objectForKey:@"type"];
            NSString *imageURL = [post objectForKey:@"picture"];
            NSString *link = [post objectForKey:@"link"];
            NSString *linkName = [post objectForKey:@"name"];
            NSString *linkCaption = [post objectForKey:@"caption"];
            NSString *linkDescription = [post objectForKey:@"description"];
            NSString *actionsAvailable = ([(NSArray *)[post objectForKey:@"actions"]count] > 0)?@"yes":@"no";
            NSString *postID = [post objectForKey:@"id"];
            NSDate *created_time = [NSDate dateWithTimeIntervalSince1970:[[post objectForKey:@"updated_time"]floatValue]+1800];
            
            [restructured setValue:toID forKey:@"to_id"];
            [restructured setValue:toName forKey:@"to_name"];
            [restructured setValue:objectID forKey:@"object_id"];
            [restructured setValue:imageIcon forKey:@"icon"];
            [restructured setValue:postID forKey:@"id"];
            [restructured setValue:type forKey:@"type"];
            [restructured setValue:created_time forKey:@"poster_created_time"];
            [restructured setValue:fromName forKey:@"poster_name"];
            [restructured setValue:fromID forKey:@"poster_id"];
            [restructured setValue:message forKey:@"message"];
            [restructured setValue:imageURL forKey:@"image_url"];
            [restructured setValue:link forKey:@"link"];
            [restructured setValue:linkName forKey:@"link_name"];
            [restructured setValue:linkCaption forKey:@"link_caption"];
            [restructured setValue:linkDescription forKey:@"link_description"];
            [restructured setValue:actionsAvailable forKey:@"actions_available"];
            
            if ([type isEqualToString:@"link"]) {
                message = [post objectForKey:@"story"];
            }
            
            [restructured setValue:@"facebook" forKey:@"social_network_name"];
            
            // Whether or not the status being parsed is one of those dumbass posts that says "Person X is friends with Person Y."
            if (!([(NSString *)[post objectForKey:@"story"]length] > 0 && [type isEqualToString:@"status"])) {
                
                BOOL shouldAddPost = YES;
                
                if (message.length == 0) {
                    NSString *story = [post objectForKey:@"story"];
                    NSString *description = [post objectForKey:@"description"];
                    
                    if (description.length > 0) {
                        [restructured setObject:description forKey:@"message"];
                        message = [description copy];
                        
                    } else if (story.length > 0) {
                        [restructured setObject:story forKey:@"message"];
                        message = [story copy];
                    }
                }
                
                if (message.length == 0) {
                    
                    if ([type isEqualToString:@"link"]) {
                        if (link.length == 0) {
                            shouldAddPost = NO;
                        }
                    }
                    
                    if ([type isEqualToString:@"photo"]) {
                        if (objectID.length == 0) {
                            shouldAddPost = NO;
                        }
                    }
                    
                    if ([type isEqualToString:@"status"]) {
                        shouldAddPost = NO;
                    }
                }
                
                if (shouldAddPost) {
                    [parsedPosts addObject:restructured];
                }
            }
        }
        [self.timeline addObjectsFromArray:parsedPosts];
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

    if (self.timeline.count == 0) {
        self.timeline = [NSMutableArray array];
    }
    
    errorEncounteredWhileLoading = NO;
    
    AppDelegate *ad = kAppDelegate;
        
    if (!ad.facebook) {
        [ad startFacebook];
    } else {
        if (![ad.facebook isSessionValid]) {
            [ad tryLoginFromSavedCreds];
        }
    }
    
    if (![ad.engine isAuthorized]) {
        [ad.engine loadAccessToken];
    }
    
    if (![FHSTwitterEngine isConnectedToInternet]) {
        [self.pull finishedLoading];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        return;
    }

    if (![ad.engine isAuthorized] && ![ad.facebook isSessionValid]) {
        [self.pull finishedLoading];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        return;
    }
    
    [self.timeline removeAllObjects];
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)reloadCommonFetching {
    AppDelegate *ad = kAppDelegate;
    NSMutableArray *usernameArrayTwitter = [usernamesListArray mutableCopy];
    NSArray *usernameArrayFacebook = [kSelectedFriendsDictionary allKeys];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    if (![FHSTwitterEngine isConnectedToInternet]) {
        [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.pull finishedLoading];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        return;
    }
    
    if (usernameArrayTwitter.count == 0 && usernameArrayFacebook.count == 0) {
        [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.pull finishedLoading];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    } else {
        
        if ([ad.engine isAuthorized]) {
            [self getTweetsForUsernames:usernameArrayTwitter];
        }
        
        if ([ad.facebook isSessionValid]) {
            [self fetchPostsForIDs:usernameArrayFacebook];
        }
    }
}

- (void)reloadTimelinePTR {
    [self reloadCommon];
    
    if (![[kAppDelegate engine]isAuthorized] && ![[kAppDelegate facebook]isSessionValid]) {
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
// PullToRefreshView Delegate
//

- (void)pullToRefreshViewWasShown:(PullToRefreshView *)view {
    NSString *subtitle = @"";
    AppDelegate *ad = kAppDelegate;
    
    NSMutableArray *usernameArrayTwitter = usernamesListArray;
    NSArray *usernameArrayFacebook = [kSelectedFriendsDictionary allKeys];
    
    BOOL twitterIsAuthorized = [ad.engine isAuthorized] && (usernameArrayTwitter.count > 0);
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

    [self.pull setSubtitleText:subtitle];
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    [self reloadTimelinePTR];
}

//
// Threaded Timeline Loading Methods
//

- (void)loadTimelineViewDidLoadThreaded {
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            AppDelegate *ad = kAppDelegate;
            
            [ad makeSureUsernameListArraysAreNotNil];
            
            NSMutableArray *savedTimeline = [ad getCachedTimeline];
        
            dispatch_sync(GCDMainThread, ^{
                @autoreleasepool {
                    [self reloadCommon];
                    
                    if (savedTimeline.count > 0) {
                        [_timeline addObjectsFromArray:savedTimeline];
                        
                        BOOL shouldRecacheTimeline = NO;
                        
                        if (![ad.facebook isSessionValid]) {
                            [ad removeFacebookFromTimeline];
                            shouldRecacheTimeline = YES;
                        }
                        
                        if (![ad.engine isAuthorized]) {
                            [ad removeTwitterFromTimeline];
                            shouldRecacheTimeline = YES;
                        }
                        
                        if (shouldRecacheTimeline) {
                            [ad cacheTimeline];
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
    if (_timeline.count == 0) {
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
    
    AppDelegate *ad = kAppDelegate;
    
    BOOL twitter = [ad.engine isAuthorized];
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
    
    NSMutableArray *array = [_timeline mutableCopy];
    NSMutableDictionary *the = [NSMutableDictionary dictionary];
    
    for (id item in array) {
        NSString *numberInArray = [NSString stringWithFormat:@"%d",(int)[array indexOfObject:item]];
        
        NSDate *date = nil;
        
        if ([item isKindOfClass:[Status class]]) {
            date = [item objectForKey:@"poster_created_time"];
        } else {
            date = twitterDateFromString([(Tweet *)item createdAt]);
        }
        
        NSString *time = [NSString stringWithFormat:@"%f",[date timeIntervalSince1970]];
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
    
    [_timeline removeAllObjects];
    [_timeline addObjectsFromArray:final];
}

// 
// Tweet Fetching Methods
//

- (void)getTweetsForUsernames:(NSArray *)usernames {
    
    AppDelegate *ad = kAppDelegate;
    
    finishedLoadingTwitter = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            
            NSMutableArray *tweets = [NSMutableArray array];
            
            NSString *irtTweetCachePath = [kCachesDirectory stringByAppendingPathComponent:@"cached_replied_to_tweets.plist"];
            NSMutableArray *cachedRepliedToTweets = [NSMutableArray arrayWithContentsOfFile:irtTweetCachePath];
            
            if (cachedRepliedToTweets == nil) {
                cachedRepliedToTweets = [NSMutableArray array];
            }
            
            NSMutableArray *usedTweetsFromCache = [NSMutableArray array];
            
            for (NSString *username in usernames) {
                
                NSLog(@"TWITTER: Starting User: %@",username);
                
                id fetched = [ad.engine getTimelineForUser:username isID:NO count:3];
                
                if ([fetched isKindOfClass:[NSError class]]) {
                    if ([(NSError *)fetched code] == 404) {
                        [self.protectedUsers addObject:username];
                    }
                }
                
                if ([fetched isKindOfClass:[NSArray class]]) {
                    
                    NSLog(@"TWITTER: fetched: %u",[(NSArray *)fetched count]);
                    
                    for (NSDictionary *dict in fetched) {
                        
                        Tweet *tweet = [Tweet tweetWithDictionary:dict];
                        
                        if (!tweet.inReplyToTweetIdentifier.length == 0) {
                            
                            id retrievedTweet = nil;
                            
                            if (cachedRepliedToTweets.count > 0) {
                                for (NSDictionary *dict_cached in cachedRepliedToTweets) {
                                    if ([tweet.inReplyToTweetIdentifier isEqualToString:[dict_cached objectForKey:@"in_reply_to_status_id_str"]]) {
                                        retrievedTweet = dict_cached;
                                        break;
                                    }
                                }
                            }
                            
                            if (retrievedTweet == nil) {
                                retrievedTweet = [ad.engine getDetailsForTweet:tweet.inReplyToTweetIdentifier];
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
            
            [usedTweetsFromCache writeToFile:irtTweetCachePath atomically:YES];
            
            int duplicateCount = (tweets.count-[tweets arrayByRemovingDuplicates].count);
            
            if (duplicateCount > 0) {
                NSLog(@"TWITTER: Deleted %d duplicate tweets",duplicateCount);
                [tweets removeDuplicates];
            }

            [_timeline addObjectsFromArray:tweets];

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
    
    if (_timeline.count > 0) {
        
        id item = [_timeline objectAtIndex:indexPath.row];
        NSString *cellText = nil;
        
        if ([item isKindOfClass:[Status class]]) {
            cellText = [item objectForKey:@"message"];
            
            if (cellText.length == 0) {
                cellText = [item objectForKey:@"type"];
            }
        } else {
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
    int count = _timeline.count;
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
    
    if (oneIsCorrect(_pull.state == kPullToRefreshViewStateLoading, _timeline.count == 0)) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.additionalLabel.text = nil;
        
        AppDelegate *ad = kAppDelegate;
        
        if (![ad.engine isAuthorized]) {
            [ad loadAccessToken];
        }
            
        if (![ad.facebook isSessionValid]) {
            [ad tryLoginFromSavedCreds];
        }
        
        if (![ad.engine isAuthorized] && ![ad.facebook isSessionValid]) {
            cell.textLabel.text = @"Not Logged in.";
            cell.detailTextLabel.text = @"You need to login in Prefs.";
        } else {
            if (oneIsCorrect(kSelectedFriendsDictionary.allKeys.count > 0, usernamesListArray.count > 0)) {
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
        id tweetOrStatus = [_timeline objectAtIndex:indexPath.row];

        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if ([tweetOrStatus isKindOfClass:[Status class]]) {
            cell.additionalLabel.text = @"Facebook    ";
            cell.additionalLabel.textColor = [UIColor colorWithRed:59.0/255.0 green:89.0/255.0 blue:152.0/255.0 alpha:1.0];
            cell.textLabel.text = [tweetOrStatus objectForKey:@"poster_name"];
            cell.detailTextLabel.text = [tweetOrStatus objectForKey:@"message"];
            
            if (cell.detailTextLabel.text.length == 0) {
                cell.detailTextLabel.text = [[tweetOrStatus objectForKey:@"type"]stringByCapitalizingFirstLetter];
            }
            
        } else {
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
    
    if (_timeline.count == 0) {
        return;
    }

    NSString *labelText = [_theTableView cellForRowAtIndexPath:indexPath].textLabel.text;
    
    if (([labelText isEqualToString:@"Not Logged in."] || [labelText isEqualToString:@"Loading..."] || [labelText isEqualToString:@"No Users Selected"])) {
        return;
    }
    
    id tappedItem = [_timeline objectAtIndex:indexPath.row];
    
    if ([tappedItem isKindOfClass:[Status class]]) {
        PostDetailViewController *p = [[PostDetailViewController alloc]initWithPost:tappedItem];
        [self presentModalViewController:p animated:YES];
    } else {
        TweetDetailViewController *d = [[TweetDetailViewController alloc]initWithTweet:tappedItem];
        [self presentModalViewController:d animated:YES];
    }
}

@end
