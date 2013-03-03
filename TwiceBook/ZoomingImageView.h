//
//  ZoomingImageView.h
//  ZommingImageView
//
//  Created by Nathaniel Symer on 7/11/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZoomingImageView : UIScrollView <UIScrollViewDelegate>

- (void)zoomOut;
- (void)loadImage:(UIImage *)image;

@property (strong, nonatomic) UIImageView *theImageView;

@end
