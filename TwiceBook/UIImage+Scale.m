//
//  UIImage+Scale.m
//  TwoFace
//
//  Created by Nathaniel Symer on 8/11/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "UIImage+Scale.h"

@implementation UIImage (scale)

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 32, 32);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)thumbnailImageWithSideOfLength:(float)length {
    
    UIImage *startImage = self;
    UIImage *thumbnail = nil;
    
    UIImageView *mainImageView = [[UIImageView alloc] initWithImage:startImage];
    
    BOOL widthGreaterThanHeight = (startImage.size.width > startImage.size.height);
    float sideFull = widthGreaterThanHeight?startImage.size.height:startImage.size.width;
    CGRect clippedRect = CGRectMake(0, 0, sideFull, sideFull);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(length, length), YES, [UIScreen mainScreen].scale);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextClipToRect(currentContext, clippedRect);
    CGFloat scaleFactor = length/sideFull;
    if (widthGreaterThanHeight) {
        float number = -1*((startImage.size.width-sideFull)/2)*scaleFactor;
        CGContextTranslateCTM(currentContext, number, 0);
    } else {
        float number = -((startImage.size.height-sideFull)/2)*scaleFactor;
        CGContextTranslateCTM(currentContext, 0, number);
    }

    CGContextScaleCTM(currentContext, scaleFactor, scaleFactor);
    [mainImageView.layer renderInContext:currentContext];
    thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return thumbnail;
}

- (UIImage *)scaleToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

- (UIImage *)scaleProportionallyToSize:(CGSize)size {
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = size.width;
    CGFloat targetHeight = size.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, size) == NO) {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor < heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        
        if (widthFactor < heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else if (widthFactor > heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    
    // this is actually the interesting part:
    
 //  UIGraphicsBeginImageContext(CGSizeMake(scaledWidth, scaledHeight));
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(scaledWidth, scaledHeight), YES, [UIScreen mainScreen].scale);
    
    CGRect thumbnailRect = CGRectZero;
  //  thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (newImage == nil) NSLog(@"could not scale image");
    
    
    return newImage;
}

@end