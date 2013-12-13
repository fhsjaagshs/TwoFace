//
//  UserSelectorCell.m
//  TwoFace
//
//  Created by Nathaniel Symer on 12/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "UserSelectorCell.h"

@implementation UserSelectorCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
