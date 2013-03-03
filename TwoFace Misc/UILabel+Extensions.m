//
//  UILabel+Extensions.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/7/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "UILabel+Extensions.h"

@implementation UILabel (Extensions)

- (NSArray *)lines {
    
    if (self.lineBreakMode != UILineBreakModeWordWrap) {
        return nil;
    }
    
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:10];
    
    NSCharacterSet *wordSeparators = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    NSString *currentLine = self.text;
    int textLength = [self.text length];
    
    NSRange rCurrentLine = NSMakeRange(0, textLength);
    NSRange rWhitespace = NSMakeRange(0,0);
    NSRange rRemainingText = NSMakeRange(0, textLength);
    BOOL done = NO;
    while (!done) {
        // determine the next whitespace word separator position
        rWhitespace.location = rWhitespace.location+rWhitespace.length;
        rWhitespace.length = textLength-rWhitespace.location;
        rWhitespace = [self.text rangeOfCharacterFromSet:wordSeparators options:NSCaseInsensitiveSearch range:rWhitespace];
        if (rWhitespace.location == NSNotFound) {
            rWhitespace.location = textLength;
            done = YES;
        }
        
        NSRange rTest = NSMakeRange(rRemainingText.location, rWhitespace.location-rRemainingText.location);
        
        NSString *textTest = [self.text substringWithRange:rTest];
        
        CGSize sizeTest = [textTest sizeWithFont:self.font forWidth:1024.0 lineBreakMode:UILineBreakModeWordWrap];
        if (sizeTest.width > self.bounds.size.width) {
            [lines addObject: [currentLine stringByTrimmingCharactersInSet:wordSeparators]];
            rRemainingText.location = rCurrentLine.location+rCurrentLine.length;
            rRemainingText.length = textLength-rRemainingText.location;
            currentLine = [self.text substringWithRange:rRemainingText];
            continue;
        }
        
        rCurrentLine = rTest;
        currentLine = textTest;
    }
    
    [lines addObject:[currentLine stringByTrimmingCharactersInSet:wordSeparators]];
    
    return lines;
}

@end
