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
                        [self.timeline addObjectsFromArray:savedTimeline];
                        
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

                        [self.pull finishedLoading];
                        
                    }
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                }
            });
        }
    });
}

//
// UIViewController Methods
//

- (void)reloadTableView {
    [self.theTableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadTimelineViewDidLoadThreaded];

    self.protectedUsers = [NSMutableArray array];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadTableView) name:@"reloadTableView" object:nil];
    
    self.pull = [[PullToRefreshView alloc]initWithScrollView:self.theTableView];
    [self.pull setDelegate:self];
    [self.theTableView addSubview:self.pull];
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.timeline.count == 0) {
        [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
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
    
    NSMutableArray *array = [self.timeline mutableCopy];
    NSMutableDictionary *the = [NSMutableDictionary dictionary];
    
    for (NSDictionary *dict in array) {
        NSString *numberInArray = [NSString stringWithFormat:@"%d",(int)[array indexOfObject:dict]];
        
        BOOL isFacebook = [(NSString *)[dict objectForKey:@"social_network_name"] isEqualToString:@"facebook"];
        
        NSDate *date = nil;
        
        if (isFacebook) {
            date = [dict objectForKey:@"poster_created_time"];
        } else {
            date = twitterDateFromString([dict objectForKey:@"created_at"]);
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
        int index = [string intValue];
        [final addObject:[array objectAtIndex:index]]; // array obj.. was timeline obj...
    }
    
    [self.timeline removeAllObjects];
    [self.timeline addObjectsFromArray:final];
}

// 
// Tweet Fetching Methods
//

- (NSMutableArray *)loadTimelineTweetCacheWithCount:(int)count forUsername:(NSString *)username {
    
    if (count < 1) {
        return nil;
    }
    
    NSString *cacheLocation = [kCachesDirectory stringByAppendingPathComponent:@"timeline_tweet_cache.plist"];
    NSMutableArray *cache = [[NSMutableArray alloc]initWithContentsOfFile:cacheLocation];
    
    if (cache.count == 0 || cache == nil) {
        return nil;
    }
    
    NSMutableArray *userSpecificTweets = [[NSMutableArray alloc]init];
    
    for (NSDictionary *tweet in cache) {
        NSString *tweetUsername = [[tweet objectForKey:@"user"]objectForKey:@"screen_name"];
        if ([[tweetUsername lowercaseString] isEqualToString:[username lowercaseString]]) {
            [userSpecificTweets addObject:tweet];
        }
    }
    
    if (userSpecificTweets.count == 0) {
        return nil;
    }
    
    NSMutableArray *array = [userSpecificTweets mutableCopy];
    NSMutableDictionary *the = [NSMutableDictionary dictionary];
    
    for (NSDictionary *dict in array) {
        NSString *numberInArray = [NSString stringWithFormat:@"%d",(int)[array indexOfObject:dict]];
        NSString *time = [NSString stringWithFormat:@"%f",[twitterDateFromString([dict objectForKey:@"created_at"]) timeIntervalSince1970]];
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
        int index = [string intValue];
        [final addObject:[array objectAtIndex:index]]; // array obj.. was timeline obj...
    }
    
    [userSpecificTweets removeAllObjects];
    [userSpecificTweets addObjectsFromArray:final];
    
    if (userSpecificTweets.count == 0) {
        return nil;
    }
    
    NSMutableArray *tweetsToReturn = [[NSMutableArray alloc]init];
    
    
    for (int i = 0; i < count; i++) {
        if (userSpecificTweets.count > i) {
            [tweetsToReturn addObject:[userSpecificTweets objectAtIndex:i]];
        }
    }
    
    if (tweetsToReturn.count == 0) {
        return nil;
    }
    
    for (id obj in userSpecificTweets) {
        if (![tweetsToReturn containsObject:obj]) {
            [cache removeObject:obj];
        }
    }
    
    return tweetsToReturn;
}

- (NSString *)getLatestTweetIDInTimelineCacheForUsername:(NSString *)username {
    NSString *cacheLocation = [kCachesDirectory stringByAppendingPathComponent:@"timeline_tweet_cache.plist"];
    NSMutableArray *cache = [[NSMutableArray alloc]initWithContentsOfFile:cacheLocation];
    
    if (cache.count == 0) {
        return nil;
    }
    
    NSMutableArray *userSpecificTweets = [NSMutableArray array];
    
    for (NSDictionary *tweet in cache) {
        NSString *tweetUsername = [[tweet objectForKey:@"user"]objectForKey:@"screen_name"];
        if ([[tweetUsername lowercaseString] isEqualToString:[username lowercaseString]]) {
            [userSpecificTweets addObject:tweet];
        }
    }
    
    if (userSpecificTweets.count == 0) {
        return nil;
    }
    
    NSMutableArray *array = [userSpecificTweets mutableCopy];
    NSMutableDictionary *the = [NSMutableDictionary dictionary];
    
    for (NSDictionary *dict in array) {
        NSString *numberInArray = [NSString stringWithFormat:@"%d",(int)[array indexOfObject:dict]];
        NSString *time = [NSString stringWithFormat:@"%f",[twitterDateFromString([dict objectForKey:@"created_at"]) timeIntervalSince1970]];
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
        int index = [string intValue];
        [final addObject:[array objectAtIndex:index]]; // array obj.. was timeline obj...
    }
    
    [userSpecificTweets removeAllObjects];
    [userSpecificTweets addObjectsFromArray:final];
    
    if (userSpecificTweets.count == 0) {
        return nil;
    }
    
    NSDictionary *latestTweet = [userSpecificTweets firstObjectA];
    NSString *finalID = [latestTweet objectForKey:@"id_str"];
    
    if (finalID == nil || finalID.length == 0) {
        finalID = [NSString stringWithFormat:@"%@",[latestTweet objectForKey:@"id"]];
    }
    
    return finalID;
}

- (void)addTweetsToTimelineTweetCache:(NSArray *)tweetsToAdd {
    
    if (tweetsToAdd.count == 0 || tweetsToAdd == nil) {
        return;
    }
    
    NSString *cacheLocation = [kCachesDirectory stringByAppendingPathComponent:@"timeline_tweet_cache.plist"];
    NSMutableArray *cache = [[NSMutableArray alloc]initWithContentsOfFile:cacheLocation];
    
    if (cache == nil) {
        cache = [NSMutableArray array];
    }
    
    for (id tweet in tweetsToAdd) {
        if (![cache containsObject:tweet]) {
            [cache addObject:tweet];
        }
    }
    
    if (cache.count == 0) {
        return;
    }
    
    NSMutableArray *array = [cache mutableCopy];
    NSMutableDictionary *the = [NSMutableDictionary dictionary];
    
    for (NSDictionary *dict in array) {
        NSString *numberInArray = [NSString stringWithFormat:@"%d",(int)[array indexOfObject:dict]];
        NSString *time = [NSString stringWithFormat:@"%f",[twitterDateFromString([dict objectForKey:@"created_at"]) timeIntervalSince1970]];
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
        int index = [string intValue];
        [final addObject:[array objectAtIndex:index]]; // array obj.. was timeline obj...
    }
    
    [cache removeAllObjects];
    [cache addObjectsFromArray:final];
    
    [cache writeToFile:cacheLocation atomically:YES];
}

- (void)getTweetsForUsernames:(NSArray *)usernames {
    
    AppDelegate *ad = kAppDelegate;
    
    finishedLoadingTwitter = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            
            NSMutableArray *tweets = [NSMutableArray array];
            NSMutableArray *mentions = [NSMutableArray array];
            
            for (NSString *username in usernames) {
                NSString *identifier = [self getLatestTweetIDInTimelineCacheForUsername:username];
                
                NSLog(@"TWITTER: latest tweet identifier: %@",identifier);
                
                id fetched = [ad.engine getTimelineForUser:username isID:NO count:3 sinceID:identifier maxID:nil];
                
                if ([fetched isKindOfClass:[NSError class]]) {
                    if ([(NSError *)fetched code] == 404) {
                        [self.protectedUsers addObject:username];
                    }
                }
                
                if ([fetched isKindOfClass:[NSArray class]]) {
                    int numberOfTweetsToLoad = 3-[(NSArray *)fetched count];
                    
                    NSMutableArray *loadedFromCacheTweets = [self loadTimelineTweetCacheWithCount:numberOfTweetsToLoad forUsername:username];
                    
                    NSLog(@"TWITTER: fetched: %u loaded: %d",[(NSArray *)fetched count],loadedFromCacheTweets.count);
                    
                    id mentions = [ad.engine getMentionsTimelineWithCount:4];
                    
                    
                    
                    [tweets addObjectsFromArray:loadedFromCacheTweets];
                    [tweets addObjectsFromArray:fetched];
                    
                    [self addTweetsToTimelineTweetCache:fetched];
                }
            }
            

            NSMutableArray *statuses = [[NSMutableArray alloc]init];
            
            NSMutableDictionary *cachedInvalidUsers = [[NSMutableDictionary alloc]initWithContentsOfFile:[kCachesDirectory stringByAppendingPathComponent:@"cached_invalid_users.plist"]];
            
            if (cachedInvalidUsers == nil) {
                cachedInvalidUsers = [NSMutableDictionary dictionary];
            }
            
            NSString *cachedPath = [kCachesDirectory stringByAppendingPathComponent:@"cached_replied_to_tweets.plist"];
            NSMutableArray *cachedRepliedToTweets = [[NSMutableArray alloc]initWithContentsOfFile:cachedPath];
            
            if (cachedRepliedToTweets == nil) {
                cachedRepliedToTweets = [NSMutableArray array];
            }
            
            NSMutableArray *potentialBadUsers = [NSMutableArray array];
            
            for (NSString *username in usernames) {
                NSLog(@"%@",username);
                
                if (username.length > 0) {
                    id badUsername = [cachedInvalidUsers objectForKey:username];
                    
                    if (badUsername) {
                        if ([(NSString *)[badUsername objectForKey:@"invalid"]isEqualToString:@"yes"] || ([(NSString *)[badUsername objectForKey:@"protected"]isEqualToString:@"yes"] && ![ad.theFetchedUsernames containsObject:username])) {
                            [self.protectedUsers addObject:username];
                        }
                        continue;
                    }
                }
                
                NSString *identifier = [self getLatestTweetIDInTimelineCacheForUsername:username];
                
                NSLog(@"identifier: %@",identifier);
                
                id fetched = [ad.engine getTimelineForUser:username isID:NO count:3 sinceID:identifier maxID:nil];
                
                if ([fetched isKindOfClass:[NSError class]]) {
                    if ([(NSError *)fetched code] == 404) {
                        [self.protectedUsers addObject:username];
                        [cachedInvalidUsers setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"no", @"protected", @"yes", @"invalid", nil] forKey:username];
                        [cachedInvalidUsers writeToFile:[kCachesDirectory stringByAppendingPathComponent:@"cached_invalid_users.plist"] atomically:YES];
                    } else {
                        if (![self.protectedUsers containsObject:username]) {
                            [potentialBadUsers addObject:username];
                        }
                    }
                }
                
                if ([fetched isKindOfClass:[NSArray class]]) {
                    int numberOfTweetsToLoad = 3-[(NSArray *)fetched count];

                    NSMutableArray *loadedFromCacheTweets = [self loadTimelineTweetCacheWithCount:numberOfTweetsToLoad forUsername:username];
                    
                    NSLog(@"TWITTER: fetched: %u loaded: %d",[(NSArray *)fetched count],loadedFromCacheTweets.count);
                    
                    [statuses addObjectsFromArray:loadedFromCacheTweets];
                    [statuses addObjectsFromArray:fetched];
                    [self addTweetsToTimelineTweetCache:fetched];
                }
                NSLog(@" ");
            }
            
            //
            // Bad User checking
            //
            
            id lookup = [ad.engine lookupUsers:potentialBadUsers areIDs:YES];
            
            if ([lookup isKindOfClass:[NSArray class]]) {
                for (NSDictionary *entry in lookup) {
                    NSString *username = [entry objectForKey:@"screen_name"];
                    if ([entry objectForKey:@"protected"] && ![usernamesListArray containsObject:username]) {
                        [self.protectedUsers addObject:username];
                        [cachedInvalidUsers setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"yes", @"protected", @"no", @"invalid", nil] forKey:username];
                        [cachedInvalidUsers writeToFile:[kCachesDirectory stringByAppendingPathComponent:@"cached_invalid_users.plist"] atomically:YES];
                    }
                }
                
            } else if ([lookup isKindOfClass:[NSError class]]) {
                NSLog(@"TWITTER: Lookup error: %@",lookup);
                errorEncounteredWhileLoading = YES;
            }
            
            
            //
            // Replied to tweet fetching
            //
            
            NSMutableArray *unusedStatusesFromCache = [statuses mutableCopy];
            
            for (NSMutableDictionary *dict in [statuses mutableCopy]) {
                
                NSString *inReplyToID = [dict objectForKey:@"in_reply_to_status_id_str"];
                if (!(inReplyToID == nil || inReplyToID.length == 0)) {

                    id retrievedTweet = nil;
                    
                    if (cachedRepliedToTweets.count > 0) {
                        for (NSDictionary *dict_cached in cachedRepliedToTweets) {
                            if ([[dict_cached objectForKey:@"in_reply_to_status_id_str"]isEqualToString:inReplyToID]) {
                                retrievedTweet = [dict_cached mutableCopy];
                            }
                        }
                    }
                    
                    if (retrievedTweet == nil) {
                        retrievedTweet = [ad.engine getDetailsForTweet:inReplyToID];
                    }
                    
                    if ([retrievedTweet isKindOfClass:[NSDictionary class]]) {
                        if (![retrievedTweet objectForKey:@"error"]) {
                            [cachedRepliedToTweets addObject:retrievedTweet];
                            [statuses addObject:retrievedTweet];
                            [unusedStatusesFromCache removeObject:retrievedTweet];
                            NSLog(@"Fetched Contextual Tweet: %@",inReplyToID);
                        } else {
                            errorEncounteredWhileLoading = YES;
                        }
                    }
                }
            }

            NSLog(@" ");
            NSLog(@"-----------------------");
            NSLog(@" ");
            
            [cachedRepliedToTweets removeObjectsInArray:unusedStatusesFromCache];
            [cachedRepliedToTweets writeToFile:cachedPath atomically:YES];
            
            for (NSMutableDictionary *dict in [statuses mutableCopy]) {
                [dict setValue:@"twitter" forKey:@"social_network_name"];
                
                NSString *text = [dict objectForKey:@"text"];
                
                NSString *retweetedUsername = [[[dict objectForKey:@"retweeted_status"]objectForKey:@"user"]objectForKey:@"screen_name"];
                NSString *retweetedText = [[dict objectForKey:@"retweeted_status"]objectForKey:@"text"];
                
                if ([[text substringToIndex:2]isEqualToString:@"RT"]) {
                    if (oneIsCorrect(retweetedUsername.length > 0, retweetedText.length > 0)) {
                        NSArray *newEntities = [[dict objectForKey:@"retweeted_status"]objectForKey:@"entities"];
                        if (newEntities != nil) {
                            text = [NSString stringWithFormat:@"RT @%@: %@",retweetedUsername,retweetedText];
                            [dict setObject:newEntities forKey:@"entities"];
                        } 
                    }
                }
                
                text = [[text stringByRemovingHTMLEntities]stringByTrimmingWhitespace];
                [dict removeObjectForKey:@"geo"];
                [dict removeObjectForKey:@"retweeted_status"];
                [dict removeObjectForKey:@"source"];
                
                for (NSMutableDictionary *mediadict in [[dict objectForKey:@"entities"]objectForKey:@"media"]) {
                    
                    NSString *picTwitterComLink = [mediadict objectForKey:@"display_url"];
                    NSString *picTwitterURLtoReplace = [mediadict objectForKey:@"url"];
                    NSString *picTwitterComImageLink = [mediadict objectForKey:@"media_url"];
                    
                    BOOL hasTwitPicLink = !((picTwitterComLink.length == 0) && (picTwitterComLink == nil) && (picTwitterURLtoReplace.length == 0) && (picTwitterURLtoReplace == nil) && (picTwitterComImageLink.length == 0) && (picTwitterComImageLink == nil));
                    
                    if (hasTwitPicLink) {
                        picTwitterComLink = [picTwitterComLink stringByReplacingOccurrencesOfString:@"http://" withString:@""];
                        text = [text stringByReplacingOccurrencesOfString:picTwitterURLtoReplace withString:picTwitterComLink];
                        [ad setImageURL:picTwitterComImageLink forLinkURL:picTwitterComLink];
                    }
                }
                
                NSArray *urlEntities = [[dict objectForKey:@"entities"]objectForKey:@"urls"];
                
                if (urlEntities.count > 0) {
                    for (NSDictionary *entity in urlEntities) {
                        NSString *shortenedURL = [entity objectForKey:@"url"];
                        NSString *fullURL = [entity objectForKey:@"expanded_url"];
                        
                        NSString *dotWhatever = [[[[[fullURL stringByReplacingOccurrencesOfString:@"://" withString:@""] componentsSeparatedByString:@"/"]firstObjectA]componentsSeparatedByString:@"."]lastObject];

                        BOOL shouldRemoveHttp = ([dotWhatever isEqualToString:@"com"] || [dotWhatever isEqualToString:@"net"] || [dotWhatever isEqualToString:@"gov"] || [dotWhatever isEqualToString:@"us"] || [dotWhatever isEqualToString:@"me"] || [dotWhatever isEqualToString:@"org"] || [dotWhatever isEqualToString:@"edu"] || [dotWhatever isEqualToString:@"er"]);
                        
                        if (shouldRemoveHttp) {
                            fullURL = [fullURL stringByReplacingOccurrencesOfString:@"http://" withString:@""];
                        }
                        
                        text = [text stringByReplacingOccurrencesOfString:shortenedURL withString:fullURL];
                    }
                }

                [dict setValue:text forKey:@"text"];
                
                NSMutableDictionary *user = [dict objectForKey:@"user"];
                [user removeObjectsForKeys:[NSArray arrayWithObjects:@"entities", @"geo_enabled", @"utc_offset", nil]];
                [dict setObject:user forKey:@"user"];
                [dict removeObjectForKey:@"place"];
            }
            
            int duplicateTweetCount = statuses.count-[[statuses mutableCopy]arrayByRemovingDuplicates].count;
            
            NSLog(@"TWITTER: Duplicate tweets: %d",duplicateTweetCount);
            
            [self.timeline addObjectsFromArray:statuses];

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
        
        NSDictionary *item = [[_timeline objectAtIndex:indexPath.row]mutableCopy];
        NSString *cellText = nil;
        
        if ([(NSString *)[item objectForKey:@"social_network_name"]isEqualToString:@"facebook"]) {
            cellText = [item objectForKey:@"message"];
            
            if (cellText.length == 0) {
                cellText = [item objectForKey:@"type"];
            }
        } else {
            cellText = [item objectForKey:@"text"];
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
    
    if (count == 0) {
        return 1;
    }
    return count;
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
        NSMutableDictionary *tweetOrStatus = [[self.timeline objectAtIndex:indexPath.row]mutableCopy];

        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if ([(NSString *)[tweetOrStatus objectForKey:@"social_network_name"]isEqualToString:@"facebook"]) {
            cell.additionalLabel.text = @"Facebook    ";
            cell.additionalLabel.textColor = [UIColor colorWithRed:59.0/255.0 green:89.0/255.0 blue:152.0/255.0 alpha:1.0];
            cell.textLabel.text = [tweetOrStatus objectForKey:@"poster_name"];
            cell.detailTextLabel.text = [tweetOrStatus objectForKey:@"message"];
            
            if (cell.detailTextLabel.text.length == 0) {
                cell.detailTextLabel.text = [[tweetOrStatus objectForKey:@"type"]stringByCapitalizingFirstLetter];
            }
            
        } else {
            cell.additionalLabel.text = @"Twitter    ";
            cell.additionalLabel.textColor = [UIColor colorWithRed:64.0/255.0 green:153.0/255.0 blue:1 alpha:1.0];
            cell.textLabel.text = [[tweetOrStatus objectForKey:@"user"]objectForKey:@"name"];
            cell.detailTextLabel.text = [[tweetOrStatus objectForKey:@"text"]stringByRemovingHTMLEntities];
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

    NSString *labelText = [self.theTableView cellForRowAtIndexPath:indexPath].textLabel.text;
    
    if (([labelText isEqualToString:@"Not Logged in."] || [labelText isEqualToString:@"Loading..."] || [labelText isEqualToString:@"No Users Selected"])) {
        return;
    }
    
    NSMutableDictionary *tappedItem = [[_timeline objectAtIndex:indexPath.row]mutableCopy];
    
    if ([(NSString *)[tappedItem objectForKey:@"social_network_name"]isEqualToString:@"facebook"]) {
        PostDetailViewController *p = [[PostDetailViewController alloc]initWithPost:tappedItem];
        [self presentModalViewController:p animated:YES];
    } else {
        TweetDetailViewController *d = [[TweetDetailViewController alloc]initWithTweet:tappedItem];
        [self presentModalViewController:d animated:YES];
    }
}

@end
