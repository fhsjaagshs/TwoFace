//
//  NSMutableArray+StripNulls.m
//  TwoFace
//
//  Created by Nathaniel Symer on 9/10/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "NSMutableArray+StripNulls.h"

@implementation NSMutableArray (StripNulls)

- (void)stripNullValues {
    for (int i = [self count] - 1; i >= 0; i--) {
        id value = [self objectAtIndex:i];
        
        if (value == [NSNull null]) {
            [self removeObjectAtIndex:i];
        } else if ([value isKindOfClass:[NSArray class]] ||
                 [value isKindOfClass:[NSDictionary class]]) {
            if (![value respondsToSelector:@selector(setObject:forKey:)] &&
                ![value respondsToSelector:@selector(addObject:)])
            {
                value = [value mutableCopy];
                [self replaceObjectAtIndex:i withObject:value];
            }
            [value stripNullValues];
        }
    }
}

@end
