//
//  UIViewController+InitWithAutoNib.m
//  TwoFace
//
//  Created by Nathaniel Symer on 9/14/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "UIViewController+InitWithAutoNib.h"

@implementation UIViewController (InitWithAutoNib)

- (id)initWithAutoNib {
    self = [self initWithNibName:NSStringFromClass([self class]) bundle:nil];
    
    if (self) {
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self.view setBackgroundColor:[UIColor underPageBackgroundColor]];
    }
    
    return self;
}

@end
