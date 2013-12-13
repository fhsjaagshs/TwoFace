//
//  PostDetailViewController.h
//  TwoFace
//
//  Created by Nathaniel Symer on 7/10/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FHSGradientView;

@interface PostDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (id)initWithPost:(Status *)posty;

@property (strong, nonatomic) Status *post;

@property (assign, nonatomic) BOOL isLoadingImage;
@property (assign, nonatomic) BOOL isLoadingComments;

@end
