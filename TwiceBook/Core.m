//
//  Cache.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/5/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Core.h"

@interface Core ()

@property (nonatomic, strong) FMDatabase *db;

@end

@implementation Core

+ (Core *)shared {
    static Core *sharedCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[Core alloc]init];
    });
    return sharedCache;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.db = [FMDatabase databaseWithPath:[Settings.cachesDirectory stringByAppendingPathComponent:@"caches.db"]];
    [_db open];
    [_db executeUpdate:@"CREATE TABLE IF NOT EXISTS twitter_friends (username varchar(255), user_id varchar(255))"];
    [_db executeUpdate:@"CREATE TABLE IF NOT EXISTS facebook_friends (name varchar(255), last_name varchar(255), uid varchar(255))"];
    [_db executeUpdate:@"CREATE TABLE IF NOT EXISTS twitter_img_urls (link_url varchar(255), img_url varchar(255))"];
    [_db close];
    
    self.timeline = [NSMutableArray array];
    
    NSString *cd = [Settings cachesDirectory];
    
    NSMutableArray *timelineTemp = [NSMutableArray arrayWithContentsOfFile:[cd stringByAppendingPathComponent:@"timelinecache.plist"]];
    
    for (NSDictionary *dict in timelineTemp) {
        if ([dict[@"snn"] isEqualToString:@"twitter"]) {
            [_timeline addObject:[Tweet tweetWithDictionary:dict]];
        } else {
            [_timeline addObject:[Status statusWithDictionary:dict]];
        }
    }
    
    NSArray *nonTimelineTweetsTemp = [NSArray arrayWithContentsOfFile:[cd stringByAppendingPathComponent:@"cached_context_tweets.plist"]];
    self.nonTimelineTweets = [NSMutableArray array];
    
    for (NSDictionary *dict in nonTimelineTweetsTemp) {
        [_nonTimelineTweets addObject:[Tweet tweetWithDictionary:dict]];
    }
    
    [_db close];
}

- (void)cache {
    NSMutableArray *timelineTemp = [NSMutableArray array];
    
    for (id obj in _timeline) {
        [timelineTemp addObject:[obj dictionaryValue]];
    }

    [timelineTemp writeToFile:[Settings.cachesDirectory stringByAppendingPathComponent:@"timelinecache.plist"] atomically:YES];
    
    NSMutableArray *nonTimelineTweetsTemp = [NSMutableArray array];
    
    for (Tweet *tweet in _nonTimelineTweets) {
        [nonTimelineTweetsTemp addObject:tweet.dictionaryValue];
    }
    
    [nonTimelineTweetsTemp writeToFile:[Settings.cachesDirectory stringByAppendingPathComponent:@"cached_context_tweets.plist"] atomically:YES];
}

- (NSMutableDictionary *)twitterFriendsFromCache {
    [_db open];
    
    FMResultSet *s = [_db executeQuery:@"SELECT * FROM twitter_friends ORDER BY username"];
    
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    
    while ([s next]) {
        NSString *uid = [s stringForColumn:@"user_id"];
        d[uid] = [s stringForColumn:@"username"];
    }
    
    [s close];
    [_db close];
    return d;
}

- (void)cacheTwitterFriendsDict:(NSMutableDictionary *)dict {
    [_db open];
    [_db executeUpdate:@"DELETE FROM twitter_friends"];
    
    if (dict.count > 0) {
        [_db beginTransaction];
        
        for (NSString *key in dict) {
            [_db executeUpdate:@"INSERT INTO twitter_friends (username, user_id) values(?,?)",dict[@"user_id"],key];
        }
        
        [_db commit];
    }
    
    [_db close];
}

- (NSMutableDictionary *)facebookFriendsFromCache:(NSMutableArray **)array {
    [_db open];
    
    FMResultSet *s = [_db executeQuery:@"SELECT * FROM facebook_friends ORDER BY last_name"];
    
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    
    while ([s next]) {
        NSString *uid = [s stringForColumn:@"uid"];
        d[uid] = [s stringForColumn:@"name"];
        [*array addObject:uid];
    }
    
    [s close];
    [_db close];
    return d;
}

- (void)cacheFacebookDicts:(NSArray *)array {
    [_db open];
    [_db executeUpdate:@"DELETE FROM facebook_friends"];
    
    if (array.count > 0) {
        [_db beginTransaction];
        
        for (NSDictionary *dict in array) {
            [_db executeUpdate:@"INSERT INTO facebook_friends (name, last_name, uid) values(?,?,?)",dict[@"name"],dict[@"last_name"],dict[@"uid"]];
        }
        
        [_db commit];
    }

    [_db close];
}

- (NSString *)nameForFacebookID:(NSString *)uid {
    [_db open];
    NSString *name = nil;
    
    FMResultSet *s = [_db executeQuery:@"SELECT name FROM facebook_Frieds WHERE uid=? LIMIT 1",uid];
    if ([s next]) {
        name = [s stringForColumn:@"name"];
    }
    [s close];
    [_db close];
    return name;
}

- (void)clearImageURLCache {
    [_db open];
    [_db executeUpdate:@"DELETE FROM twitter_img_urls"];
    [_db close];
}

- (void)setImageURL:(NSString *)imageURL forLinkURL:(NSString *)linkURL {
    [_db open];
    [_db executeUpdate:@"INSERT or REPLACE INTO twitter_img_urls (img_url, link_url) VALUES(?,?)",imageURL,linkURL];
    [_db close];
}

- (NSString *)getImageURLForLinkURL:(NSString *)linkURL {
    NSString *ret = nil;
    [_db open];
    FMResultSet *s = [_db executeQuery:@"SELECT img_url FROM twitter_img_urls WHERE link_url=?",linkURL];
    if ([s next]) {
        ret = [s stringForColumn:@"img_url"];
    }
    [s close];
    [_db close];
    return ret;
}

+ (void)setImage:(UIImage *)image forName:(NSString *)name {
    if (!image) {
        return;
    }
    
    if (name.length == 0) {
        return;
    }
    
    name = [name.pathComponents[0] stringByAppendingPathExtension:@"png"];
    [UIImagePNGRepresentation(image) writeToFile:[[[Settings cachesDirectory]stringByAppendingPathComponent:@"images"]stringByAppendingPathComponent:name] atomically:YES];
}

+ (UIImage *)imageFromCache:(NSString *)imageName {
    if (imageName.length == 0) {
        return nil;
    }
    
    imageName = [imageName.pathComponents[0] stringByAppendingPathExtension:@"png"];
    return [UIImage imageWithContentsOfFile:[[[Settings cachesDirectory]stringByAppendingPathComponent:@"images"]stringByAppendingPathComponent:imageName]];
}

+ (void)clearImageCache {
    NSString *cachesDirectory = [[Settings cachesDirectory]stringByAppendingPathComponent:@"images"];
    NSArray *cachedFiles = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:cachesDirectory error:nil];
    
    for (NSString *filename in cachedFiles) {
        NSString *file = [cachesDirectory stringByAppendingPathComponent:filename];
        [[NSFileManager defaultManager]removeItemAtPath:file error:nil];
    }
}

- (void)sortTimeline {
    [_timeline sortUsingComparator:^NSComparisonResult(id one, id two) {
        float oneTime = [one createdAt].timeIntervalSince1970;
        float twoTime = [two createdAt].timeIntervalSince1970;
        
        if (oneTime < twoTime) {
            return (NSComparisonResult)NSOrderedDescending;
        } else if (oneTime > twoTime) {
            return (NSComparisonResult)NSOrderedAscending;
        } else {
            return (NSComparisonResult)NSOrderedSame;
        }
    }];
}

@end
