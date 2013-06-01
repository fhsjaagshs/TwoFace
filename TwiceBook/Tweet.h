//
//  Tweet.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tweet : NSObject

@property (nonatomic, strong) NSString *identifier; // id_str
@property (nonatomic, strong) NSDate *createdAt; // created_at
@property (nonatomic, strong) NSString *inReplyToUserIdentifier; // in_reply_to_user_id_str
@property (nonatomic, strong) NSString *inReplyToScreenName; // in_reply_to_screen_name
@property (nonatomic, strong) NSString *inReplyToTweetIdentifier; // in_reply_to_status_id_str && in_reply_to_status_id
@property (nonatomic, strong) NSString *text; // text

@property (nonatomic, strong) NSString *source; // source

@property (nonatomic, strong) TwitterUser *user; // user

@property (nonatomic, assign) BOOL isFavorited; // favorited
@property (nonatomic, assign) BOOL isRetweeted; // retweeted

@property (nonatomic, retain) NSMutableDictionary *replies;

- (id)initWithDictionary:(NSDictionary *)dictionary;
+ (Tweet *)tweetWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryValue;
- (void)addReply:(Tweet *)reply;

@end
