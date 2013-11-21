//
//  NewPrefs.h
//  TwoFace
//
//  Created by Nathaniel Symer on 9/23/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PrefsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *theTableView;

@end
