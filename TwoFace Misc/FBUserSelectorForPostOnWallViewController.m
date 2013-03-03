//
//  FBUserSelectorForPostOnWallViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/22/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "FBUserSelectorForPostOnWallViewController.h"

#define fqlFriendsOrdered @"SELECT name,uid,last_name FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me()) order by last_name"

@implementation FBUserSelectorForPostOnWallViewController

@synthesize back, theTableView;

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
    [self getFriends];
}

- (void)pullToRefreshViewWasShown:(PullToRefreshView *)view {
    [pull setSubtitleText:@"Facebook Friends"];
}

//
// friends counter methods
//

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
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    back.enabled = YES;
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
    
    cell.textLabel.text = theValue;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    AppDelegate *ad = kAppDelegate;
    
    if ([[theTableView cellForRowAtIndexPath:indexPath].textLabel.text isEqualToString:@"Something went wrong"]) {
        return;
    }
    
    NSString *selectedObject = [self.orderedFriendsArray objectAtIndex:indexPath.row];
    int correctedRow = [ad.facebookFriendsDict.allValues indexOfObject:selectedObject];
    
    NSString *identifier = [ad.facebookFriendsDict.allKeys objectAtIndex:correctedRow];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"passFriendID" object:identifier];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)close {
    [self dismissModalViewControllerAnimated:YES];
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
}

@end
