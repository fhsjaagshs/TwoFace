//
//  SimpleKeychain.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Keychain.h"

@implementation Keychain

+ (Keychain *)shared {
    static Keychain *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[Keychain alloc]init];
    });
    return shared;
}

- (void)setObject:(id)object forKey:(NSString *)key {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    keychainQuery[(__bridge id)kSecValueData] = [NSKeyedArchiver archivedDataWithRootObject:object];
    SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
}

- (id)objectForKey:(NSString *)key {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];
    keychainQuery[(__bridge id)kSecReturnData] = (id)kCFBooleanTrue;
    keychainQuery[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    
    id ret = nil;
    
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        }
        @catch (NSException *e) {
            NSLog(@"Unarchive of %@ failed: %@", key, e);
        }
        @finally {}
    }
    
    if (keyData) {
        CFRelease(keyData);
    }
    return ret;
}

- (void)removeObjectForKey:(NSString *)key {
    SecItemDelete((__bridge CFDictionaryRef)[self getKeychainQuery:key]);
}

- (NSMutableDictionary *)getKeychainQuery:(NSString *)service {
    return [@{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrService: service, (__bridge id)kSecAttrAccount: service, (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock }mutableCopy];
}

+ (void)setObject:(id)object forKey:(NSString *)key {
    Keychain.shared[key] = object;
}

+ (id)objectForKey:(NSString *)key {
    return Keychain.shared[key];
}

+ (void)removeObjectForKey:(NSString *)key {
    [Keychain.shared removeObjectForKey:key];
}

@end