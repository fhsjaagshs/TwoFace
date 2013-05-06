//
//  Common.h
//  CoolTable
//
//  Created by Ray Wenderlich on 9/29/10.
//  Copyright 2010 Ray Wenderlich. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LIGHT_BLUE [UIColor colorWithRed:105.0f/255.0f green:179.0f/255.0f blue:216.0f/255.0f alpha:1.0].CGColor
#define DARK_BLUE [UIColor colorWithRed:21.0/255.0 green:92.0/255.0 blue:136.0/255.0 alpha:1.0].CGColor
#define DARK_BLUE_TWO [UIColor colorWithRed:31.0/255.0 green:102.0/255.0 blue:146.0/255.0 alpha:1.0].CGColor
#define LIGHT_GRAY [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0].CGColor
#define DARK_GRAY [UIColor darkGrayColor].CGColor

void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef  endColor);
CGRect rectFor1PxStroke(CGRect rect);
void draw1PxStroke(CGContextRef context, CGPoint startPoint, CGPoint endPoint, CGColorRef color);
void drawGlossAndGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef endColor);
static inline double radians (double degrees) { return degrees * M_PI/180; }
CGMutablePathRef createArcPathFromBottomOfRect(CGRect rect, CGFloat arcHeight);
UIImage * getButtonImage(void);
UIImage * getUIButtonImageNonPressed(void);
UIImage * getUIButtonImagePressed(void);
UIImage * getButtonImagePressed(void);




// Good blue color: 100 200 100