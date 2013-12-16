//
//  NSDate+twoface.h
//  TwoFace
//
//  Created by Nathaniel Symer on 12/16/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (twoface)

- (NSString *)timeElapsedSinceCurrentDate;
- (NSString *)stringDaysAgo;

+ (NSDateFormatter *)twoface_formatter;

@end
