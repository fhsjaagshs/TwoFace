//
//  TimeUpdatingLabel.h
//  TwoFace
//
//  Created by Nathaniel Symer on 10/13/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimeUpdatingLabel : UILabel

@property (strong, nonatomic) NSDate *date;

- (void)stop;
- (void)start;
- (id)initWithDate:(NSDate *)aDate;

@end
