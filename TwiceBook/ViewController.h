//
//  ViewController.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/3/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, PullToRefreshViewDelegate> {
    BOOL errorEncounteredWhileLoading;
    BOOL finishedLoadingTwitter;
    BOOL facebookDone;
}

@property (strong, nonatomic) UITableView *theTableView;

- (void)getTweetsForUsernames:(NSArray *)usernames;
- (BOOL)isLoadingPosts;

@end
