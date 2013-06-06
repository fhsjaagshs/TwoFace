//
//  Keychain.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/5/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Keychain.h"
#import <Security/Security.h>

@interface Keychain ()

@property (nonatomic, strong) NSMutableDictionary *keychainItemData;
@property (nonatomic, strong) NSString *keychainidentifier;

@end

@implementation Keychain

+ (Keychain *)sharedKeychain {
    static Keychain *sharedKeychain;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedKeychain = [[Keychain alloc]init];
    });
    return sharedKeychain;
}

- (void)setIdentifier:(NSString *)anIdentifier {
    self.keychainidentifier = anIdentifier;
    NSDictionary *query = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:(__bridge id)kSecClassGenericPassword, _keychainidentifier, (__bridge id)kSecMatchLimitOne, (id)kCFBooleanTrue, nil] forKeys:[NSArray arrayWithObjects:(__bridge id)kSecClass, (__bridge id)kSecAttrGeneric, (__bridge id)kSecMatchLimit, (__bridge id)kSecReturnAttributes, nil]];
    
    CFDictionaryRef result = nil;
    
    if (!SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result) == noErr) {
        [self reset];
        [_keychainItemData setObject:_keychainidentifier forKey:(__bridge id)kSecAttrGeneric];
    } else {
        self.keychainItemData = [self secItemFormatToDictionary:(__bridge id)result];
    }
}

- (void)setObject:(id)inObject forKey:(id)key  {
    if (!inObject) {
        return;
    }
    
    if (!key) {
        return;
    }
    
    if (![[_keychainItemData objectForKey:key] isEqual:inObject]) {
        [_keychainItemData setObject:inObject forKey:key];
        [self writeToKeychain];
    }
}

- (id)objectForKey:(id)key {
    return [_keychainItemData objectForKey:key];
}

- (void)reset {
	OSStatus junk = noErr;
    if (!_keychainItemData) {
        self.keychainItemData = [NSMutableDictionary dictionary];
    } else {
        NSMutableDictionary *tempDictionary = [self dictionaryToSecItemFormat:self.keychainItemData];
		junk = SecItemDelete((__bridge CFDictionaryRef)tempDictionary);
        NSAssert(junk == noErr || junk == errSecItemNotFound, @"Problem deleting current dictionary.");
    }
    
    [_keychainItemData setObject:@"" forKey:(__bridge id)kSecAttrAccount];
    [_keychainItemData setObject:@"" forKey:(__bridge id)kSecAttrLabel];
    [_keychainItemData setObject:@"" forKey:(__bridge id)kSecAttrDescription];
    [_keychainItemData setObject:@"" forKey:(__bridge id)kSecValueData];
}

- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert {
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [returnDictionary setObject:[[dictionaryToConvert objectForKey:(__bridge id)kSecValueData]dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
    return returnDictionary;
}

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert {
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    [returnDictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    CFDataRef result = nil;
    
    if (SecItemCopyMatching((__bridge CFDictionaryRef)returnDictionary, (CFTypeRef *)&result) == noErr) {
        [returnDictionary removeObjectForKey:(__bridge id)kSecReturnData];
        NSData *passwordData = (__bridge id)result;
        NSString *password = [[NSString alloc]initWithBytes:passwordData.bytes length:passwordData.length encoding:NSUTF8StringEncoding];
        [returnDictionary setObject:password forKey:(__bridge id)kSecValueData];
    }
    
	return returnDictionary;
}

- (void)writeToKeychain {
    NSDictionary *query = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:(__bridge id)kSecClassGenericPassword, _keychainidentifier, (__bridge id)kSecMatchLimitOne, (id)kCFBooleanTrue, nil] forKeys:[NSArray arrayWithObjects:(__bridge id)kSecClass, (__bridge id)kSecAttrGeneric, (__bridge id)kSecMatchLimit, (__bridge id)kSecReturnAttributes, nil]];
    
    CFDictionaryRef result = nil;
    
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result) == noErr) {
        NSMutableDictionary *updateItem = [NSMutableDictionary dictionaryWithDictionary:(__bridge id)result];
        [updateItem setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:_keychainItemData];
        [tempCheck removeObjectForKey:(__bridge id)kSecClass];
        SecItemUpdate((__bridge CFDictionaryRef)updateItem, (__bridge CFDictionaryRef)tempCheck);
    } else {
        SecItemAdd((__bridge CFDictionaryRef)[self dictionaryToSecItemFormat:_keychainItemData], nil);
    }
}

@end
