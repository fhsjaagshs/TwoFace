//
//  CachesViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/7/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "CachesViewController.h"

#define invalidUsersCachePath [kCachesDirectory stringByAppendingPathComponent:@"cached_invalid_users.plist"]
#define contextualTweetCachePath [kCachesDirectory stringByAppendingPathComponent:@"cached_replied_to_tweets.plist"]
#define noncontextualTweetCachePath [kCachesDirectory stringByAppendingPathComponent:@"timeline_tweet_cache.plist"]
#define usernamesListCachePath [kCachesDirectory stringByAppendingPathComponent:@"twitter_username_lookup_dict.plist"]

@implementation CachesViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    [self.view setBackgroundColor:[UIColor underPageBackgroundColor]];
    UITableView *theTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-44) style:UITableViewStyleGrouped];
    theTableView.delegate = self;
    theTableView.dataSource = self;
    theTableView.backgroundColor = [UIColor clearColor];
    UIView *bgView = [[UIView alloc]initWithFrame:theTableView.frame];
    bgView.backgroundColor = [UIColor clearColor];
    [theTableView setBackgroundView:bgView];
    [self.view addSubview:theTableView];
    [self.view bringSubviewToFront:theTableView];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Caches"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [bar pushNavigationItem:topItem animated:NO];
    
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 2;
    } else if (section == 2) {
        return 1;
    } else if (section == 3) {
        return 1;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Image Cache";
    } else if (section == 1) {
        return @"Tweet Caches";
    } else if (section == 2) {
        return @"Invalid Users Cache";
    } else if (section == 3) {
        return @"Twitter Friends Cache";
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        // return @"I cache images to cut loading time. Clear the cache if you experience problems.";
        return @"Images are cached to cut loading times.";
    } else if (section == 1) {
        // return @"I cache tweets to cut refreshing times. Clear the cache if you experience problems.";
        return @"Tweets are cached to speed up refreshing times.";
    } else if (section == 2) {
        // return @"I cache a list of invalid users to cut loading times. Clear the cache if you experience problems";
        return @"Invalid users are cached to speed up error checking.";
    } else if (section == 3) {
        return @"Cached Twitter Friends speed up the loading of Twitter friends.";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell4";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    int section = indexPath.section;
    int row = indexPath.row;
    
    if (section == 0) {
        
        if (row == 0) {
            cell.textLabel.text = @"Clear Image Cache";
        }
        
    } else if (section == 1) {
        
        if (row == 0) {
            cell.textLabel.text = @"Clear Contexual Tweet Cache";
        } else if (row == 1) {
            cell.textLabel.text = @"Clear General Tweet Cache";
        }
    } else if (section == 2) {
        if (row == 0) {
            cell.textLabel.text = @"Clear Invalid User Cache";
        }
    } else if (section == 3) {
        if (row == 0) {
            cell.textLabel.text = @"Clear Twitter Friends Cache";
        }
    }
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int section = indexPath.section;
    int row = indexPath.row;
    
    if (section == 0) {
        if (row == 0) {
            [kAppDelegate clearImageCache];
        }
    } else if (section == 1) {
        
        if (row == 0) {
            [[NSFileManager defaultManager]removeItemAtPath:contextualTweetCachePath error:nil];
        } else if (row == 1) {
            [[NSFileManager defaultManager]removeItemAtPath:noncontextualTweetCachePath error:nil];
        }
    } else if (section == 2) {
        if (row == 0) {
            [[NSFileManager defaultManager]removeItemAtPath:invalidUsersCachePath error:nil];
        }
    } else if (section == 3) {
        if (row == 0) {
            [[NSFileManager defaultManager]removeItemAtPath:usernamesListCachePath error:nil];
        }
    }
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

@end
