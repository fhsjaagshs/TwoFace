//
//  UserSelectorViewController.h
//  TwoFace
//
//  Created by Nathaniel Symer on 1/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserSelectorViewController : UIViewController

@property (nonatomic, assign) BOOL isFacebook;
@property (nonatomic, assign) BOOL isImmediateSelection;

- (id)initWithIsFacebook:(BOOL)isfacebook;
- (id)initWithIsFacebook:(BOOL)isfacebook isImmediateSelection:(BOOL)isimdtselection;

@end
