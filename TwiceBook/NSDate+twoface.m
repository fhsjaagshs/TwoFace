//
//  NSDate+twoface.m
//  TwoFace
//
//  Created by Nathaniel Symer on 12/16/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "NSDate+twoface.h"

@implementation NSDate (twoface)

+ (NSDateFormatter *)formatterWithFormat:(NSString *)format {
    static NSMutableDictionary *formatters = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatters = [NSMutableDictionary dictionary];
    });
    
    NSDateFormatter *ret = formatters[format];
    
    if (!ret) {
        ret = [[NSDateFormatter alloc]init];
        ret.dateFormat = format;
        formatters[format] = ret;
    }
    
    return ret;
}

- (NSString *)stringDaysAgo {
    NSDateFormatter *formatter = [NSDate formatterWithFormat:@"yyyy-MM-dd"];

	NSDate *midnight = [formatter dateFromString:[formatter stringFromDate:self]];
	
	NSUInteger daysAgo = (int)[midnight timeIntervalSinceNow]/(60*60*24)*-1;
	
    NSString *text = nil;
	switch (daysAgo) {
		case 0:
			text = @"Today";
			break;
		case 1:
			text = @"Yesterday";
			break;
		default:
			text = [NSString stringWithFormat:@"%d days ago", daysAgo];
	}
	return text;
}

- (NSString *)timeElapsedSinceCurrentDate {
    
    double interval = [[NSDate date]timeIntervalSinceDate:self];
    
    float day = interval/(60*60*24);
    float hour = interval/(60*60);
    float minute = interval/60;
    float second = interval;
    
    BOOL isDay = (day >= 1);
    BOOL isHour = (hour >= 1);
    BOOL isMinute = (minute >= 1);
    BOOL isSecond = (second >= 1);
    
    NSString *suffix = @"s";
    double howMany = 0;
    
    if (isSecond) {
        howMany = interval;
        suffix = @"s";
    }
    
    if (isMinute) {
        howMany = interval/60;
        suffix = @"m";
    }
    
    if (isHour) {
        howMany = interval/(60*60);
        suffix = @"h";
    }
    
    if (isDay) {
        howMany = interval/(60*60*24);
        suffix = @"d";
    }
    
    return [NSString stringWithFormat:@"%.0f%@",howMany,suffix];
}

@end
