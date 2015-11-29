//
//  NSString+mods.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/24/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "NSString+mods.h"

@implementation NSString (mods)

- (BOOL)testRegex:(NSString *)expression {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
    return match != nil;
}

- (CGSize)sizeWithMaxSize:(CGSize)size font:(UIFont *)font {
    NSAttributedString *attributedText = [[NSAttributedString alloc]initWithString:self attributes:@{ NSFontAttributeName: font }];
    return [attributedText boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
}

- (NSString *)stringByTrimmingWhitespace {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)stringByRemovingHTMLEntities {
    NSString *me = self;
    me = [me stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    me = [me stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    me = [me stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    me = [me stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    me = [me stringByReplacingOccurrencesOfString:@"&circ;" withString:@"^"];
    me = [me stringByReplacingOccurrencesOfString:@"&tilde;" withString:@"~"];
    me = [me stringByReplacingOccurrencesOfString:@"&dagger;" withString:@"†"];
    me = [me stringByReplacingOccurrencesOfString:@"&Dagger;" withString:@"‡"];
    return me;
}

- (NSString *)stringByCapitalizingFirstLetter {
    return [self stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[self substringToIndex:1] uppercaseString]];
}

- (NSUInteger)occurencesOfString:(NSString *)string {
    NSUInteger count = 0;
    NSRange range = NSMakeRange(0, self.length);
    while(range.location != NSNotFound) {
        range = [self rangeOfString:string options:0 range:range];
        if (range.location != NSNotFound) {
            range = NSMakeRange(range.location+range.length, self.length-(range.location+range.length));
            count++; 
        }
    }
    return count;
}

- (BOOL)containsString:(NSString *)otherString {
    if ([self rangeOfString:otherString].location == NSNotFound) {
        return NO;
    } else {
        return YES;
    }
}

- (NSString *)stringByTrimmingExtraInternalSpacing {
    
    NSString *string = self;

    while ([string rangeOfString:@"  "].location != NSNotFound) {
        string = [string stringByReplacingOccurrencesOfString:@"  " withString:@" "];
    }
    return string;
}

- (NSString *)stringBySanitizingForFilename {
    NSCharacterSet *illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
    return [[self componentsSeparatedByCharactersInSet:illegalFileNameCharacters]componentsJoinedByString:@""];
}

@end
