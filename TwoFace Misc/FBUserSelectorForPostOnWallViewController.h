//
//  FBUserSelectorForPostOnWallViewController.h
//  TwoFace
//
//  Created by Nathaniel Symer on 10/22/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FBUserSelectorForPostOnWallViewController : UIViewController <FBRequestDelegate, UITableViewDelegate, UITableViewDataSource, PullToRefreshViewDelegate> {
    IBOutlet UITableView *theTableView;
    IBOutlet UIBarButtonItem *back;
    PullToRefreshView *pull;
}

@property (strong, nonatomic) IBOutlet UITableView *theTableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *back;

@property (strong, nonatomic) NSMutableArray *orderedFriendsArray;
@property (strong, nonatomic) NSMutableDictionary *savedFriendsDict;

@end
