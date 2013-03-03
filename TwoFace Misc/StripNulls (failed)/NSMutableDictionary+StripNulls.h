//
//  NSMutableDictionary+StripNulls.h
//  TwoFace
//
//  Created by Nathaniel Symer on 9/11/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (StripNulls)

//- (NSDictionary *) dictionaryByReplacingNullsWithStrings;

+ (NSMutableArray *)traverseDictionary:(NSDictionary *)aDictionary;

- (void)removeNullValues;

- (void)removeNullValues2;

- (void)removeNullValues3;

@end
