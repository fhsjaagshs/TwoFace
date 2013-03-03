//
//  SDCloudUserDefaults.m
//
//  Created by Stephen Darlington on 01/09/2011.
//  Copyright (c) 2011 Wandle Software Limited. All rights reserved.
//

#import "SDCloudUserDefaults.h"

@implementation SDCloudUserDefaults

+ (void)removeAllObjects {
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    for (id key in store.dictionaryRepresentation.allKeys) {
        [store removeObjectForKey:key];
    }
}

+(NSString*)stringForKey:(NSString*)aKey {
    return [SDCloudUserDefaults objectForKey:aKey];
}

+(BOOL)boolForKey:(NSString*)aKey {
    return [[SDCloudUserDefaults objectForKey:aKey] boolValue];
}

+(id)objectForKey:(NSString*)aKey {
    NSUbiquitousKeyValueStore* cloud = [NSUbiquitousKeyValueStore defaultStore];
    id retv = [cloud objectForKey:aKey];
    return retv;
}

+(void)setString:(NSString*)aString forKey:(NSString*)aKey {
    [SDCloudUserDefaults setObject:aString forKey:aKey];
}

+(void)setBool:(BOOL)aBool forKey:(NSString*)aKey {
    [SDCloudUserDefaults setObject:[NSNumber numberWithBool:aBool] forKey:aKey];
}

+(void)setObject:(id)anObject forKey:(NSString*)aKey {
    [[NSUbiquitousKeyValueStore defaultStore] setObject:anObject forKey:aKey];
}

+(void)removeObjectForKey:(NSString*)aKey {
    [[NSUbiquitousKeyValueStore defaultStore] removeObjectForKey:aKey];
}

+(void)synchronize {
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

+(void)registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserverForName:@"NSUbiquitousKeyValueStoreDidChangeExternallyNotification"
                                                      object:[NSUbiquitousKeyValueStore defaultStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification* notification) {
                                                      NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
                                                      NSUbiquitousKeyValueStore* cloud = [NSUbiquitousKeyValueStore defaultStore];
                                                      NSDictionary* changedKeys = [notification.userInfo objectForKey:@"NSUbiquitousKeyValueStoreChangedKeysKey"];
                                                      for (NSString* a in changedKeys) {
                                                          [defaults setObject:[cloud objectForKey:a] forKey:a];
                                                      }
                                                  }];

}

+(void)removeNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:[NSUbiquitousKeyValueStore defaultStore]];
}

@end
