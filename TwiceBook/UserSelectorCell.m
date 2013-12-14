//
//  UserSelectorCell.m
//  TwoFace
//
//  Created by Nathaniel Symer on 12/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "UserSelectorCell.h"

@implementation UserSelectorCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.user_id = nil;
    self.username = nil;
}

@end
