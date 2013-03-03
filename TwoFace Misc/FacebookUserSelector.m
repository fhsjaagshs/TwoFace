//
//  FacebookUserSelector.m
//  TwoFace
//
//  Created by Nathaniel Symer on 7/12/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "FacebookUserSelector.h"

#define fqlFriendsOrdered @"SELECT name,uid,last_name FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me()) order by last_name"

@implementation FacebookUserSelector

@synthesize theTableView, counter, back, reset, savedFriendsDict;

- (void)loadCachedFriendsOrderedArray {
    NSString *loadPath = [kCachesDirectory stringByAppendingPathComponent:@"orderedFacebookFriends.plist"];
    self.orderedFriendsArray = [[NSMutableArray alloc]initWithContentsOfFile:loadPath];
}

- (void)cacheFriendsOrderedArray {
    NSString *loadPath = [kCachesDirectory stringByAppendingPathComponent:@"orderedFacebookFriends.plist"];
    [self.orderedFriendsArray writeToFile:loadPath atomically:YES];
}

//
// PTR methods
//

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    back.enabled = NO;
    reset.enabled = NO;
    [self getFriends];
}

- (void)pullToRefreshViewWasShown:(PullToRefreshView *)view {
    [pull setSubtitleText:@"Facebook Friends"];
}

//
// friends counter methods
//

- (void)updateCounter {
    NSArray *array = [kSelectedFriendsDictionary allKeys];
    int count = array.count;
    counter.text = [NSString stringWithFormat:@"%d/5",count];
}

- (void)getFriends {
    AppDelegate *ad = kAppDelegate;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
    [params setObject:fqlFriendsOrdered forKey:@"q"];
    [ad.facebook requestWithGraphPath:@"me/fql" andParams:params andHttpMethod:@"GET" andDelegate:self];
}

- (void)clearFriends {
    AppDelegate *ad = kAppDelegate;
    [ad.facebookFriendsDict removeAllObjects];
    [ad cacheFetchedFacebookFriends];
    [ad removeFacebookFromTimeline];
}

- (void)request:(FBRequest *)request didLoad:(id)result {
    
    AppDelegate *ad = kAppDelegate;
    
    [ad hideHUD];

    BOOL isCorrectRequest = [request.params.allValues containsObject:fqlFriendsOrdered];
    
    if (self.orderedFriendsArray.count == 0) {
        self.orderedFriendsArray = [[NSMutableArray alloc]init];
    }
    
    if (ad.facebookFriendsDict.allKeys.count == 0) {
        ad.facebookFriendsDict = [[NSMutableDictionary alloc]init];
    }
    
    if (isCorrectRequest) {
        [self clearFriends];
        NSDictionary *resultDictionary = (NSDictionary *)result;
        
        NSArray *data = [resultDictionary objectForKey:@"data"];

        for (int i = 0; i < data.count; i++) {
            NSString *username = [NSString stringWithString:[[data objectAtIndex:i]objectForKey:@"name"]];

            if ([ad.facebookFriendsDict.allValues containsObject:username]) {
                username = [username stringByAppendingString:@" "];
            }

            NSString *identifier = [NSString stringWithFormat:@"%@",[[data objectAtIndex:i]objectForKey:@"uid"]];
            [ad.facebookFriendsDict setValue:username forKey:identifier];

            [self.orderedFriendsArray addObject:username];
        }

        [theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        
        [self cacheFriendsOrderedArray];
        [ad cacheFetchedFacebookFriends];
    }
    
    if (pull.state != kPullToRefreshViewStateNormal) {
        [pull finishedLoading];
    }
    
    back.enabled = YES;
    reset.enabled = YES;
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    back.enabled = YES;
    reset.enabled = YES;
    [kAppDelegate hideHUD];
    if (pull.state != kPullToRefreshViewStateNormal) {
        [pull finishedLoading];
    }
    NSString *FBerr = [error localizedDescription];
    NSString *message = (FBerr.length == 0 || !FBerr)?@"Confirm that you are logged in correctly and try again.":FBerr;
    qAlert(@"Error", message);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    AppDelegate *ad = kAppDelegate;
    return ad.facebookFriendsDict.allKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    AppDelegate *ad = kAppDelegate;

    NSDictionary *selectedDictionary = kSelectedFriendsDictionary;
    
    BOOL orderedArrayIsNil = (self.orderedFriendsArray.count == 0);
    BOOL fbFriendsDictIsNil = (ad.facebookFriendsDict.allValues.count == 0);
    
    if (orderedArrayIsNil) {
        self.orderedFriendsArray = [[NSMutableArray alloc]init];
        if (fbFriendsDictIsNil) {
            ad.facebookFriendsDict = [[NSMutableDictionary alloc]init];
        }
        cell.textLabel.text = @"Something went wrong";
        return cell;
    }
    
    if (fbFriendsDictIsNil) {
        if (orderedArrayIsNil) {
            self.orderedFriendsArray = [[NSMutableArray alloc]init];
        }
        ad.facebookFriendsDict = [[NSMutableDictionary alloc]init];
        cell.textLabel.text = @"Something went wrong";
        return cell;
    }
    
    NSString *theValue = [self.orderedFriendsArray objectAtIndex:indexPath.row];
    int indexOfKey = [ad.facebookFriendsDict.allValues indexOfObject:theValue];
    
    NSString *secondValue = nil;
    
    if (indexOfKey < INT_MAX) {
        secondValue = [ad.facebookFriendsDict.allKeys objectAtIndex:indexOfKey];
    }

    BOOL isSelected = [selectedDictionary.allKeys containsObject:secondValue];
    
    if (isSelected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.textLabel.text = theValue;
 
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [theTableView cellForRowAtIndexPath:indexPath];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self updateCounter];
    
    AppDelegate *ad = kAppDelegate;

    NSMutableDictionary *selectedDictionary = kSelectedFriendsDictionary;
    
    NSMutableDictionary *deletedDictionary = kDBSyncDeletedFBDict;
    
    NSString *selectedObject = [self.orderedFriendsArray objectAtIndex:indexPath.row];
    int correctedRow = [ad.facebookFriendsDict.allValues indexOfObject:selectedObject];
    
    NSString *identifier = [ad.facebookFriendsDict.allKeys objectAtIndex:correctedRow];
    NSString *name = [ad.facebookFriendsDict.allValues objectAtIndex:correctedRow];
    
    if (![selectedDictionary.allKeys containsObject:identifier]) {
        if (selectedDictionary.allKeys.count < 5) {
            [selectedDictionary setValue:name forKey:identifier];
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            if ([deletedDictionary objectForKey:identifier]) {
                [deletedDictionary removeObjectForKey:identifier];
            }
        } else {
            [self flashLabel];
        }
    } else {
        
        if ([savedFriendsDict.allKeys containsObject:identifier]) {
            [deletedDictionary setObject:[selectedDictionary objectForKey:identifier] forKey:identifier];
        }
        
        if ([selectedDictionary objectForKey:identifier]) {
            [selectedDictionary removeObjectForKey:identifier];
        }
        
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    [[NSUserDefaults standardUserDefaults]setObject:deletedDictionary forKey:kDBSyncDeletedFBDictKey];
    [[NSUserDefaults standardUserDefaults]setObject:selectedDictionary forKey:kSelectedFriendsDictionaryKey];
    
    [self updateCounter];
}

- (IBAction)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)resetSelectedFriends {
    NSMutableDictionary *selectedDictionary = kSelectedFriendsDictionary;
    
    NSMutableDictionary *deletedDictionary = kDBSyncDeletedFBDict;
    [deletedDictionary addEntriesFromDictionary:selectedDictionary];
    [[NSUserDefaults standardUserDefaults]setObject:deletedDictionary forKey:kDBSyncDeletedFBDictKey];
    
    [selectedDictionary removeAllObjects];
    [[NSUserDefaults standardUserDefaults]setObject:selectedDictionary forKey:kSelectedFriendsDictionaryKey];
    [self updateCounter];
    [theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)flashLabel {
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:0.0];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor whiteColor] afterDelay:0.1];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:0.2];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor whiteColor] afterDelay:0.3];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor redColor] afterDelay:0.4];
    [counter performSelector:@selector(setTextColor:) withObject:[UIColor whiteColor] afterDelay:0.5];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    pull = [[PullToRefreshView alloc]initWithScrollView:theTableView];
    [pull setDelegate:self];
    [theTableView addSubview:pull];
    
    AppDelegate *ad = kAppDelegate;
    
    self.savedFriendsDict = kSelectedFriendsDictionary;
    
    [self loadCachedFriendsOrderedArray];
    
    if (!self.orderedFriendsArray) {
        self.orderedFriendsArray = [[NSMutableArray alloc]init];
        [ad.facebookFriendsDict removeAllObjects];
    }

    if (ad.facebookFriendsDict.allKeys.count == 0) {
        [kAppDelegate showHUDWithTitle:@"Loading..."];
        [self getFriends];
    }
    
    [self updateCounter];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
