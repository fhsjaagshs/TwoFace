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
    return @{@"id": _identifier?_identifier:@"", @"name": _name?_name:@"", @"link": _profileURL?_profileURL:@"", @"username": _username?_username:@"", @"bio": _bio?_bio:@"", @"picture": _profilePictureURL?_profilePictureURL:@"", @"website": _website?_website:@""};
}

- (void)parseDictionary:(NSDictionary *)dict {
    
    if (dict == nil) {
        return;
    }
    
    self.identifier = dict[@"id"];
    self.name = dict[@"name"];
    self.profileURL = dict[@"link"];
    self.username = dict[@"username"];
    self.bio = dict[@"bio"];
    self.profilePictureURL = dict[@"picture"];
    self.website = dict[@"website"];
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
