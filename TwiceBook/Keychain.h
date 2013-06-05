//
//  Keychain.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/5/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Keychain : NSObject

+ (Keychain *)sharedKeychain;
- (void)setIdentifier:(NSString *)identifier;
- (void)setObject:(id)inObject forKey:(id)key;
- (id)objectForKey:(id)key;
- (void)reset;

@end
