//
//  AdditionalLabelCell.m
//  TwoFace
//
//  Created by Nathaniel Symer on 7/24/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "AdditionalLabelCell.h"

#define additionalLabelFrame CGRectMake(self.textLabel.frame.size.width+20, self.textLabel.frame.origin.y, 320-(self.textLabel.frame.size.width)-35, self.textLabel.frame.size.height)

@implementation AdditionalLabelCell

@synthesize additionalLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.additionalLabel = [[UILabel alloc]initWithFrame:additionalLabelFrame];
        self.additionalLabel.textAlignment = UITextAlignmentRight;
        self.additionalLabel.font = [UIFont boldSystemFontOfSize:14];
        [self addSubview:self.additionalLabel];
        self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y, self.textLabel.frame.size.width-35, self.textLabel.frame.size.height);
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.additionalLabel.frame = additionalLabelFrame;
}

@end
