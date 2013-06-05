//
//  KeychainItemWrapper.m
//  TwoFace
//
//  Created by Nathaniel Symer on 7/21/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//


#import "KeychainItemWrapper.h"
#import <Security/Security.h>

/*
 These are the default constants and their respective types,
 available for the kSecClassGenericPassword Keychain Item class:

 kSecAttrAccessGroup			-		CFStringRef
 kSecAttrCreationDate		    -		CFDateRef
 kSecAttrModificationDate       -		CFDateRef
 kSecAttrDescription			-		CFStringRef
 kSecAttrComment				-		CFStringRef
 kSecAttrCreator				-		CFNumberRef
 kSecAttrType                   -		CFNumberRef
 kSecAttrLabel			    	-		CFStringRef
 kSecAttrIsInvisible			-		CFBooleanRef
 kSecAttrIsNegative		    	-		CFBooleanRef
 kSecAttrAccount				-		CFStringRef
 kSecAttrService				-		CFStringRef
 kSecAttrGeneric				-		CFDataRef
 
 See the header file Security/SecItem.h for more details.
*/

@interface KeychainItemWrapper (PrivateMethods)
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;
- (void)writeToKeychain;
@end

@implementation KeychainItemWrapper

@synthesize keychainItemData, genericPasswordQuery;

- (id)initWithIdentifier: (NSString *)identifier accessGroup:(NSString *)accessGroup {
    if (self = [super init]) {
        self.genericPasswordQuery = [NSMutableDictionary dictionary];
		[self.genericPasswordQuery setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
        [self.genericPasswordQuery setObject:identifier forKey:(id)kSecAttrGeneric];
        
		if (accessGroup) {	
			[self.genericPasswordQuery setObject:accessGroup forKey:(id)kSecAttrAccessGroup];
		}
		
        [self.genericPasswordQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
        [self.genericPasswordQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
        
        NSDictionary *tempQuery = [NSDictionary dictionaryWithDictionary:self.genericPasswordQuery];
        
        NSMutableDictionary *outDictionary = nil;
        
        if (!SecItemCopyMatching((CFDictionaryRef)tempQuery, (CFTypeRef *)&outDictionary) == noErr) {
            [self resetKeychainItem];
			[self.keychainItemData setObject:identifier forKey:(id)kSecAttrGeneric];
			if (accessGroup != nil) {
				[self.keychainItemData setObject:accessGroup forKey:(id)kSecAttrAccessGroup];
			}
		} else {
            self.keychainItemData = [self secItemFormatToDictionary:outDictionary];
        }
       
		[outDictionary release];
    }
    
	return self;
}

- (id)initWithIdentifier:(NSString *)identifier {
    return [self initWithIdentifier:identifier accessGroup:nil];
}

- (void)setObject:(id)inObject forKey:(id)key  {
    if (!inObject) {
        return;
    }
    
    if (!key) {
        return;
    }
    
    if (![[self.keychainItemData objectForKey:key] isEqual:inObject]) {
        [self.keychainItemData setObject:inObject forKey:key];
        [self writeToKeychain];
    }
}

- (id)objectForKey:(id)key {			
    return [self.keychainItemData objectForKey:key];
}

- (void)resetKeychainItem {
	OSStatus junk = noErr;
    if (!self.keychainItemData) {
        self.keychainItemData = [NSMutableDictionary dictionary];
    } else {
        NSMutableDictionary *tempDictionary = [self dictionaryToSecItemFormat:self.keychainItemData];
		junk = SecItemDelete((CFDictionaryRef)tempDictionary);
        NSAssert(junk == noErr || junk == errSecItemNotFound, @"Problem deleting current dictionary.");
    }

    [self.keychainItemData setObject:@"" forKey:(id)kSecAttrAccount];
    [self.keychainItemData setObject:@"" forKey:(id)kSecAttrLabel];
    [self.keychainItemData setObject:@"" forKey:(id)kSecAttrDescription];
    [self.keychainItemData setObject:@"" forKey:(id)kSecValueData];
}

- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert {
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    [returnDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    [returnDictionary setObject:[[dictionaryToConvert objectForKey:(id)kSecValueData]dataUsingEncoding:NSUTF8StringEncoding] forKey:(id)kSecValueData];
    return returnDictionary;
}

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert {
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    [returnDictionary setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [returnDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];

    NSData *passwordData = nil;
    if (SecItemCopyMatching((CFDictionaryRef)returnDictionary, (CFTypeRef *)&passwordData) == noErr) {
        [returnDictionary removeObjectForKey:(id)kSecReturnData];
        NSString *password = [[NSString alloc]initWithBytes:passwordData.bytes length:passwordData.length encoding:NSUTF8StringEncoding];
        [returnDictionary setObject:password forKey:(id)kSecValueData];
        [password release];
    }
    
    [passwordData release];
   
	return returnDictionary;
}

- (void)writeToKeychain {
    NSDictionary *attributes = nil;
    NSMutableDictionary *updateItem = nil;
    
    if (SecItemCopyMatching((CFDictionaryRef)self.genericPasswordQuery, (CFTypeRef *)&attributes) == noErr) {
        updateItem = [NSMutableDictionary dictionaryWithDictionary:attributes];
        [updateItem setObject:[self.genericPasswordQuery objectForKey:(id)kSecClass] forKey:(id)kSecClass];
        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:self.keychainItemData];
        [tempCheck removeObjectForKey:(id)kSecClass];
        SecItemUpdate((CFDictionaryRef)updateItem, (CFDictionaryRef)tempCheck);
    } else {
        SecItemAdd((CFDictionaryRef)[self dictionaryToSecItemFormat:self.keychainItemData], nil);
    }
}

- (void)dealloc {
    [self setKeychainItemData:nil];
    [self setGenericPasswordQuery:nil];
	[super dealloc];
}

@end
