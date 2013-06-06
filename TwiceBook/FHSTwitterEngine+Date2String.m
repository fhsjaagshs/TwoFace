//
//  FHSTwitterEngine+FHSTwitterEngine_Date2String.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "FHSTwitterEngine+Date2String.h"
#import "FHSTwitterEngine.h"

@implementation FHSTwitterEngine (FHSTwitterEngine_Date2String)

+ (NSDateFormatter *)formatter {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc]init];
        formatter.locale = [[NSLocale alloc]initWithLocaleIdentifier:@"en_US"];
        formatter.dateStyle = NSDateFormatterLongStyle;
        formatter.formatterBehavior = NSDateFormatterBehavior10_4;
        formatter.dateFormat = @"EEE MMM dd HH:mm:ss ZZZZ yyyy";
    });
    return formatter;
}

- (NSString *)stringFromDate:(NSDate *)date {
    return [[FHSTwitterEngine formatter]stringFromDate:date];
}

@end
