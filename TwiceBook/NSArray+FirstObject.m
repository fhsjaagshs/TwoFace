//
//  NSArray+FirstObject.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/13/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "NSArray+FirstObject.h"

@implementation NSArray (FirstObject)

- (id)firstObjectA {
    return [self firstObjectCommonWithArray:self];
}

@end
