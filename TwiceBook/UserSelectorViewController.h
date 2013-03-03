//
//  UserSelectorViewController.h
//  TwoFace
//
//  Created by Nathaniel Symer on 1/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserSelectorViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, PullToRefreshViewDelegate>

// UI
@property (nonatomic, strong) PullToRefreshView *pull;
@property (nonatomic, strong) UITableView *theTableView;
@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) UILabel *counter;

// Twitter
@property (strong, nonatomic) NSMutableArray *savedSelectedArrayTwitter;
- (void)manuallyAddUsername:(NSString *)username;

// Facebook
@property (strong, nonatomic) NSMutableArray *orderedFriendsArray;
@property (strong, nonatomic) NSMutableDictionary *savedFriendsDict;

@property (nonatomic, assign) BOOL isFacebook;
@property (nonatomic, assign) BOOL isImmediateSelection;

- (id)initWithIsFacebook:(BOOL)isfacebook;
- (id)initWithIsFacebook:(BOOL)isfacebook isImmediateSelection:(BOOL)isimdtselection;

@end
