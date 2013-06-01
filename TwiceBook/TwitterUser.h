//
//  TwitterUser.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TwitterUser : NSObject

@property (nonatomic, strong) NSString *name; // name
@property (nonatomic, strong) NSString *userDescription; // description
@property (nonatomic, strong) NSString *identifier; // id_str
@property (nonatomic, strong) NSString *profileImageURL; // profile_image_url
@property (nonatomic, strong) NSString *profileBackgroundImageURL; // profile_background_image_url
@property (nonatomic, strong) NSString *location; // location
@property (nonatomic, strong) NSString *screename; // screen_name
@property (nonatomic, strong) NSString *url; // url

@property (nonatomic, assign) BOOL isFollowing; // following
@property (nonatomic, assign) BOOL isProtected; // protected

- (id)initWithDictionary:(NSDictionary *)dict;
+ (TwitterUser *)twitterUserWithDictionary:(NSDictionary *)dict;

@end
