//
//  NSString+mods.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/24/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (mods)

- (BOOL)testRegex:(NSString *)expression;
- (CGSize)sizeWithMaxSize:(CGSize)size font:(UIFont *)font;
- (NSString *)stringByRemovingHTMLEntities;
- (NSString *)stringByCapitalizingFirstLetter;
- (int)occurencesOfString:(NSString *)string;
- (BOOL)containsString:(NSString *)otherString;
- (NSString *)stringByTrimmingExtraInternalSpacing;
- (NSString *)stringBySanitizingForFilename;
- (NSString *)stringByTrimmingWhitespace;

@end
