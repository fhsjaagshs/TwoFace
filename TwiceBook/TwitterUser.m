//
//  TwitterUser.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "TwitterUser.h"

@implementation TwitterUser

- (void)parseDictionary:(NSDictionary *)dict {
    self.name = [dict objectForKey:@"name"];
    self.userDescription = [dict objectForKey:@"description"];
    self.identifier = [dict objectForKey:@"id_str"];
    self.profileImageURL = [dict objectForKey:@"profile_image_url"];
    self.profileBackgroundImageURL = [dict objectForKey:@"profile_background_image_url"];
    self.location = [dict objectForKey:@"location"];
    self.screename = [dict objectForKey:@"screen_name"];
    self.url = [dict objectForKey:@"url"];
    
    self.isFollowing = [[dict objectForKey:@"following"]boolValue];
    self.isProtected = [[dict objectForKey:@"protected"]boolValue];
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
