//
//  SyncingViewControllerViewController.h
//  TwoFace
//
//  Created by Nate Symer on 7/23/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SyncingViewControllerViewController : UIViewController {
    IBOutlet UIBarButtonItem *loginButton;
    IBOutlet UIButton *syncButton;
    IBOutlet UIBarButtonItem *resetSyncButton;
    IBOutlet UILabel *lastSyncedLabel;
}

@property (strong, nonatomic) IBOutlet UIBarButtonItem *loginButton;

@property (strong, nonatomic) IBOutlet UIButton *syncButton;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *resetSyncButton;

@property (strong, nonatomic) IBOutlet UILabel *lastSyncedLabel;

@end
