//
//  FacebookUser.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "FacebookUser.h"

@implementation FacebookUser

- (NSString *)description {
    return [[self dictionaryValue]description];
}

- (NSDictionary *)dictionaryValue {
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:_identifier?_identifier:@"", _name?_name:@"", _profileURL?_profileURL:@"", _username?_username:@"", _bio?_bio:@"", _profilePictureURL?_profilePictureURL:@"", _website?_website:@"", nil] forKeys:[NSArray arrayWithObjects:@"id", @"name", @"link", @"username", @"bio", @"picture", @"website", nil]];
}

- (void)parseDictionary:(NSDictionary *)dict {
    self.identifier = [dict objectForKey:@"id"];
    self.name = [dict objectForKey:@"name"];
    self.profileURL = [dict objectForKey:@"link"];
    self.username = [dict objectForKey:@"username"];
    self.bio = [dict objectForKey:@"bio"];
    self.profilePictureURL = [dict objectForKey:@"picture"];
    self.website = [dict objectForKey:@"website"];
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        [self parseDictionary:dictionary];
    }
    return self;
}

+ (id)facebookUserWithDictionary:(NSDictionary *)dict {
    return [[[self class]alloc]initWithDictionary:dict];
}

@end
