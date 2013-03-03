//
//  PostDetailViewController.h
//  TwoFace
//
//  Created by Nathaniel Symer on 7/10/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FHSGradientView;

@interface PostDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, PullToRefreshViewDelegate> {
    UIActivityIndicatorView *aivy;
}

- (id)initWithPost:(NSMutableDictionary *)posty;

@property (strong, nonatomic) UIButton *linkButton;

@property (strong, nonatomic) UITableView *commentsTableView;
@property (strong, nonatomic) UIImageView *theImageView;
@property (strong, nonatomic) UINavigationBar *navBar;
@property (strong, nonatomic) UILabel *displayNameLabel;
@property (strong, nonatomic) UITextView *messageView;
@property (strong, nonatomic) FHSGradientView *gradientView;
@property (strong, nonatomic) PullToRefreshView *pull;

@property (strong, nonatomic) NSMutableDictionary *post;

@property (assign, nonatomic) BOOL isLoadingImage;
@property (assign, nonatomic) BOOL isLoadingComments;

@end
