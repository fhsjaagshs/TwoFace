//
//  ViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/3/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ViewController.h"
#import "FHSTwitterEngine.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, PullToRefreshViewDelegate> {
    BOOL errorEncounteredWhileLoading;
    BOOL finishedLoadingTwitter;
    BOOL facebookDone;
}

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation ViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.theTableView = [[UITableView alloc]initWithFrame:screenBounds style:UITableViewStylePlain];
    _theTableView.backgroundColor = [UIColor clearColor];
    _theTableView.delegate = self;
    _theTableView.dataSource = self;
    _theTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _theTableView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    [self.view addSubview:_theTableView];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refreshTimeline:) forControlEvents:UIControlEventValueChanged];
    [_theTableView addSubview:_refreshControl];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"TwoFace"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(showCompose)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"\u2699" style:UIBarButtonItemStyleBordered target:self action:@selector(showPrefs)];
    [topItem.rightBarButtonItem setTitlePositionAdjustment:UIOffsetMake(0, 15.0f) forBarMetrics:UIBarMetricsDefault];
    [topItem.rightBarButtonItem setTitleTextAttributes:@{ UITextAttributeFont: [UIFont systemFontOfSize:24.0f] } forState:UIControlStateNormal];
    
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(90, 20, 160, 44);
    [button addTarget:self action:@selector(showVersion) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    [self.view bringSubviewToFront:button];
    
    [self initialTimelineCacheHit];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadTableView) name:@"reloadTableView" object:nil];
}

- (void)initialTimelineCacheHit {

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
    
    if ([[Cache sharedCache]timeline].count > 0) {
        if (![ad.facebook isSessionValid]) {
            [ad removeFacebookFromTimeline];
        }
        
        if (![[FHSTwitterEngine sharedEngine]isAuthorized]) {
            [ad removeTwitterFromTimeline];
        }
    }

    [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)refreshTimeline:(UIRefreshControl *)control {
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
        [control endRefreshing];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        return;
    }
    
    if (![[FHSTwitterEngine sharedEngine]isAuthorized] && ![ad.facebook isSessionValid]) {
        [control endRefreshing];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        return;
    }
    
    NSMutableArray *usernameArrayTwitter = [Settings selectedTwitterUsernames];
    NSArray *usernameArrayFacebook = [[Settings selectedFacebookFriends]allKeys];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    if (usernameArrayTwitter.count == 0 && usernameArrayFacebook.count == 0) {
        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [control endRefreshing];
    } else {
        [[[Cache sharedCache]timeline]removeAllObjects];
        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        
        if ([[FHSTwitterEngine sharedEngine]isAuthorized]) {
            [self getTweetsForUsernames:usernameArrayTwitter];
        }
        
        if ([ad.facebook isSessionValid]) {
            [self fetchPostsForIDs:usernameArrayFacebook];
        }
    }
}

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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            [self clearImageCachesIfNecessary];
        }
    });

    [self sortedTimeline];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];

    if ([[Cache sharedCache]invalidUsers].count > 0) {
        NSString *protectedUserString = [@"@" stringByAppendingString:[[[Cache sharedCache]invalidUsers]componentsJoinedByString:@", @"]];
        NSString *message = [NSString stringWithFormat:@"The following users are invalid or have their tweets protected:\n\n%@\n\n Would you like to remove them from your watched list?",protectedUserString];
        
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Protected Users" message:message completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
            
            if (buttonIndex == 0) {
                [[[Cache sharedCache]invalidUsers]removeAllObjects];
            }
            
            if (buttonIndex == 1) {
                
                NSMutableArray *addedUsers = [Settings addedTwitterUsernames];
                NSMutableArray *selectedUsers = [Settings selectedTwitterUsernames];
                
                for (NSString *obj in [[Cache sharedCache]invalidUsers]) {
                    if ([addedUsers containsObject:obj]) {
                        [addedUsers removeObject:obj];
                    }
                    
                    if ([selectedUsers containsObject:obj]) {
                        [selectedUsers removeObject:obj];
                    }
                }
                
                [[[Cache sharedCache]invalidUsers]removeAllObjects];

                [[NSUserDefaults standardUserDefaults]setObject:addedUsers forKey:kAddedUsernamesListKey];
                [[NSUserDefaults standardUserDefaults]setObject:selectedUsers forKey:kSelectedUsernamesListKey];
            }
        } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Remove", nil];
        [av show];
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
    
    NSString *string = [NSString stringWithFormat:@"https://graph.facebook.com/?batch=%@&access_token=%@",reqString.fhs_URLEncode,ad.facebook.accessToken];
    
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

            NSLog(@"%@",status);
            
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

- (void)reloadTableView {
    [_theTableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    if ([[Cache sharedCache]timeline].count == 0) {
        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)showVersion {
    AboutViewController *vc = [[AboutViewController alloc]init];
    [self presentModalViewController:vc animated:YES];
}

- (void)showPrefs {
    PrefsViewController *p = [[PrefsViewController alloc]init];
    [self presentModalViewController:p animated:YES];
}

- (void)showCompose {
    UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:@"Compose" completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex]isEqualToString:@"Tweet"]) {
            ReplyViewController *composer = [[ReplyViewController alloc]initWithTweet:nil];
            [self presentModalViewController:composer animated:YES];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex]isEqualToString:@"Status"]) {
            ReplyViewController *composer = [[ReplyViewController alloc]initWithToID:nil];
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
        as.title = @"Please log in.";
        [as addButtonWithTitle:@"OK"];
    } else {
        [as addButtonWithTitle:@"Cancel"];
    }
    as.cancelButtonIndex = as.numberOfButtons-1;
    
    [as showInView:ad.window];
}

- (void)sortedTimeline {
    [[[Cache sharedCache]timeline]sortUsingComparator:^NSComparisonResult(id one, id two) {
        float oneTime = [[one createdAt]timeIntervalSince1970];
        float twoTime = [[two createdAt]timeIntervalSince1970];
        
        if (oneTime < twoTime) {
            return (NSComparisonResult)NSOrderedDescending;
        } else if (oneTime > twoTime) {
            return (NSComparisonResult)NSOrderedAscending;
        } else {
            return (NSComparisonResult)NSOrderedSame;
        }
    }];
}

// 
// Tweet Fetching Methods
//

- (void)getTweetsForUsernames:(NSArray *)usernames {
    
    finishedLoadingTwitter = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            
            NSMutableArray *tweets = [NSMutableArray array];
            
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
                                for (Tweet *fromcache in nonTimelineTweets) {
                                    if ([tweet.inReplyToTweetIdentifier isEqualToString:fromcache.inReplyToTweetIdentifier]) {
                                        retrievedTweet = fromcache;
                                        break;
                                    }
                                }
                            }
                            
                            if (retrievedTweet == nil) {
                                retrievedTweet = [[FHSTwitterEngine sharedEngine]getDetailsForTweet:tweet.inReplyToTweetIdentifier];
                            }
                            
                            if ([retrievedTweet isKindOfClass:[NSDictionary class]]) {
                                Tweet *irt = [Tweet tweetWithDictionary:retrievedTweet];
                                [[[Cache sharedCache]nonTimelineTweets]addObject:irt];
                                [tweets addObject:irt];
                                NSLog(@"TWITTER: Fetched Contextual Tweet: %@",irt.inReplyToTweetIdentifier);
                            } else if ([retrievedTweet isKindOfClass:[Tweet class]]) {
                                [tweets addObject:retrievedTweet];
                                NSLog(@"TWITTER: Loaded Contextual Tweet: %@",((Tweet *)retrievedTweet).inReplyToTweetIdentifier);
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
            
            int duplicateCount = (tweets.count-[tweets arrayByRemovingDuplicates].count);
            
            if (duplicateCount > 0) {
                NSLog(@"TWITTER: Deleted %d duplicate tweets",duplicateCount);
                [tweets removeDuplicates];
            }

            [[[Cache sharedCache]timeline]addObjectsFromArray:tweets];

            finishedLoadingTwitter = YES;
            
            dispatch_sync(dispatch_get_main_queue(), ^{
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

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
 
    cell.textLabel.highlightedTextColor = [UIColor blackColor];  
    cell.detailTextLabel.highlightedTextColor = [UIColor blackColor];
    
    cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.detailTextLabel.numberOfLines = 0;
    
    NSMutableArray *timeline = [[Cache sharedCache]timeline];
    
    if (oneIsCorrect(_refreshControl.isRefreshing, timeline.count == 0)) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
     //   cell.additionalLabel.text = nil;
        
        AppDelegate *ad = [Settings appDelegate];
        
        if (![[FHSTwitterEngine sharedEngine]isAuthorized]) {
            [[FHSTwitterEngine sharedEngine]loadAccessToken];
        }
            
        if (![ad.facebook isSessionValid]) {
            [ad tryLoginFromSavedCreds];
        }
        
        if (![[FHSTwitterEngine sharedEngine]isAuthorized] && ![ad.facebook isSessionValid]) {
            cell.textLabel.text = @"Not Logged in.";
            cell.detailTextLabel.text = @"You need to login in Prefs.";
        } else {
            if (oneIsCorrect([[[Settings selectedFacebookFriends]allKeys]count] > 0, [[Settings selectedTwitterUsernames]count] > 0)) {
                if (!_refreshControl.isRefreshing) {
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
            NSString *text = status.message;
            
            if (text.length > 140) {
                text = [[text substringToIndex:140]stringByAppendingString:@"..."];
            } else if (text.length == 0) {
                text = [status.type stringByCapitalizingFirstLetter];
            }
            
            cell.detailTextLabel.text = text;

            cell.textLabel.text = status.from.name;
            
        } else if ([tweetOrStatus isKindOfClass:[Tweet class]]) {
            Tweet *tweet = (Tweet *)tweetOrStatus;
       //     cell.additionalLabel.text = @"Twitter    ";
       //     cell.additionalLabel.textColor = [UIColor colorWithRed:64.0/255.0 green:153.0/255.0 blue:1 alpha:1.0];
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
