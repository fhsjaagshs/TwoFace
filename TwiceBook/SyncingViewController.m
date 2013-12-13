//
//  iCloudSyncingViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 9/14/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "SyncingViewController.h"

@implementation SyncingViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    self.view = [[UIView alloc]initWithFrame:screenBounds];

    self.theTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height) style:UITableViewStyleGrouped];
    _theTableView.delegate = self;
    _theTableView.dataSource = self;
    _theTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _theTableView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    [self.view addSubview:_theTableView];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Sync"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setLastSyncedDate) name:@"lastSynced" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setLoggedInAccount:) name:@"dropboxLoggedInUser" object:nil];
    
    self.loggedInUsername = [[NSUserDefaults standardUserDefaults]objectForKey:@"loggedInDropboxUser"];
}

- (void)setLastSyncedDate {
    [_theTableView reloadData];
}

- (void)setLoggedInAccount:(NSNotification *)notif {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.loggedInUsername = notif.object;
    [[NSUserDefaults standardUserDefaults]setObject:_loggedInUsername forKey:@"loggedInDropboxUser"];
    [_theTableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 1)?2:1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if ([[DBSession sharedSession]isLinked]) {
            return (_loggedInUsername.length == 0)?@"Loading username...":[NSString stringWithFormat:@"Logged in as %@",_loggedInUsername];
        }
        return @"Not logged in";
    } else if (section == 1) {
        if (![[DBSession sharedSession]isLinked]) {
            return nil;
        }
        
        NSDate *date = [[NSUserDefaults standardUserDefaults]objectForKey:@"lastSyncedDateKey"];

        if (date) {
            NSString *dateS = [date stringDaysAgo];
            
            if ([dateS isEqualToString:@"Today"]) {
                dateS = [NSDate stringForDisplayFromDate:date prefixed:YES];
            }
            
            return [NSString stringWithFormat:@"Last synced %@",dateS];
        }
        return @"Never Synced";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell_syncing";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.section == 0) {
        cell.textLabel.text = [[DBSession sharedSession]isLinked]?@"Log out of Dropbox":@"Log into Dropbox";
    } else if (indexPath.section == 1) {
        cell.textLabel.text = (indexPath.row == 0)?@"Sync":@"Reset Sync";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (![[DBSession sharedSession]isLinked]) {
            [[DBSession sharedSession]linkFromController:self];
        } else {
            [[DBSession sharedSession]unlinkAll];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"loggedInDropboxUser"];
            self.loggedInUsername = nil;
            [_theTableView reloadData];
        }
    } else if (indexPath.section == 1) {
        if (![FHSTwitterEngine isConnectedToInternet]) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            qAlert(@"Connection Offline", @"Your Internet connection appears to be offline. Please verify that your connection is valid.");
            return;
        }
        
        if (indexPath.row == 0) {
            [DBSyncClient dropboxSync];
        } else if (indexPath.row == 1) {
            UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Are You Sure?" message:@"Resetting your Dropbox sync cannot be undone." completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
                if (buttonIndex == 1) {
                    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"lastSyncedDateKey"];
                    [_theTableView reloadData];
                    [DBSyncClient resetDropboxSync];
                }
            } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reset",nil];
            [av show];
        }
    }
    [_theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"lastSynced" object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"dropboxLoggedInUser" object:nil];
}

@end
