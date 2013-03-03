//
//  TwitterOrFBCell.m
//  TwoFace
//
//  Created by Nate Symer on 7/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TwitterOrFBCell.h"

@implementation TwitterOrFBCell

@synthesize label;

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.label) {
        label = [[UILabel alloc]init];
        label.font = [UIFont fontWithName:@"Helvetica" size:15.0];
        CGRect f = self.textLabel.frame;
        label.frame = CGRectMake(f.size.width+30, f.origin.y, 320-(f.size.width+30), 0);
        [self addSubview:self.label];
    }
}

- (void)setFacebook:(BOOL)isFacebook {
    
    NSString *cellText = nil;
    
    if (isFacebook) {
        cellText = @"Facebook";
        self.label.textColor = [UIColor colorWithRed:59.0/255.0 green:89.0/255.0 blue:182.0/255.0 alpha:1.0];
    } else {
        cellText = @"Twitter";
        self.label.textColor = [UIColor colorWithRed:89.0/255.0 green:178.0/255.0 blue:255.0/255.0 alpha:1.0];
    }
    
    CGSize constraintSize = CGSizeMake(320-(self.textLabel.frame.size.width+30), MAXFLOAT);
    CGSize labelSize = [cellText sizeWithFont:label.font constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
    label.text = cellText;
    CGRect f = self.textLabel.frame;
    label.frame = CGRectMake(f.size.width+30, f.origin.y, 320-(f.size.width+30), labelSize.height);
}

@end
