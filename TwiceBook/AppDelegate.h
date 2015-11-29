//
//  AppDelegate.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/3/12.
//  Copyright (c) 2012 Nawthaniel Symer. All rights reserved.
//

// Potential New name: PrimaFacie

#import <UIKit/UIKit.h>

static NSString *kDropboxSecret = @"";
static NSString *kDropboxKey = @"";
static NSString *kFacebookAppID = @"";

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ViewController *viewController;

- (void)loginFacebook;
- (void)logoutFacebook;

@end
