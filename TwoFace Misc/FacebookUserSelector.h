//
//  FacebookUserSelector.h
//  TwoFace
//
//  Created by Nathaniel Symer on 7/12/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FacebookUserSelector : UIViewController <FBRequestDelegate, UITableViewDelegate, UITableViewDataSource, PullToRefreshViewDelegate> {
    IBOutlet UITableView *theTableView;
    IBOutlet UILabel *counter;
    IBOutlet UIBarButtonItem *back;
    IBOutlet UIBarButtonItem *reset;
    PullToRefreshView *pull;
}

@property (strong, nonatomic) IBOutlet UITableView *theTableView;
@property (strong, nonatomic) IBOutlet UILabel *counter;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *back;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *reset;

@property (strong, nonatomic) NSMutableArray *orderedFriendsArray;
@property (strong, nonatomic) NSMutableDictionary *savedFriendsDict;

- (void)getFriends;
- (void)clearFriends;

- (void)cacheFriendsOrderedArray;
- (void)loadCachedFriendsOrderedArray;

@end
