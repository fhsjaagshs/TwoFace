//
//  Tweet.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Tweet.h"

@implementation Tweet

- (NSString *)description {
    return [self dictionaryValue].description;
}

- (NSDictionary *)dictionaryValue {
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:_identifier, _createdAt, _text, _source, _inReplyToScreenName, _inReplyToUserIdentifier, _inReplyToTweetIdentifier, [_user dictionaryValue], _isFavorited?@"true":@"false", _isRetweeted?@"true":@"false", nil] forKeys:[NSArray arrayWithObjects:@"id_str", @"created_at", @"text", @"source", @"in_reply_to_screen_name", @"in_reply_to_user_id_str", @"in_reply_to_status_id_str", @"favorited", @"retweeted", nil]];
}

- (void)parseDictionary:(NSDictionary *)dictionary {
    
    self.identifier = [dictionary objectForKey:@"id_str"];
    self.createdAt = [dictionary objectForKey:@"created_at"];
    self.text = [dictionary objectForKey:@"text"];
    self.source = [dictionary objectForKey:@"source"];
    self.inReplyToScreenName = [dictionary objectForKey:@"in_reply_to_screen_name"];
    self.inReplyToUserIdentifier = [dictionary objectForKey:@"in_reply_to_user_id_str"];
    self.inReplyToTweetIdentifier = [dictionary objectForKey:@"in_reply_to_status_id_str"];
    
    if (_inReplyToTweetIdentifier.length == 0) {
        self.inReplyToTweetIdentifier = [[dictionary objectForKey:@"in_reply_to_status_id"]stringValue];
    }
    
    self.isFavorited = [[dictionary objectForKey:@"favorited"]boolValue];
    self.isRetweeted = [[dictionary objectForKey:@"retweeted"]boolValue];
    
    self.user = [TwitterUser twitterUserWithDictionary:[dictionary objectForKey:@"user"]];
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        [self parseDictionary:dictionary];
    }
    return self;
}

+ (Tweet *)tweetWithDictionary:(NSDictionary *)dictionary {
    return [[[self class]alloc]initWithDictionary:dictionary];
}

@end
