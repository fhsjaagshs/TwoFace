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
    return [[self dictionaryValue]description];
}

- (NSDictionary *)dictionizeReplies {
    NSMutableDictionary *replyDicts = [NSMutableDictionary dictionary];
    
    for (NSString *identifierKey in _replies.allKeys) {
        [replyDicts setObject:[[_replies objectForKey:identifierKey]dictionaryValue] forKey:identifierKey];
    }
    
    return replyDicts;
}

- (NSDictionary *)dictionaryValue {
    NSArray *objects = [NSArray arrayWithObjects:_identifier?_identifier:@"",
                        _createdAt?_createdAt:[NSDate date],
                        _text?_text:@"",
                        _source?_source:@"",
                        _inReplyToScreenName?_inReplyToScreenName:@"",
                        _inReplyToUserIdentifier?_inReplyToUserIdentifier:@"",
                        _inReplyToTweetIdentifier?_inReplyToTweetIdentifier:@"",
                        [_user dictionaryValue],
                        _isFavorited?@"true":@"false",
                        _isRetweeted?@"true":@"false",
                        [self dictionizeReplies],
                        _retweetedBy?_retweetedBy:@""
                        , nil];
    
    NSArray *keys = [NSArray arrayWithObjects:@"id_str", @"created_at", @"text", @"source", @"in_reply_to_screen_name", @"in_reply_to_user_id_str", @"in_reply_to_status_id_str", @"user", @"favorited", @"retweeted", @"replies", @"retweeted_by", nil];
    
    NSLog(@"Objects: %d  keys: %d",objects.count, keys.count);
    
    return [NSDictionary dictionaryWithObjects:objects forKeys:keys];
}

- (void)addReply:(Tweet *)reply {
    [_replies setObject:reply forKey:reply.identifier];
}

- (void)parseDictionary:(NSDictionary *)dictionary {
    self.identifier = [dictionary objectForKey:@"id_str"];
    
    self.text = [dictionary objectForKey:@"text"];
    self.source = [dictionary objectForKey:@"source"];
    self.inReplyToScreenName = [dictionary objectForKey:@"in_reply_to_screen_name"];
    self.inReplyToUserIdentifier = [dictionary objectForKey:@"in_reply_to_user_id_str"];
    self.inReplyToTweetIdentifier = [dictionary objectForKey:@"in_reply_to_status_id_str"];
    
    id created_at = [dictionary objectForKey:@"created_at"];
    
    if ([created_at isKindOfClass:[NSString class]]) {
        self.createdAt = [[FHSTwitterEngine sharedEngine]getDateFromTwitterCreatedAt:created_at];
    } else if ([created_at isKindOfClass:[NSDate class]]) {
        self.createdAt = (NSDate *)created_at;
    }
    
    if (_inReplyToTweetIdentifier.length == 0) {
        self.inReplyToTweetIdentifier = [dictionary objectForKey:@"in_reply_to_status_id"];
    }
    
    self.isFavorited = [[dictionary objectForKey:@"favorited"]boolValue];
    self.isRetweeted = [[dictionary objectForKey:@"retweeted"]boolValue];
    
    self.user = [TwitterUser twitterUserWithDictionary:[dictionary objectForKey:@"user"]];
    
    self.replies = [dictionary objectForKey:@"replies"];
    
    if (_replies == nil) {
        self.replies = [NSMutableDictionary dictionary];
    }
    
    self.retweetedBy = [dictionary objectForKey:@"retweeted_by"];
    
    NSMutableDictionary *entities = [dictionary objectForKey:@"entities"];
    
    NSMutableDictionary *rt_status = [dictionary objectForKey:@"retweeted_status"];
    
    if (rt_status.allKeys.count > 0) {
        NSString *retweetedUsername = [[rt_status objectForKey:@"user"]objectForKey:@"screen_name"];
        NSString *retweetedText = [rt_status objectForKey:@"text"];
        
        if ([[_text substringToIndex:2]isEqualToString:@"RT"]) {
            if (oneIsCorrect(retweetedUsername.length > 0, retweetedText.length > 0)) {
                NSMutableDictionary *newEntities = [[dictionary objectForKey:@"retweeted_status"]objectForKey:@"entities"];
                if (newEntities.allKeys.count > 0) {
                    [rt_status removeObjectForKey:@"in_reply_to_screen_name"];
                    [rt_status removeObjectForKey:@"in_reply_to_user_id_str"];
                    [rt_status removeObjectForKey:@"in_reply_to_status_id_str"];
                    [rt_status setObject:_user forKey:@"retweeted_by"];
                    [self parseDictionary:rt_status];
                    return;
                }
            }
        }
    }
    
    if (entities.allKeys.count > 0) {
        for (NSMutableDictionary *mediadict in [entities objectForKey:@"media"]) {
            
            NSString *picTwitterComLink = [mediadict objectForKey:@"display_url"];
            NSString *picTwitterURLtoReplace = [mediadict objectForKey:@"url"];
            NSString *picTwitterComImageLink = [mediadict objectForKey:@"media_url"];
            
            BOOL hasTwitPicLink = (picTwitterComImageLink.length > 0);
            
            if (hasTwitPicLink) {
                picTwitterComLink = [picTwitterComLink stringByReplacingOccurrencesOfString:@"http://" withString:@""];
                self.text = [_text stringByReplacingOccurrencesOfString:picTwitterURLtoReplace withString:picTwitterComLink];
                [[[Cache sharedCache]pictwitterURLs]setObject:picTwitterComImageLink forKey:picTwitterComLink];
            }
        }
        
        NSArray *urlEntities = [entities objectForKey:@"urls"];
        
        if (urlEntities.count > 0) {
            for (NSDictionary *entity in urlEntities) {
                NSString *shortenedURL = [entity objectForKey:@"url"];
                NSString *fullURL = [entity objectForKey:@"expanded_url"];
                
                NSString *dotWhatever = [[[[[fullURL stringByReplacingOccurrencesOfString:@"://" withString:@""]componentsSeparatedByString:@"/"]firstObjectA]componentsSeparatedByString:@"."]lastObject];
                
                if (([dotWhatever isEqualToString:@"com"] || [dotWhatever isEqualToString:@"net"] || [dotWhatever isEqualToString:@"gov"] || [dotWhatever isEqualToString:@"us"] || [dotWhatever isEqualToString:@"me"] || [dotWhatever isEqualToString:@"org"] || [dotWhatever isEqualToString:@"edu"])) {
                    fullURL = [fullURL stringByReplacingOccurrencesOfString:@"http://" withString:@""];
                }
                
                self.text = [_text stringByReplacingOccurrencesOfString:shortenedURL withString:fullURL];
            }
        }
    }
    
    self.text = [[_text stringByRemovingHTMLEntities]stringByTrimmingWhitespace];
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
