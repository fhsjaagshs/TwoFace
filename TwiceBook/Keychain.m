//
//  SimpleKeychain.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Keychain.h"



@implementation Keychain

+ (NSMutableDictionary *)getKeychainQuery:(NSString *)service {
    return [@{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrService: service, (__bridge id)kSecAttrAccount: service, (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock }mutableCopy];
}

+ (void)setObject:(id)object forKey:(NSString *)key {
    NSMutableDictionary *keychainQuery = [[self class]getKeychainQuery:key];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    keychainQuery[(__bridge id)kSecValueData] = [NSKeyedArchiver archivedDataWithRootObject:object];
    SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
}

+ (id)objectForKey:(NSString *)key {
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

+ (void)deleteObjectForKey:(NSString *)service {
    SecItemDelete((__bridge CFDictionaryRef)[self getKeychainQuery:service]);
}

@end