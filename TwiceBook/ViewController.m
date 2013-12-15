//
//  ViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/3/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ViewController.h"
#import "FHSTwitterEngine.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UITableView *theTableView;

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
    
    self.refreshControl = [[UIRefreshControl alloc]init];
    [_refreshControl addTarget:self action:@selector(refreshTimeline) forControlEvents:UIControlEventValueChanged];
    [_theTableView addSubview:_refreshControl];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"TwoFace"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(showCompose)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"\u2699" style:UIBarButtonItemStyleBordered target:self action:@selector(showPrefs)];
    [topItem.rightBarButtonItem setTitlePositionAdjustment:UIOffsetMake(0, 15.0f) forBarMetrics:UIBarMetricsDefault];
    [topItem.rightBarButtonItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:24.0f] } forState:UIControlStateNormal];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];
    
    [[NSNotificationCenter defaultCenter]addObserver:_theTableView selector:@selector(reloadData) name:@"reloadTableView" object:nil];
}

- (void)refreshTimeline {
    if (![FHSTwitterEngine isConnectedToInternet]) {
        [_refreshControl endRefreshing];
        return;
    }
    
    if (![[FHSTwitterEngine sharedEngine]isAuthorized]) {
        [[FHSTwitterEngine sharedEngine]loadAccessToken];
    }
    
    if (![[FHSTwitterEngine sharedEngine]isAuthorized] && !FHSFacebook.shared.isSessionValid) {
        [_refreshControl endRefreshing];
        return;
    }
    
    NSMutableArray *usernameArrayTwitter = [Settings selectedTwitterUsernames];
    NSArray *usernameArrayFacebook = [[Settings selectedFacebookFriends]allKeys];
    
    if (usernameArrayTwitter.count == 0 && usernameArrayFacebook.count == 0) {
        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [_refreshControl endRefreshing];
    } else {
        [[[Cache shared]timeline]removeAllObjects];
        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                [self clearImageCachesIfNecessary];
                
                BOOL returnValue = YES;
                
                if ([[FHSTwitterEngine sharedEngine]isAuthorized]) {
                    returnValue = [PostsClient loadTweetsForUsernames:usernameArrayTwitter];
                }
                
                if (FHSFacebook.shared.isSessionValid) {
                    BOOL retValFB = [PostsClient loadPostsForIDs:usernameArrayFacebook];
                    if (returnValue) {
                        returnValue = retValFB;
                    }
                }

                [[Cache shared]sortTimeline];
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        [_refreshControl endRefreshing];
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];

                        if (!returnValue) {
                            qAlert(@"Errors Encountered", @"There were some errors while fetching some tweets and statuses.");
                        }
                    }
                });
            }
        });
    }
}

- (void)clearImageCachesIfNecessary {
    double time = [[NSDate date]timeIntervalSince1970];
    double previousTime = [[NSUserDefaults standardUserDefaults]doubleForKey:@"previousClearTime"];
    if (time-previousTime > 172800) { // 2 days (172800 seconds)
        [[NSUserDefaults standardUserDefaults]setDouble:time forKey:@"previousClearTime"];
        [Cache clearImageCache];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *timeline = [[Cache shared]timeline];
    
    if (timeline.count > 0) {
        
        id item = timeline[indexPath.row];
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
        
        NSAttributedString *attributedText = [[NSAttributedString alloc]initWithString:cellText attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:17] }];
        CGSize labelSize = [attributedText boundingRectWithSize:(CGSize){280, 1000} options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
     //   CGSize labelSize = [cellText sizeWithFont:[UIFont systemFontOfSize:17] constrainedToSize:CGSizeMake(280, 1000) lineBreakMode:UILineBreakModeWordWrap];
        return labelSize.height+35;
    }
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int count = Cache.shared.timeline.count;
    return (count == 0)?1:count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * const CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.highlightedTextColor = [UIColor blackColor];
        cell.detailTextLabel.highlightedTextColor = [UIColor blackColor];
        
        cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
        cell.detailTextLabel.numberOfLines = 0;
    }
 
    NSMutableArray *timeline = [[Cache shared]timeline];
    
    if (any(_refreshControl.isRefreshing, timeline.count == 0)) {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        if (![[FHSTwitterEngine sharedEngine]isAuthorized]) {
            [[FHSTwitterEngine sharedEngine]loadAccessToken];
        }

        if (!FHSTwitterEngine.sharedEngine.isAuthorized && !FHSFacebook.shared.isSessionValid) {
            cell.textLabel.text = @"Not Logged in.";
            cell.detailTextLabel.text = @"You need to login in Prefs.";
        } else {
            if (any(Settings.selectedFacebookFriends.count > 0, Settings.selectedTwitterUsernames.count > 0)) {
                if (!_refreshControl.isRefreshing) {
                    cell.textLabel.text = @"No Data";
                    cell.detailTextLabel.text = @"Please pull down to refresh.";
                } else {
                    cell.textLabel.text = @"Loading...";
                }
            } else {
                cell.textLabel.text = @"No Users Selected";
                cell.detailTextLabel.text = @"Select users to watch in Prefs.";
            }
        }
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        id tweetOrStatus = timeline[indexPath.row];

        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if ([tweetOrStatus isKindOfClass:[Status class]]) {
            Status *status = (Status *)tweetOrStatus;
            NSString *text = status.message;
            
            if (text.length > 140) {
                text = [[text substringToIndex:140]stringByAppendingString:@"..."];
            } else if (text.length == 0) {
                text = [status.type stringByCapitalizingFirstLetter];
            }
            
            cell.textLabel.textColor = [UIColor colorWithRed:59.0f/255.0f green:89.0f/255.0f blue:152.0f/255.0f alpha:1.0f];
            cell.detailTextLabel.text = text;
            cell.textLabel.text = status.from.name;
        } else if ([tweetOrStatus isKindOfClass:[Tweet class]]) {
            Tweet *tweet = (Tweet *)tweetOrStatus;
            cell.textLabel.textColor = [UIColor colorWithRed:64.0/255.0 green:153.0/255.0 blue:1 alpha:1.0];
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
    NSMutableArray *timeline = [[Cache shared]timeline];
    
    if (timeline.count == 0) {
        return;
    }

    NSString *labelText = [_theTableView cellForRowAtIndexPath:indexPath].textLabel.text;
    
    if (([labelText isEqualToString:@"Not Logged in."] || [labelText isEqualToString:@"Loading..."] || [labelText isEqualToString:@"No Users Selected"])) {
        return;
    }
    
    id tappedItem = timeline[indexPath.row];
    
    if ([tappedItem isKindOfClass:[Status class]]) {
        PostDetailViewController *p = [[PostDetailViewController alloc]initWithPost:tappedItem];
        [self presentViewController:p animated:YES completion:nil];
    } else if ([tappedItem isKindOfClass:[Tweet class]]) {
        TweetDetailViewController *d = [[TweetDetailViewController alloc]initWithTweet:tappedItem];
        [self presentViewController:d animated:YES completion:nil];
    }
    
    [_theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    if (Cache.shared.timeline.count == 0) {
        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)showPrefs {
    PrefsViewController *p = [[PrefsViewController alloc]init];
    [self presentViewController:p animated:YES completion:nil];
}

- (void)showCompose {
    UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:@"Compose" completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex]isEqualToString:@"Tweet"]) {
            ReplyViewController *composer = [[ReplyViewController alloc]initWithTweet:nil];
            [self presentViewController:composer animated:YES completion:nil];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex]isEqualToString:@"Status"]) {
            ReplyViewController *composer = [[ReplyViewController alloc]initWithToID:nil];
            [self presentViewController:composer animated:YES completion:nil];
        }
    } cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    BOOL twitter = FHSTwitterEngine.sharedEngine.isAuthorized;
    BOOL facebook = FHSFacebook.shared.isSessionValid;
    
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
    
    [as showInView:Settings.appDelegate.window];
}

@end
