//
//  FHSGradientBGLabel.m
//  TwoFace
//
//  Created by Nathaniel Symer on 8/7/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "FHSGradientView.h"
#import <QuartzCore/QuartzCore.h>

@implementation FHSGradientView

#define TABLE_CELL_BACKGROUND    { 1, 1, 1, 1, 0.866, 0.866, 0.866, 1}			// #FFFFFF and #DDDDDD
#define kDefaultMargin 10

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)aRect {
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    int lineWidth = 1;
    
    CGRect rect = self.bounds;
    CGFloat minx = CGRectGetMinX(rect);
    CGFloat midx = CGRectGetMidX(rect);
    CGFloat maxx = CGRectGetMaxX(rect);
    CGFloat miny = CGRectGetMinY(rect);
    CGFloat midy = CGRectGetMidY(rect);
    CGFloat maxy = CGRectGetMaxY(rect);
    miny -= 1;
    
    CGFloat locations[2] = { 0.0, 1.0 };
    CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
    CGFloat components[8] = TABLE_CELL_BACKGROUND;
    CGContextSetStrokeColorWithColor(c, [[UIColor darkGrayColor]CGColor]);
    CGContextSetLineWidth(c, lineWidth);
    CGContextSetAllowsAntialiasing(c, YES);
    CGContextSetShouldAntialias(c, YES);
    
    miny += 1;
    
	CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, minx, midy);
    CGPathAddArcToPoint(path, nil, minx, miny, midx, miny, kDefaultMargin);
    CGPathAddArcToPoint(path, nil, maxx, miny, maxx, midy, kDefaultMargin);
    CGPathAddArcToPoint(path, nil, maxx, maxy, midx, maxy, kDefaultMargin);
    CGPathAddArcToPoint(path, nil, minx, maxy, minx, midy, kDefaultMargin);
	CGPathCloseSubpath(path);
    
	// Fill and stroke the path
	CGContextSaveGState(c);
	CGContextAddPath(c, path);
	CGContextClip(c);
    
	CGGradientRef myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, 2);
	CGContextDrawLinearGradient(c, myGradient, CGPointMake(minx,miny), CGPointMake(minx,maxy), 0);
    
	CGContextAddPath(c, path);
	CGPathRelease(path);
	CGContextStrokePath(c);
	CGContextRestoreGState(c);

    CGColorSpaceRelease(myColorspace);
    CGGradientRelease(myGradient);
}

@end
