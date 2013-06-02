//
//  NSArray+RemoveDuplicates.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/7/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "NSArray+RemoveDuplicates.h"

@implementation NSMutableArray (removeDuplicates)

- (void)removeDuplicates {
    NSArray *nonDupes = [[NSSet setWithArray:self]allObjects];
    NSMutableArray *dupes = [self mutableCopy];
    [dupes removeObjectsInArray:nonDupes];
    [self removeObjectsInArray:dupes];
}

@end

@implementation NSArray (arrayByRemovingDuplicates)

- (NSArray *)arrayByRemovingDuplicates {
    return [[NSSet setWithArray:self]allObjects];
}

@end

/*@implementation NSMutableArray (removeDuplicates)

- (void)removeDuplicates {
    NSMutableArray *ret = [NSMutableArray array];
    
    for (id obj in [self mutableCopy]) {
        if (![ret containsObject:obj]) {
            [ret addObject:obj];
        } else {
            [self removeObject:obj];
        }
    }
}

@end*/
