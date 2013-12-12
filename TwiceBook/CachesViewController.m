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
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    UITableView *theTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height) style:UITableViewStyleGrouped];
    theTableView.delegate = self;
    theTableView.dataSource = self;
    theTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    theTableView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    [self.view addSubview:theTableView];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Caches"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [bar pushNavigationItem:topItem animated:NO];
    
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Caches Menu";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"You can clear these caches to free some disk space.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellCaches";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Clear Image Cache";
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"Clear Twitter Cache";
    } else if (indexPath.row == 2) {
        cell.textLabel.text = @"Clear Facebook Cache";
    } else if (indexPath.row == 3) {
        cell.textLabel.text = @"Clear Timeline Cache";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int section = indexPath.section;
    
    if (section == 0) {
        [Cache clearImageCache];
    } else if (section == 1) {
        [[[Cache shared]nonTimelineTweets]removeAllObjects];
        [[[Cache shared]twitterFriends]removeAllObjects];
    } else if (section == 2) {
        [[[Cache shared]facebookFriends]removeAllObjects];
    } else if (section == 3) {
        [[[Cache shared]timeline]removeAllObjects];
    }
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

@end
