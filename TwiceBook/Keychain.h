//
//  SimpleKeychain.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kKeychainAccessTokenKey;

@interface Keychain : NSObject

+ (void)setObject:(id)object forKey:(NSString *)key;
+ (id)objectForKey:(NSString *)service;
+ (void)deleteObjectForKey:(NSString *)key;

@end
