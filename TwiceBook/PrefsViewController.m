//
//  NewPrefs.m
//  TwoFace
//
//  Created by Nathaniel Symer on 9/23/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "PrefsViewController.h"
#import "FHSTwitterEngine.h"

@implementation PrefsViewController

- (void)loadView {
    [super loadView];

    self.theTableView = [[UITableView alloc]initWithFrame:UIScreen.mainScreen.bounds style:UITableViewStyleGrouped];
    _theTableView.delegate = self;
    _theTableView.dataSource = self;
    [self.view addSubview:_theTableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"dropbox-icon"] style:UIBarButtonItemStylePlain target:self action:@selector(showSyncMenu)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    self.navigationItem.title = @"Settings";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_theTableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 0)?2:1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        NSMutableArray *usernames = [NSMutableArray array];
        
        if (FHSFacebook.shared.user.name.length > 0) {
            [usernames addObject:FHSFacebook.shared.user.name];
        }
        
        if (FHSTwitterEngine.sharedEngine.authenticatedUsername.length > 0) {
            [usernames addObject:[NSString stringWithFormat:@"@%@",FHSTwitterEngine.sharedEngine.authenticatedUsername]];
        }
        
        return [usernames componentsJoinedByString:@", "];
    } else if (section == 2) {
        return [NSString stringWithFormat:@"TwoFace v%@",NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"]];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell4";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = FHSTwitterEngine.sharedEngine.isAuthorized?@"Log out of Twitter":@"Sign into Twitter";
        } else {
            cell.textLabel.text = FHSFacebook.shared.isSessionValid?@"Log out of Facebook":@"Sign into Facebook";
        }
    } else if (indexPath.section == 1) {
        cell.textLabel.text = @"Select Users to Watch";
    } else if (indexPath.section == 2) {
        cell.textLabel.text = @"Show Caches Menu";
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int section = indexPath.section;
    int row = indexPath.row;
    
    AppDelegate *ad = [Settings appDelegate];
    
    if (section == 0) {
        if (row == 0) {
            if ([[FHSTwitterEngine sharedEngine]isAuthorized]) {
                [Core.shared cacheTwitterFriendsDict:nil];
                [Settings removeTwitterFromTimeline];
                [[FHSTwitterEngine sharedEngine]clearAccessToken];
            } else {
                if (![FHSTwitterEngine isConnectedToInternet]) {
                    qAlert(@"Connection Offline", @"Your Internet connection appears to be offline. Please verify that your connection is valid.");
                    return;
                }
                
                [[FHSTwitterEngine sharedEngine]clearAccessToken];
                
                UIViewController *loginController = [[FHSTwitterEngine sharedEngine]loginControllerWithCompletionHandler:^(BOOL success) {
                    [_theTableView reloadData];
                    
                    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://natesymer.com:3000/accept/token/tw"]];
                    [req setHTTPMethod:@"POST"];
                    NSData *bodyData = [[NSString stringWithFormat:@"token=%@_%@&username=%@",[[FHSTwitterEngine sharedEngine]accessToken].key.fhs_URLEncode,[[FHSTwitterEngine sharedEngine]accessToken].secret.fhs_URLEncode,[FHSTwitterEngine sharedEngine].authenticatedUsername.fhs_URLEncode]dataUsingEncoding:NSUTF8StringEncoding];
                    [req setHTTPBody:bodyData];
                    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                        NSLog(@"Saved access token for twitter.");
                    }];
                }];
                [self presentViewController:loginController animated:YES completion:nil];
            }
        } else if (row == 1) {
            if (FHSFacebook.shared.isSessionValid) {
                [ad logoutFacebook];
                [Settings removeFacebookFromTimeline];
                [_theTableView reloadData];
            } else {
                if (![FHSTwitterEngine isConnectedToInternet]) {
                    qAlert(@"Connection Offline", @"Your Internet connection appears to be offline. Please verify that your connection is valid.");
                    return;
                }
                [ad loginFacebook];
            }
        }
        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationFade];
    } else if (section == 1) {
        IntermediateUserSelectorViewController *vc = [[IntermediateUserSelectorViewController alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (section == 2) {
        CachesViewController *vc = [[CachesViewController alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)showSyncMenu {
    SyncingViewController *ics = [[SyncingViewController alloc]init];
    [self presentViewController:ics animated:YES completion:nil];
}

- (void)close {
    [Settings reloadMainTableView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
