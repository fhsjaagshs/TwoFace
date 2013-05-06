//
//  ViewController.m
//  TwoFace Icon
//
//  Created by Nathaniel Symer on 8/30/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ViewController.h"
#import "Common.h"
#import <CoreText/CoreText.h>
#import "UIImage+Additions.h"

@implementation ViewController

- (CGRect)getBoundsForString:(NSString *)string {
    int charCount = [string length];
    CGGlyph glyphs[charCount];
    CGRect rects[charCount];
    
    // CGFontRef theCTFont = CGFontCreateWithFontName((CFStringRef)[UIFont systemFontOfSize:30].fontName);
    UIFont *font = [UIFont systemFontOfSize:400];
    
    CTFontRef theCTFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    
    CTFontGetGlyphsForCharacters(theCTFont, (const unichar*)[string cStringUsingEncoding:NSUnicodeStringEncoding], glyphs, charCount);
    CTFontGetBoundingRectsForGlyphs(theCTFont, kCTFontDefaultOrientation, glyphs, rects, charCount);
    
    int totalwidth = 0, maxheight = 0;
    for (int i=0; i < charCount; i++)
    {
        totalwidth += rects[i].size.width;
        maxheight = maxheight < rects[i].size.height ? rects[i].size.height : maxheight;
    }
    
    return CGRectMake(0, 0, totalwidth, maxheight);
}

void drawF(CGContextRef context) {
    
    CGRect pseudoBounds = CGRectMake(0, 0, 512, 512);
    
    CGContextSaveGState(context);
    
    char* text = "f";
    CGContextSelectFont(context, "ArialRoundedMTBold", 445, kCGEncodingMacRoman); // 400 is centered
    CGAffineTransform xform = CGAffineTransformMake(1.0,  0.0, 0.0, -1.0, 0.0,  0.0);
    CGContextSetTextMatrix(context, xform);
    
    float y = (pseudoBounds.size.height/2)+200; // 128 for 400
    float x = (pseudoBounds.size.width/2)+60; // 128 for 400
    
    float shadowConstant = 10;
    
    
    CGContextSaveGState(context);
    
    // draw text with top shadow
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetShadowWithColor(context, CGSizeMake(0, -shadowConstant), 32, [UIColor blackColor].CGColor);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    // draw text with bottom shadow
    CGContextSetShadowWithColor(context, CGSizeMake(0, shadowConstant), 32, [UIColor blackColor].CGColor);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    // draw text with left shadow
    CGContextSetShadowWithColor(context, CGSizeMake(-shadowConstant, 0), 32, [UIColor blackColor].CGColor);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    // draw text with right shadow
    CGContextSetShadowWithColor(context, CGSizeMake(shadowConstant, 0), 32, [UIColor blackColor].CGColor);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    CGContextRestoreGState(context);
    
    // clip to letter
    CGContextSetTextDrawingMode(context, kCGTextClip);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    //drawLinearGradient(context, pseudoBounds, LIGHT_BLUE, DARK_BLUE_TWO);
    
    CGContextSaveGState(context);
    
    CGColorRef redColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
    CGColorRef asdfColor = [UIColor colorWithRed:59.0/255.0 green:89.0/255.0 blue:182.0/255.0 alpha:1.0].CGColor;
    
    CGContextSetFillColorWithColor(context, redColor);
    CGContextFillRect(context, pseudoBounds);
    
    //CGContextRestoreGState(context);
    
    // CGContextSaveGState(context); //Save Context State Before Clipping "hatchPath"
    
    CGFloat spacer = 120.0f;
    int rows = (pseudoBounds.size.width + pseudoBounds.size.height/spacer);
    CGFloat padding = 0.0f;
    CGMutablePathRef hatchPath = CGPathCreateMutable();
    for(int i =  1; i<=rows; i++) {
        CGPathMoveToPoint(hatchPath, NULL, spacer * i, padding);
        CGPathAddLineToPoint(hatchPath, NULL, padding, spacer * i);
    }
    CGContextAddPath(context, hatchPath);
    CGPathRelease(hatchPath);
    CGContextSetLineWidth(context, 40.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, asdfColor);
    CGContextDrawPath(context, kCGPathStroke);
    
    CGContextRestoreGState(context);
}

- (UIImage *)getIconImage {
    CGRect pseudoBounds = CGRectMake(0, 0, 512, 512);
    
    UIGraphicsBeginImageContext(CGSizeMake(512, 512));
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    
    //
    // Draw Background
    //
    /*CGContextSaveGState(context);
    //CGColorRef redColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0].CGColor;  // 0.55
   // CGColorRef asdfColor = [UIColor colorWithRed:0.55 green:0.55 blue:0.55 alpha:1.0].CGColor;    // 0.6
    CGColorRef redColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
    CGColorRef asdfColor = [UIColor colorWithRed:64.0/255.0 green:153.0/255.0 blue:1.0 alpha:1.0].CGColor;
    
    CGContextSetFillColorWithColor(context, redColor);
    CGContextFillRect(context, pseudoBounds);
    
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context); //Save Context State Before Clipping "hatchPath"
    
    CGFloat spacer = 120.0f;
    int rows = (pseudoBounds.size.width + pseudoBounds.size.height/spacer);
    CGFloat padding = 0.0f;
    CGMutablePathRef hatchPath = CGPathCreateMutable();
    for(int i =  1; i<=rows; i++) {
        CGPathMoveToPoint(hatchPath, NULL, spacer * i, padding);
        CGPathAddLineToPoint(hatchPath, NULL, padding, spacer * i);
    }
    CGContextAddPath(context, hatchPath);
    CGPathRelease(hatchPath);
    CGContextSetLineWidth(context, 40.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, asdfColor);
    CGContextDrawPath(context, kCGPathStroke);
    CGContextRestoreGState(context); //Restore Last Context State Before Clipping "hatchPath"*/
    
    
    //
    // Draw S
    //
    
    CGContextSaveGState(context);
    
    char* text = "t";
    CGContextSelectFont(context, "Courier-Bold", 445, kCGEncodingMacRoman); // 400 is centered
    CGAffineTransform xform = CGAffineTransformMake(1.0,  0.0, 0.0, -1.0, 0.0,  0.0);
    CGContextSetTextMatrix(context, xform);
    
    float y = (pseudoBounds.size.height/2)+100; // 128 for 400  ORIG: +170
    float x = (pseudoBounds.size.width/2)-240; // 128 for 400 ORIG: -160
    
    float shadowConstant = 10;
    
    
    CGContextSaveGState(context);
    
    // draw text with top shadow
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetShadowWithColor(context, CGSizeMake(0, -shadowConstant), 32, [UIColor blackColor].CGColor);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    // draw text with bottom shadow
    CGContextSetShadowWithColor(context, CGSizeMake(0, shadowConstant), 32, [UIColor blackColor].CGColor);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    // draw text with left shadow
    CGContextSetShadowWithColor(context, CGSizeMake(-shadowConstant, 0), 32, [UIColor blackColor].CGColor);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    // draw text with right shadow
    CGContextSetShadowWithColor(context, CGSizeMake(shadowConstant, 0), 32, [UIColor blackColor].CGColor);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context);
    
    // clip to letter
    CGContextSetTextDrawingMode(context, kCGTextClip);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    CGContextSetShadowWithColor(context, CGSizeMake(0, shadowConstant), 8, [UIColor blackColor].CGColor);
    
    //drawLinearGradient(context, pseudoBounds, LIGHT_BLUE, DARK_BLUE_TWO);
    
    CGColorRef redColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
    CGColorRef asdfColor = [UIColor colorWithRed:64.0/255.0 green:153.0/255.0 blue:1.0 alpha:1.0].CGColor;
    
    CGContextSetFillColorWithColor(context, redColor);
    CGContextFillRect(context, pseudoBounds);
    
    //CGContextRestoreGState(context);
    
   // CGContextSaveGState(context); //Save Context State Before Clipping "hatchPath"
    
    CGFloat spacer = 120.0f;
    int rows = (pseudoBounds.size.width + pseudoBounds.size.height/spacer);
    CGFloat padding = 0.0f;
    CGMutablePathRef hatchPath = CGPathCreateMutable();
    for(int i = 1; i<=rows; i++) {
        CGPathMoveToPoint(hatchPath, NULL, spacer * i, padding);
        CGPathAddLineToPoint(hatchPath, NULL, padding, spacer * i);
    }
    CGContextAddPath(context, hatchPath);
    CGPathRelease(hatchPath);
    CGContextSetLineWidth(context, 40.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, asdfColor);
    CGContextDrawPath(context, kCGPathStroke);
    
    CGContextRestoreGState(context);
    
    drawF(context);
    
    UIGraphicsPopContext();
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return outputImage;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [super viewDidLoad];
    UIImage *image = [self getIconImage];

    UIImage *iPadRetina = [image scaleToSize:CGSizeMake(144, 144)];
    UIImage *iPad = [image scaleToSize:CGSizeMake(72, 72)];
    UIImage *iPhoneRetina = [image scaleToSize:CGSizeMake(114, 114)];
    UIImage *iPhone = [image scaleToSize:CGSizeMake(57, 57)];
    
    [UIImagePNGRepresentation(image) writeToFile:@"/Users/wiedmersymer/Desktop/SwiftloadIconry/iTunesArtwork.png" atomically:YES];
    [UIImagePNGRepresentation(iPadRetina) writeToFile:@"/Users/wiedmersymer/Desktop/SwiftloadIconry/icon~iPad@2x.png" atomically:YES];
    [UIImagePNGRepresentation(iPad) writeToFile:@"/Users/wiedmersymer/Desktop/SwiftloadIconry/icon~iPad.png" atomically:YES];
    [UIImagePNGRepresentation(iPhoneRetina) writeToFile:@"/Users/wiedmersymer/Desktop/SwiftloadIconry/icon@2x.png" atomically:YES];
    [UIImagePNGRepresentation(iPhone) writeToFile:@"/Users/wiedmersymer/Desktop/SwiftloadIconry/icon.png" atomically:YES];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
