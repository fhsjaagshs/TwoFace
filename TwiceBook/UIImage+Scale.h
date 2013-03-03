//
//  UIImage+Scale.h
//  TwoFace
//
//  Created by Nathaniel Symer on 8/11/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

@interface UIImage (scale)

- (UIImage *)scaleToSize:(CGSize)size;
- (UIImage *)scaleProportionallyToSize:(CGSize)size;
- (UIImage *)thumbnailImageWithSideOfLength:(float)length;
+ (UIImage *)imageWithColor:(UIColor *)color;

@end