//
//  iCloudSyncingViewController.h
//  TwoFace
//
//  Created by Nathaniel Symer on 9/14/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SyncingViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSString *loggedInUsername;
@property (strong, nonatomic) UITableView *theTableView;

@end