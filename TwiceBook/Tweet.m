//
//  Tweet.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Tweet.h"
#import "FHSTwitterEngine.h"

@implementation Tweet

- (NSString *)description {
    return [self dictionaryValue].description;
}

- (NSDictionary *)dictionizeReplies {
    NSMutableDictionary *replyDicts = [NSMutableDictionary dictionary];
    
    for (NSString *identifierKey in _replies.allKeys) {
        replyDicts[identifierKey] = [_replies[identifierKey] dictionaryValue];
    }
    
    return replyDicts;
}

- (NSDictionary *)dictionaryValue {
    return @{
             @"id_str": _identifier?_identifier:@"",
             @"created_at": [[[FHSTwitterEngine sharedEngine]dateFormatter]stringFromDate:_createdAt?_createdAt:[NSDate date]],
             @"text": _text?_text:@"",
             @"source": _source?_source:@"",
             @"in_reply_to_screen_name": _inReplyToScreenName?_inReplyToScreenName:@"",
             @"in_reply_to_user_id_str": _inReplyToUserIdentifier?_inReplyToUserIdentifier:@"",
             @"in_reply_to_status_id_str": _inReplyToTweetIdentifier?_inReplyToTweetIdentifier:@"",
             @"user": [_user dictionaryValue],
             @"favorited": _isFavorited?@"true":@"false",
             @"retweeted": _isRetweeted?@"true":@"false",
             @"replies": [self dictionizeReplies],
             @"retweeted_by": [_retweetedBy dictionaryValue],
             @"snn": @"twitter"
             };
}

- (void)addReply:(Tweet *)reply {
    _replies[reply.identifier] = reply;
}

- (void)parseDictionary:(NSDictionary *)dictionary {
    self.identifier = dictionary[@"id_str"];
    self.text = dictionary[@"text"];
    self.source = dictionary[@"source"];
    self.inReplyToScreenName = dictionary[@"in_reply_to_screen_name"];
    self.inReplyToUserIdentifier = dictionary[@"in_reply_to_user_id_str"];
    self.inReplyToTweetIdentifier = dictionary[@"in_reply_to_status_id_str"];
    
    id created_at = dictionary[@"created_at"];
    
    if ([created_at isKindOfClass:[NSString class]]) {
        self.createdAt = [[[FHSTwitterEngine sharedEngine]dateFormatter]dateFromString:created_at];
    } else if ([created_at isKindOfClass:[NSDate class]]) {
        self.createdAt = (NSDate *)created_at;
    }
    
    if (_inReplyToTweetIdentifier.length == 0) {
        self.inReplyToTweetIdentifier = [NSString stringWithFormat:@"%@",dictionary[@"in_reply_to_status_id"]];
    }
    
    self.isFavorited = [dictionary[@"favorited"] boolValue];
    self.isRetweeted = [dictionary[@"retweeted"] boolValue];
    
    self.user = [TwitterUser twitterUserWithDictionary:dictionary[@"user"]];
    
    self.replies = dictionary[@"replies"];
    
    if (_replies == nil) {
        self.replies = [NSMutableDictionary dictionary];
    }
    
    self.retweetedBy = [TwitterUser twitterUserWithDictionary:dictionary[@"retweeted_by"]];
    
    NSMutableDictionary *entities = dictionary[@"entities"];
    NSMutableDictionary *rt_status = dictionary[@"retweeted_status"];
    
    if (rt_status.allKeys.count > 0) {
        NSString *retweetedUsername = rt_status[@"user"][@"screen_name"];
        NSString *retweetedText = rt_status[@"text"];
        
        if ([[_text substringToIndex:2]isEqualToString:@"RT"]) {
            if (oneIsCorrect(retweetedUsername.length > 0, retweetedText.length > 0)) {
                NSMutableDictionary *newEntities = dictionary[@"retweeted_status"][@"entities"];
                if (newEntities.allKeys.count > 0) {
                    [rt_status removeObjectForKey:@"in_reply_to_screen_name"];
                    [rt_status removeObjectForKey:@"in_reply_to_user_id_str"];
                    [rt_status removeObjectForKey:@"in_reply_to_status_id_str"];
                    rt_status[@"retweeted_by"] = [_user dictionaryValue];
                    [self parseDictionary:rt_status];
                    return;
                }
            }
        }
    }
    
    if (entities.allKeys.count > 0) {
        for (NSMutableDictionary *mediadict in entities[@"media"]) {
            
            NSString *picTwitterComLink = mediadict[@"display_url"];
            NSString *picTwitterURLtoReplace = mediadict[@"url"];
            NSString *picTwitterComImageLink = mediadict[@"media_url"];
            
            BOOL hasTwitPicLink = (picTwitterComImageLink.length > 0);
            
            if (hasTwitPicLink) {
                picTwitterComLink = [picTwitterComLink stringByReplacingOccurrencesOfString:@"http://" withString:@""];
                self.text = [_text stringByReplacingOccurrencesOfString:picTwitterURLtoReplace withString:picTwitterComLink];
                Cache.sharedCache.pictwitterURLs[picTwitterComLink] = picTwitterComImageLink;
            }
        }
        
        NSArray *urlEntities = entities[@"urls"];
        
        if (urlEntities.count > 0) {
            for (NSDictionary *entity in urlEntities) {
                NSString *shortenedURL = entity[@"url"];
                NSString *fullURL = entity[@"expanded_url"];
                
                NSString *dotWhatever = [[[[[fullURL stringByReplacingOccurrencesOfString:@"://" withString:@""]componentsSeparatedByString:@"/"]firstObject]componentsSeparatedByString:@"."]lastObject];
                
                if ([@[@"com",@"net",@"gov",@"us",@"me",@"org",@"edu"] containsObject:dotWhatever]) {
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
