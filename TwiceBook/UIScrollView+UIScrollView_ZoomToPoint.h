//
//  UIScrollView+UIScrollView_ZoomToPoint.h
//  TwoFace
//
//  Created by Nathaniel Symer on 9/8/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (UIScrollView_ZoomToPoint)

- (void)zoomToPoint:(CGPoint)zoomPoint withScale:(CGFloat)scale animated:(BOOL)animated;

@end
