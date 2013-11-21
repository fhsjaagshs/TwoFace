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
    [self.view setBackgroundColor:[UIColor underPageBackgroundColor]];
    self.theTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height) style:UITableViewStyleGrouped];
    _theTableView.delegate = self;
    _theTableView.dataSource = self;
    _theTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _theTableView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    [self.view addSubview:_theTableView];
    [self.view bringSubviewToFront:_theTableView];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Sync"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [bar pushNavigationItem:topItem animated:NO];
    
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
}

- (void)setLastSyncedDate {
    [self.theTableView reloadData];
}

- (void)setLoggedInAccount:(NSNotification *)notif {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.loggedInUsername = [notif object];
    [[NSUserDefaults standardUserDefaults]setObject:self.loggedInUsername forKey:@"loggedInDropboxUser"];
    [self.theTableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setLastSyncedDate) name:@"lastSynced" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setLoggedInAccount:) name:@"dropboxLoggedInUser" object:nil];
    NSString *savedUsername = [[NSUserDefaults standardUserDefaults]objectForKey:@"loggedInDropboxUser"];
    if (savedUsername.length > 0) {
        self.loggedInUsername = savedUsername;
    } else {
        if ([[DBSession sharedSession]isLinked]) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            [[[Settings appDelegate]restClient]loadAccountInfo];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 1) {
        return 2;
    } else {
        return 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {

    if (section == 0) {
        if (![[DBSession sharedSession]isLinked]) {
            return @"Not logged in";
        } else {
            
            if (self.loggedInUsername == nil || self.loggedInUsername.length == 0) {
                return @"Loading username...";
            }
            return [NSString stringWithFormat:@"Logged in as %@",self.loggedInUsername];
        }
    }
    
    if (section == 1) {
        
        if (![[DBSession sharedSession]isLinked]) {
            return nil;
        }
        
        NSDate *date = [[NSUserDefaults standardUserDefaults]objectForKey:@"lastSyncedDateKey"];

        NSString *displayString = nil;
        if (!date) {
            displayString = @"Never Synced";
        } else {
            
            NSString *dateS = [date stringDaysAgo];
            
            if ([dateS isEqualToString:@"Today"]) {
                dateS = [NSDate stringForDisplayFromDate:date prefixed:YES];
            }
            
            displayString = [NSString stringWithFormat:@"Last synced %@",dateS];
        }
        return displayString;
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
    
    int section = indexPath.section;
    int row = indexPath.row;
    
    if (section == 0) {
        cell.textLabel.text = [[DBSession sharedSession]isLinked]?@"Log out of Dropbox":@"Log into Dropbox";
    } else if (section == 1) {
        cell.textLabel.text = (row == 0)?@"Sync":@"Reset Sync";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int section = indexPath.section;
    int row = indexPath.row;
    
    if (section == 0) {
        if (![[DBSession sharedSession]isLinked]) {
            [[DBSession sharedSession]linkFromController:self];
        } else {
            [[DBSession sharedSession]unlinkAll];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"loggedInDropboxUser"];
            self.loggedInUsername = nil;
            [self.theTableView reloadData];
        }
    } else if (section == 1) {
        
        if (![FHSTwitterEngine isConnectedToInternet]) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            qAlert(@"Connection Offline", @"Your Internet connection appears to be offline. Please verify that your connection is valid.");
            return;
        }
        
        if (row == 0) {
            [[Settings appDelegate]dropboxSync];
        } else if (row == 1) {
            UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Are You Sure?" message:@"Resetting your Dropbox sync cannot be undone." completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
                
                if (buttonIndex == 1) {
                    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"lastSyncedDateKey"];
                    [self.theTableView reloadData];
                    [[Settings appDelegate]resetDropboxSync];
                }
                
            } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reset",nil];
            [av show];
        }
    }
}

- (void)close {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"lastSynced" object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"dropboxLoggedInUser" object:nil];
    [self dismissModalViewControllerAnimated:YES];
}

@end
