//
//  CustomCellCell.m
//  Test
//
//  Created by Nathaniel Symer on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ColoredCell.h"

CGRect rectFor1PxStroke(CGRect rect) {
    return CGRectMake(rect.origin.x + 0.5, rect.origin.y + 0.5, rect.size.width - 1, rect.size.height - 1);
}

void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef  endColor) {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    
    NSArray *colors = [NSArray arrayWithObjects:(__bridge id)startColor, (__bridge id)endColor, nil];
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    
    CGContextSaveGState(context);
    CGContextAddRect(context, rect);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGContextRestoreGState(context);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

void draw1PxStroke(CGContextRef context, CGPoint startPoint, CGPoint endPoint, CGColorRef color) {
    
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetStrokeColorWithColor(context, color);
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, startPoint.x + 0.5, startPoint.y + 0.5);
    CGContextAddLineToPoint(context, endPoint.x + 0.5, endPoint.y + 0.5);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);        
    
}


@implementation ColoredCell

@synthesize colorLayer;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.textLabel.backgroundColor = [UIColor clearColor];    
        self.textLabel.highlightedTextColor = [UIColor blackColor];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];    
        self.detailTextLabel.highlightedTextColor = [UIColor blackColor];
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        self.colorLayer = [[CALayer alloc]init];
        colorLayer.contentsGravity = kCAGravityCenter;
        colorLayer.contentsScale = [[UIScreen mainScreen]scale];
        [self.layer insertSublayer:colorLayer atIndex:0];
    }
    
    return self;
}

- (void)setIsFacebook:(BOOL)isFacebooks {
    isFacebook = isFacebooks;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    UIColor *lightColor = nil;
    UIColor *darkColor = nil;
    if (isFacebook) {
        // darker blue color
        // lightColor = [UIColor colorWithRed:59.0/255.0 green:89.0/255.0 blue:200.0/255.0 alpha:0.7]; // 200 is 182
        lightColor = [UIColor colorWithRed:0.0 green:0.0 blue:230.0/255.0 alpha:0.7];
        darkColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.7];
        // darkColor = [UIColor colorWithRed:84.0/255.0 green:114.0/255.0 blue:207.0/255.0 alpha:0.7];
    } else {
        // lighter blue
        // subtract 25 from darker color to get lighter color
        lightColor = [UIColor colorWithRed:64.0/255.0 green:153.0/255.0 blue:230.0/255.0 alpha:0.7];
        darkColor = [UIColor colorWithRed:89.0/255.0 green:178.0/255.0 blue:255.0/255.0 alpha:0.7];
    }

    float height = self.frame.size.height;
    
    CGRect paperRect = CGRectMake(0, 0, 320, height);
    
    CGContextRef context = UIGraphicsGetCurrentContext();		
    
    //CGColorRef separatorColor = [UIColor colorWithRed:208.0/255.0 green:208.0/255.0 blue:208.0/255.0 alpha:1.0].CGColor;
    
    CGColorRef separatorColor = [UIColor lightGrayColor].CGColor;
    
    drawLinearGradient(context, paperRect, lightColor.CGColor, darkColor.CGColor);
    
    // Add white 1 px stroke
    CGRect strokeRect = paperRect;
    strokeRect.size.height -= 1;
    strokeRect = rectFor1PxStroke(strokeRect);
    
    CGContextSetStrokeColorWithColor(context, lightColor.CGColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokeRect(context, strokeRect);
    
    // Add separator
     CGPoint startPoint = CGPointMake(paperRect.origin.x, paperRect.origin.y + paperRect.size.height - 1);
     CGPoint endPoint = CGPointMake(paperRect.origin.x + paperRect.size.width - 1, paperRect.origin.y + paperRect.size.height - 1);
     draw1PxStroke(context, startPoint, endPoint, separatorColor);
}

@end
