//
//  Cache.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/5/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Cache.h"

@implementation Cache

+ (Cache *)sharedCache {
    static Cache *sharedCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[Cache alloc]init];
    });
    return sharedCache;
}

- (void)loadCaches {
    NSString *cd = [Settings cachesDirectory];
    self.twitterFriends = [NSMutableArray arrayWithContentsOfFile:[cd stringByAppendingPathComponent:@"fetchedTwitterUsernames.plist"]];
    self.facebookFriends = [NSMutableDictionary dictionaryWithContentsOfFile:[cd stringByAppendingPathComponent:@"fetchedFacebookFriends.plist"]];
    self.invalidUsers = [NSMutableArray arrayWithContentsOfFile:[cd stringByAppendingPathComponent:@"invalidUsers.plist"]];
    self.twitterIdToUsername = [NSMutableDictionary dictionaryWithContentsOfFile:[cd stringByAppendingPathComponent:@"twitter_username_lookup_dict.plist"]];
    self.pictwitterURLs = [NSMutableDictionary dictionaryWithContentsOfFile:[cd stringByAppendingPathComponent:@"picTwitter_to_image_url.plist"]];
    
    if (!_twitterFriends) {
        self.twitterFriends = [NSMutableArray array];
    }
    
    if (!_facebookFriends) {
        self.facebookFriends = [NSMutableDictionary dictionary];
    }
    
    if (!_invalidUsers) {
        self.invalidUsers = [NSMutableArray array];
    }
    
    if (!_twitterIdToUsername) {
        self.twitterIdToUsername = [NSMutableDictionary dictionary];
    }
    
    if (!_pictwitterURLs) {
        self.pictwitterURLs = [NSMutableDictionary dictionary];
    }
    
    self.timeline = [NSMutableArray array];
    
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
}

- (void)cache {
    NSString *cd = [Settings cachesDirectory];
    [_facebookFriends writeToFile:[cd stringByAppendingPathComponent:@"fetchedFacebookFriends.plist"] atomically:YES];
    [_twitterFriends writeToFile:[cd stringByAppendingPathComponent:@"fetchedTwitterUsernames.plist"] atomically:YES];
    [_invalidUsers writeToFile:[cd stringByAppendingPathComponent:@"invalidUsers.plist"] atomically:YES];
    [_twitterIdToUsername writeToFile:[cd stringByAppendingPathComponent:@"twitter_username_lookup_dict.plist"] atomically:YES];
    [_pictwitterURLs writeToFile:[cd stringByAppendingPathComponent:@"picTwitter_to_image_url.plist"] atomically:YES];
    
    NSMutableArray *timelineTemp = [NSMutableArray array];
    
    for (id obj in _timeline) {
        [timelineTemp addObject:[obj dictionaryValue]];
    }

    [timelineTemp writeToFile:[cd stringByAppendingPathComponent:@"timelinecache.plist"] atomically:YES];
    
    NSMutableArray *nonTimelineTweetsTemp = [NSMutableArray array];
    
    for (Tweet *tweet in _nonTimelineTweets) {
        [nonTimelineTweetsTemp addObject:[tweet dictionaryValue]];
    }
    
    [nonTimelineTweetsTemp writeToFile:[cd stringByAppendingPathComponent:@"cached_context_tweets.plist"] atomically:YES];
}

- (void)setImageURL:(NSString *)imageURL forLinkURL:(NSString *)linkURL {
    NSString *writeLocation = [[Settings cachesDirectory]stringByAppendingPathComponent:@"picTwitter_to_image_url.plist"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:writeLocation];
    
    if (dict.allKeys.count == 0) {
        dict = [NSMutableDictionary dictionary];
    }
    
    dict[linkURL] = imageURL;
    [dict writeToFile:writeLocation atomically:YES];
}

- (NSString *)getImageURLForLinkURL:(NSString *)linkURL {
    NSString *writeLocation = [[Settings cachesDirectory]stringByAppendingPathComponent:@"picTwitter_to_image_url.plist"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:writeLocation];
    return dict[linkURL];
}

+ (void)setImage:(UIImage *)image forName:(NSString *)name {
    
    if (!image) {
        return;
    }
    
    if (name.length == 0) {
        return;
    }
    
    name = [[name pathComponents][0]stringByAppendingPathExtension:@"png"];
    [UIImagePNGRepresentation(image) writeToFile:[[Settings cachesDirectory]stringByAppendingPathComponent:name] atomically:YES];
}

+ (UIImage *)imageFromCache:(NSString *)imageName {
    
    if (imageName.length == 0) {
        return nil;
    }
    
    imageName = [[imageName pathComponents][0]stringByAppendingPathExtension:@"png"];
    return [UIImage imageWithContentsOfFile:[[Settings cachesDirectory]stringByAppendingPathComponent:imageName]];
}

+ (void)clearImageCache {
    NSString *cachesDirectory = [Settings cachesDirectory];
    NSArray *cachedFiles = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:cachesDirectory error:nil];
    
    for (NSString *filename in cachedFiles) {
        if (![filename.pathExtension isEqualToString:@"plist"]) {
            NSString *file = [cachesDirectory stringByAppendingPathComponent:filename];
            [[NSFileManager defaultManager]removeItemAtPath:file error:nil];
        }
    }
}

- (void)sortTimeline {
    [_timeline sortUsingComparator:^NSComparisonResult(id one, id two) {
        float oneTime = [[one createdAt]timeIntervalSince1970];
        float twoTime = [[two createdAt]timeIntervalSince1970];
        
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
