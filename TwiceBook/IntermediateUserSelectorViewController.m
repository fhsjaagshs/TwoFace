//
//  IntermediateUserSelectorViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/17/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "IntermediateUserSelectorViewController.h"

@implementation IntermediateUserSelectorViewController

@synthesize theTableView;

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    [self.view setBackgroundColor:[UIColor underPageBackgroundColor]];
    self.theTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-44) style:UITableViewStyleGrouped];
    self.theTableView.delegate = self;
    self.theTableView.dataSource = self;
    self.theTableView.backgroundColor = [UIColor clearColor];
    UIView *bgView = [[UIView alloc]initWithFrame:self.theTableView.frame];
    bgView.backgroundColor = [UIColor clearColor];
    [self.theTableView setBackgroundView:bgView];
    [self.view addSubview:self.theTableView];
    [self.view bringSubviewToFront:self.theTableView];
    
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
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d/5",usernamesListArray.count];
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"Facebook";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d/5",kSelectedFriendsDictionary.allKeys.count];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        if (![[kAppDelegate engine]isAuthorized]) {
            qAlert(@"Login Required", @"You must be logged in order to obtain a list of your friends on Twitter.");
        } else {
            UserSelectorViewController *userSelector = [[UserSelectorViewController alloc]initWithIsFacebook:NO];
            [self presentModalViewController:userSelector animated:YES];
        }
    } else if (indexPath.row == 1) {
        if (![[kAppDelegate facebook]isSessionValid]) {
            qAlert(@"Login Required", @"You must be logged in order to obtain a list of your friends on Facebook.");
        } else {
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
