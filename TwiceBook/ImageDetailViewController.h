//
//  ImageDetailViewController.h
//  TwoFace
//
//  Created by Nathaniel Symer on 7/11/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageDetailViewController : UIViewController <UIGestureRecognizerDelegate>

- (id)initWithImagePath:(NSString *)path;
- (id)initWithData:(NSData *)data;
- (id)initWithImage:(UIImage *)imagey;

@property (strong, nonatomic) ZoomingImageView *zoomingImageView;
@property (strong, nonatomic) UINavigationBar *navBar;
@property (strong, nonatomic) UIImage *image;
@property (assign, nonatomic) BOOL shouldShowSaveButton;

@end
