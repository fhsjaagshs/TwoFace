//
//  IntermediateUserSelectorViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/17/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "IntermediateUserSelectorViewController.h"

@implementation IntermediateUserSelectorViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    [self.view setBackgroundColor:[UIColor underPageBackgroundColor]];
    _theTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-44) style:UITableViewStyleGrouped];
    _theTableView.delegate = self;
    _theTableView.dataSource = self;
    _theTableView.backgroundColor = [UIColor clearColor];
    UIView *bgView = [[UIView alloc]initWithFrame:self.theTableView.frame];
    bgView.backgroundColor = [UIColor clearColor];
    [_theTableView setBackgroundView:bgView];
    [self.view addSubview:_theTableView];
    [self.view bringSubviewToFront:_theTableView];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Select Social Network"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [bar pushNavigationItem:topItem animated:NO];
    
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ImdtCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Twitter";
        BOOL authorized = [[FHSTwitterEngine sharedEngine]isAuthorized];
        cell.detailTextLabel.text = authorized?[NSString stringWithFormat:@"%d/5",usernamesListArray.count]:@"Login Required";
        
        if (!authorized) {
            cell.detailTextLabel.textColor = [UIColor redColor];
        } 
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"Facebook";
        BOOL authorized = [[kAppDelegate facebook]isSessionValid];
        cell.detailTextLabel.text = authorized?[NSString stringWithFormat:@"%d/5",kSelectedFriendsDictionary.allKeys.count]:@"Login Required";
        
        if (!authorized) {
            cell.detailTextLabel.textColor = [UIColor redColor];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        if ([[FHSTwitterEngine sharedEngine]isAuthorized]) {
            UserSelectorViewController *userSelector = [[UserSelectorViewController alloc]initWithIsFacebook:NO];
            [self presentModalViewController:userSelector animated:YES];
        }
    } else if (indexPath.row == 1) {
        if ([[kAppDelegate facebook]isSessionValid]) {
            UserSelectorViewController *userSelector = [[UserSelectorViewController alloc]initWithIsFacebook:YES];
            [self presentModalViewController:userSelector animated:YES];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.theTableView reloadData];
}

@end
