//
//  TwitterUserSelector.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/17/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TwitterUserSelector : UIViewController <UITableViewDataSource, UITableViewDelegate, NSURLConnectionDelegate, UIAlertViewDelegate, PullToRefreshViewDelegate> {
    PullToRefreshView *pull;
}

@property (nonatomic, strong) IBOutlet UITableView *theTableView;
@property (nonatomic, strong) IBOutlet UILabel *counter;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *back;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *reset;

@property (strong, nonatomic) NSMutableArray *savedSelectedArray;

- (void)manuallyAddUsername:(NSString *)username;

@end
