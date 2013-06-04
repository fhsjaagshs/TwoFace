//
//  FacebookUser.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FacebookUser : NSObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *profileURL;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *bio;
@property (nonatomic, strong) NSString *profilePictureURL;
@property (nonatomic, strong) NSString *website;

- (id)initWithDictionary:(NSDictionary *)dictionary;
+ (id)facebookUserWithDictionary:(NSDictionary *)dict;

- (NSDictionary *)dictionaryValue;

@end
