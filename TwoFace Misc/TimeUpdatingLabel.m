//
//  TimeUpdatingLabel.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/13/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "TimeUpdatingLabel.h"

@implementation TimeUpdatingLabel

- (id)initWithDate:(NSDate *)aDate {
    self = [super initWithFrame:CGRectMake(0, 0, 25, 35)];
    if (self) {
        self.date = aDate;
        self.font = [UIFont boldSystemFontOfSize:12];
        self.text = [self.date timeElapsedSinceCurrentDate];
        [self start];
    }
    return self;
}

- (void)update {
    self.text = [self.date timeElapsedSinceCurrentDate];
}

- (void)start {
    [self performSelector:@selector(update) withObject:nil afterDelay:1.0f];
}

- (void)stop {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(update) object:nil];
}

@end
