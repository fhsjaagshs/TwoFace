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
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Settings"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Sync" style:UIBarButtonItemStyleBordered target:self action:@selector(showSyncMenu)];
    [bar pushNavigationItem:topItem animated:NO];
    
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refreshFacebookButton) name:@"FBButtonNotif" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.theTableView reloadData];
}

- (void)refreshFacebookButton {
    [self.theTableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return 20;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {

    AppDelegate *ad = [Settings appDelegate];
    
    if (section == 0) {
        
        NSString *twitterUsername = [[FHSTwitterEngine sharedEngine]authenticatedUsername];
        NSString *fbUsername = [[NSUserDefaults standardUserDefaults]objectForKey:@"fbName"];
        
        if (fbUsername.length == 0 && [ad.facebook isSessionValid]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool {
                    NSString *theName = [ad getFacebookUsernameSync];
                    [[NSUserDefaults standardUserDefaults]setObject:theName forKey:@"fbName"];
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationFade];
                        }
                    });
                }
            });
        }
        
        BOOL fbUsernameIsThere = fbUsername.length > 0;
        BOOL twitterUsernameIsThere = twitterUsername.length > 0;

        if (fbUsernameIsThere && twitterUsernameIsThere) {
            return [NSString stringWithFormat:@"@%@, %@",twitterUsername, fbUsername];
        }
        
        if (fbUsernameIsThere && !twitterUsernameIsThere) {
            return fbUsername;
        }
        
        if (!fbUsernameIsThere && twitterUsernameIsThere) {
            return [@"@" stringByAppendingString:twitterUsername];
        }
        
        if (!fbUsernameIsThere && !twitterUsernameIsThere) {
            return nil;
        }
    }
    
    if (section == 2) {
        return @"Opens a menu with a list of caches that you can clear if you encounter problems.";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell4";

    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    int section = indexPath.section;
    int row = indexPath.row;
    
    AppDelegate *ad = [Settings appDelegate];
    
    if (section == 0) {
        if (row == 0) {
            if ([[FHSTwitterEngine sharedEngine]isAuthorized]) {
                cell.textLabel.text = @"Log out of Twitter";
            } else {
                cell.textLabel.text = @"Sign into Twitter" ;
            }
        } else {
            if ([ad.facebook isSessionValid]) {
                cell.textLabel.text = @"Log out of Facebook";
            } else {
                cell.textLabel.text = @"Sign into Facebook";
            }
        }
    }
    
    if (section == 1) {
        cell.textLabel.text = @"Select Users to Watch";
    }
    
    if (section == 2) {
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
                [[[Cache sharedCache]twitterFriends]removeAllObjects];
                [[FHSTwitterEngine sharedEngine]clearAccessToken];
            } else {
                if (![FHSTwitterEngine isConnectedToInternet]) {
                    qAlert(@"Connection Offline", @"Your Internet connection appears to be offline. Please verify that your connection is valid.");
                    return;
                }
                [[FHSTwitterEngine sharedEngine]clearAccessToken];
                
                UIViewController *loginController = [[FHSTwitterEngine sharedEngine]loginControllerWithCompletionHandler:^(BOOL success) {
                    NSLog(success?@"L0L success":@"O noes!!! Loggen faylur!!!");
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
            if ([ad.facebook isSessionValid]) {
                [ad logoutFacebook];
                [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"fbName"];
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
        IntermediateUserSelectorViewController *iusvc = [[IntermediateUserSelectorViewController alloc]init];
        [self presentModalViewController:iusvc animated:YES];
    } else if (section == 2) {
        CachesViewController *vc = [[CachesViewController alloc]init];
        [self presentModalViewController:vc animated:YES];
    }
}

- (void)showSyncMenu {
    SyncingViewController *ics = [[SyncingViewController alloc]init];
    [self presentModalViewController:ics animated:YES];
}

- (void)close {
    AppDelegate *ad = [Settings appDelegate];
    
    BOOL shouldReload = NO;
    
    if (![ad.facebook isSessionValid]) {
        [ad removeFacebookFromTimeline];
        shouldReload = YES;
    }
    
    if (![[FHSTwitterEngine sharedEngine]isAuthorized]) {
        [ad removeTwitterFromTimeline];
        shouldReload = YES;
    }
    
    if (shouldReload) {
        [ad reloadMainTableView];
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"FBButtonNotif" object:nil];
}

@end
