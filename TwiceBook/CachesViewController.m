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
    UITableView *theTableView = [[UITableView alloc]initWithFrame:UIScreen.mainScreen.bounds style:UITableViewStyleGrouped];
    theTableView.delegate = self;
    theTableView.dataSource = self;
    [self.view addSubview:theTableView];
    
    self.navigationItem.title = @"Caches";
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

    if (indexPath.section == 0) {
        [Cache clearImageCache];
    } else if (indexPath.section == 1) {
        [[[Cache shared]nonTimelineTweets]removeAllObjects];
        [[[Cache shared]twitterFriends]removeAllObjects];
    } else if (indexPath.section == 2) {
        [Cache.shared cacheFacebookDicts:nil];
    } else if (indexPath.section == 3) {
        [[[Cache shared]timeline]removeAllObjects];
    }
}

@end
