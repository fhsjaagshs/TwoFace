//
//  Cache.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/5/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Cache.h"

@interface Cache ()

@property (nonatomic, strong) FMDatabase *db;

@end

@implementation Cache

+ (Cache *)shared {
    static Cache *sharedCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[Cache alloc]init];
    });
    return sharedCache;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.db = [FMDatabase databaseWithPath:[Settings.cachesDirectory stringByAppendingPathComponent:@"caches.db"]];
        [_db executeUpdate:@"CREATE TABLE IF NOT EXISTS twitter_friends (username varchar(255), user_id varchar(255))"];
        [_db executeUpdate:@"CREATE TABLE IF NOT EXISTS facebook_friends (name varchar(255), last_name varchar(255), uid varchar(255))"];
        [_db executeUpdate:@"CREATE TABLE IF NOT EXISTS twitter_img_urls (link_url varchar(255), img_url varchar(255))"];
        [self loadCaches];
    }
    return self;
}

- (void)loadCaches {
    [_db open];

    //self.facebookFriends = [NSMutableDictionary dictionary];
    self.twitterFriends = [NSMutableDictionary dictionary];
    
    FMResultSet *tw = [_db executeQuery:@"SELECT * FROM twitter_usernames"];
    while ([tw next]) {
        _twitterFriends[[tw stringForColumn:@"user_id"]] = [tw stringForColumn:@"usernames"];
    }
    [tw close];
    
    /*FMResultSet *fb = [_db executeQuery:@"SELECT * FROM facebook_friends ORDER BY last_name"];
    while ([fb next]) {
        _facebookFriends[[fb stringForColumn:@"uid"]] = [fb stringForColumn:@"name"];
    }
    [fb close];*/

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
    NSString *cd = [Settings cachesDirectory];
   // [_facebookFriends writeToFile:[cd stringByAppendingPathComponent:@"fetchedFacebookFriends.plist"] atomically:YES];
    [_twitterFriends writeToFile:[cd stringByAppendingPathComponent:@"fetchedTwitterUsernames.plist"] atomically:YES];
  //  [_twitterIdToUsername writeToFile:[cd stringByAppendingPathComponent:@"twitter_username_lookup_dict.plist"] atomically:YES];
    
    NSMutableArray *timelineTemp = [NSMutableArray array];
    
    for (id obj in _timeline) {
        [timelineTemp addObject:[obj dictionaryValue]];
    }

    [timelineTemp writeToFile:[cd stringByAppendingPathComponent:@"timelinecache.plist"] atomically:YES];
    
    NSMutableArray *nonTimelineTweetsTemp = [NSMutableArray array];
    
    for (Tweet *tweet in _nonTimelineTweets) {
        [nonTimelineTweetsTemp addObject:tweet.dictionaryValue];
    }
    
    [nonTimelineTweetsTemp writeToFile:[cd stringByAppendingPathComponent:@"cached_context_tweets.plist"] atomically:YES];
}

- (void)cacheFacebookDicts:(NSArray *)array {
    [_db open];
    [_db executeUpdate:@"DELETE * FROM facebook_friends"];
    
    [_db beginTransaction];
    
    for (NSDictionary *dict in array) {
        [_db executeUpdate:@"INSERT into facebook_friends (name, last_name, uid) values(?,?,?)",dict[@"name"],dict[@"last_name"],dict[@"uid"]];
    }
    
    [_db commit];
}

- (void)setImageURL:(NSString *)imageURL forLinkURL:(NSString *)linkURL {
    [_db executeUpdate:@"INSERT or REPLACE INTO twitter_img_urls (img_url, link_url) VALUES(?,?)",imageURL,linkURL];
}

- (NSString *)getImageURLForLinkURL:(NSString *)linkURL {
    FMResultSet *s = [_db executeQuery:@"SELECT img_url FROM twitter_img_urls WHERE link_url=?",linkURL];
    if ([s next]) {
        return [s stringForColumn:@"img_url"];
    }
    return nil;
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
