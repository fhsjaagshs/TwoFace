//
//  NSArray+RemoveDuplicates.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/7/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "NSArray+RemoveDuplicates.h"

@implementation NSMutableArray (RemoveDuplicates)

- (void)removeDuplicates {
    NSArray *nonDupes = [[NSSet setWithArray:self]allObjects];
    NSMutableArray *dupes = [self mutableCopy];
    [dupes removeObjectsInArray:nonDupes];
    [self removeObjectsInArray:dupes];
}

@end

@implementation NSArray (RemoveDuplicates)

- (NSArray *)arrayByRemovingDuplicates {
    return [[NSSet setWithArray:self]allObjects];
}

@end
