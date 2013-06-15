//
//  ColorBandView.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/12/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "ColorBandView.h"

@interface ColorBandView ()

@property (nonatomic, assign) BOOL isFacebook;
@property (nonatomic, assign) BOOL shouldClear;

@end

@implementation ColorBandView

- (void)drawRect:(CGRect)rect {
    
    if (!_shouldClear) {
        UIColor *startColor;
        UIColor *endColor;
        
        if (_isFacebook) {
            startColor = [UIColor colorWithRed:59.0/255.0 green:89.0/255.0 blue:152.0/255.0 alpha:1.0];
            endColor = [UIColor colorWithRed:29.0/255.0 green:59.0/255.0 blue:122.0/255.0 alpha:1.0];
        } else {
            startColor = [UIColor colorWithRed:64.0/255.0 green:153.0/255.0 blue:1 alpha:1.0];
            endColor = [UIColor colorWithRed:34.0/255.0 green:123.0/255.0 blue:225.0/225.0 alpha:1.0];
        }
        
        CGPoint startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect));
        CGPoint endPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect));
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGFloat locations[] = { 0.0, 1.0 };
        NSArray *colors = [NSArray arrayWithObjects:(__bridge id)startColor.CGColor, (__bridge id)endColor.CGColor, nil];
        CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge_retained CFArrayRef)colors, locations);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSaveGState(context);
        CGContextAddRect(context, rect);
        CGContextClip(context);
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
        CGContextRestoreGState(context);
        
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorSpace);
    }
    
    self.shouldClear = NO;
}

- (void)drawWithIsFacebook:(BOOL)isFacebook {
    _isFacebook = isFacebook;
    self.backgroundColor = [UIColor clearColor];
    [self setNeedsDisplay];
}

- (void)clear {
    self.shouldClear = YES;
    [self setNeedsDisplay];
}

@end
