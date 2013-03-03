//
//  CustomCellCell.h
//  Test
//
//  Created by Nathaniel Symer on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

CGRect rectFor1PxStroke(CGRect rect);

void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef  endColor);

void draw1PxStroke(CGContextRef context, CGPoint startPoint, CGPoint endPoint, CGColorRef color);


@interface ColoredCell : UITableViewCell {
    BOOL isFacebook;
}

@property (strong, nonatomic) CALayer *colorLayer;

- (void)setIsFacebook:(BOOL)isFacebook;

@end
