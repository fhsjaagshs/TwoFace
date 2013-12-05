//
//  TwitterUser.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "TwitterUser.h"

@implementation TwitterUser

- (NSString *)description {
    return [[self dictionaryValue]description];
}

- (NSDictionary *)dictionaryValue {
    return @{@"name": _name?_name:@"",
             @"description": _userDescription?_userDescription:@"",
             @"id_str": _identifier?_identifier:@"",
             @"profile_image_url": _profileImageURL?_profileImageURL:@"",
             @"profile_background_image_url": _profileBackgroundImageURL?_profileBackgroundImageURL:@"",
             @"location": _location?_location:@"",
             @"screen_name": _screename?_screename:@"",
             @"url": _url?_url:@"",
             @"following": _isFollowing?@"true":@"false",
             @"protected": _isProtected?@"true":@"false"
             };
}

- (void)parseDictionary:(NSDictionary *)dict {
    
    if (dict.count == 0) {
        return;
    }
    
    self.name = dict[@"name"];
    self.userDescription = dict[@"description"];
    self.identifier = dict[@"id_str"];
    self.profileImageURL = dict[@"profile_image_url"];
    self.profileBackgroundImageURL = dict[@"profile_background_image_url"];
    self.location = dict[@"location"];
    self.screename = dict[@"screen_name"];
    self.url = dict[@"url"];
    
    self.isFollowing = [dict[@"following"] boolValue];
    self.isProtected = [dict[@"protected"] boolValue];
}

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        [self parseDictionary:dict];
    }
    return self;
}

+ (TwitterUser *)twitterUserWithDictionary:(NSDictionary *)dict {
    return [[[self class]alloc]initWithDictionary:dict];
}

@end
