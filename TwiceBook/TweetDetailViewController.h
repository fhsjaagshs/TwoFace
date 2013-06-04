//
//  TweetDetailViewController.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/6/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TweetDetailViewController : UIViewController

@property (strong, nonatomic) UITextView *tv;
@property (strong, nonatomic) UILabel *displayName;
@property (strong, nonatomic) UILabel *username;
@property (strong, nonatomic) UIImageView *theImageView;
@property (strong, nonatomic) UINavigationBar *navBar;
@property (strong, nonatomic) Tweet *tweet;

- (id)initWithTweet:(Tweet *)aTweet;
- (void)getProfileImage;

@end
