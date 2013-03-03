//
//  CommentViewController.h
//  TwoFace
//
//  Created by Nathaniel Symer on 7/11/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentViewController : UIViewController <UITextViewDelegate>

- (id)initWithPostID:(NSString *)postID;

@property (strong, nonatomic) NSString *postIdentifier;
@property (strong, nonatomic) UINavigationBar *navBar;
@property (strong, nonatomic) UITextView *commentField;

@property (assign, nonatomic) CGRect originalTextViewFrame;

@end
