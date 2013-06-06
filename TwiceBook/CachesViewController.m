//
//  CachesViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/7/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "CachesViewController.h"

@implementation CachesViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view.backgroundColor = [UIColor underPageBackgroundColor];
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
    if (section < 4) {
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
        return @"Twitter Cache";
    } else if (section == 2) {
        return @"Facebook Cache";
    } else if (section == 3) {
        return @"Timeline";
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"Images from Facebook and Twitter";
    } else if (section == 1) {
        return @"Tweets and Twitter Users";
    } else if (section == 2) {
        return @"Statuses and Facebook Users";
    } else {
        return @"The timeline";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"CellCaches";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    int section = indexPath.section;

    if (section == 0) {
        cell.textLabel.text = @"Clear Image Cache";
    } else if (section == 1) {
        cell.textLabel.text = @"Clear Twitter Cache";
    } else if (section == 2) {
        cell.textLabel.text = @"Clear Facebook Cache";
    } else if (section == 3) {
        cell.textLabel.text = @"Clear Timeline";
    }
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int section = indexPath.section;
    
    if (section == 0) {
        [Cache clearImageCache];
    } else if (section == 1) {
        [[[Cache sharedCache]nonTimelineTweets]removeAllObjects];
        [[[Cache sharedCache]twitterIdToUsername]removeAllObjects];
        [[[Cache sharedCache]invalidUsers]removeAllObjects];
        [[[Cache sharedCache]twitterFriends]removeAllObjects];
    } else if (section == 2) {
        [[[Cache sharedCache]facebookFriends]removeAllObjects];
    } else if (section == 3) {
        [[[Cache sharedCache]timeline]removeAllObjects];
    }
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

@end
