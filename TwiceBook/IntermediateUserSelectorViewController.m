//
//  IntermediateUserSelectorViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/17/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "IntermediateUserSelectorViewController.h"

@interface IntermediateUserSelectorViewController () <UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate>

@property (strong, nonatomic) UITableView *theTableView;

@end

@implementation IntermediateUserSelectorViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    _theTableView = [[UITableView alloc]initWithFrame:UIScreen.mainScreen.bounds style:UITableViewStyleGrouped];
    _theTableView.delegate = self;
    _theTableView.dataSource = self;
    [self.view addSubview:_theTableView];
    
    self.navigationItem.title = @"Social Networks";
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
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    if (indexPath.row == 0) {
        cell.textLabel.text = @"Twitter";
        BOOL authorized = [[FHSTwitterEngine sharedEngine]isAuthorized];
        
        if (!authorized) {
            cell.detailTextLabel.text = @"Login Required";
            cell.detailTextLabel.textColor = [UIColor redColor];
        } else cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu/5",(unsigned long)[[Settings selectedTwitterUsernames]count]];
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"Facebook";
        BOOL authorized = FHSFacebook.shared.isSessionValid;
        cell.detailTextLabel.text = authorized?[NSString stringWithFormat:@"%lu/5",(unsigned long)[[Settings selectedFacebookFriends]count]]:@"Login Required";
        
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
            [self.navigationController pushViewController:userSelector animated:YES];
        }
    } else if (indexPath.row == 1) {
        if (FHSFacebook.shared.isSessionValid) {
            UserSelectorViewController *userSelector = [[UserSelectorViewController alloc]initWithIsFacebook:YES];
            [self.navigationController pushViewController:userSelector animated:YES];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_theTableView reloadData];
}

@end
