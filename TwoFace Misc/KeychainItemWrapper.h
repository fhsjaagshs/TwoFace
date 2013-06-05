//
//  KeychainItemWrapper.h
//  TwoFace
//
//  Created by Nathaniel Symer on 7/21/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KeychainItemWrapper : NSObject 

@property (nonatomic, retain) NSMutableDictionary *keychainItemData;
@property (nonatomic, retain) NSMutableDictionary *genericPasswordQuery;

- (id)initWithIdentifier:(NSString *)identifier accessGroup:(NSString *)accessGroup;
- (id)initWithIdentifier:(NSString *)identifier;
- (void)setObject:(id)inObject forKey:(id)key;
- (id)objectForKey:(id)key;

- (void)resetKeychainItem;

@end