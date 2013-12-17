//
//  ImageDetailViewController.h
//  TwoFace
//
//  Created by Nathaniel Symer on 7/11/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageDetailViewController : UIViewController <UIGestureRecognizerDelegate>

- (instancetype)initWithImagePath:(NSString *)path;
- (instancetype)initWithData:(NSData *)data;
- (instancetype)initWithImage:(UIImage *)imagey;

@property (assign, nonatomic) BOOL shouldShowSaveButton;

@end
