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
    self.twitterFriends = [NSMutableArray arrayWithContentsOfFile:[cd stringByAppendingPathComponent:@"fetchedTwitterUsernames.plist"]];;
    self.facebookFriends = [NSMutableDictionary dictionaryWithContentsOfFile:[cd stringByAppendingPathComponent:@"fetchedFacebookFriends.plist"]];
    self.invalidUsers = [NSMutableArray arrayWithContentsOfFile:[cd stringByAppendingPathComponent:@"invalidUsers.plist"]];
    self.twitterIdToUsername = [NSMutableDictionary dictionaryWithContentsOfFile:[cd stringByAppendingPathComponent:@"twitter_username_lookup_dict.plist"]];
    
    self.timeline = [NSMutableArray array];
    NSMutableArray *timelineTemp = [NSMutableArray arrayWithContentsOfFile:[cd stringByAppendingPathComponent:@"timeline.plist"]];
    
    for (NSDictionary *dict in timelineTemp) {
        if ([dict objectForKey:@"id_str"]) {
            [_timeline addObject:[Tweet tweetWithDictionary:dict]];
        } else {
            [_timeline addObject:[Status statusWithDictionary:dict]];
        }
    }
    
    NSMutableArray *nonTimelineTweetsTemp = [NSMutableArray arrayWithContentsOfFile:[cd stringByAppendingPathComponent:@"cached_tweets.plist"]];
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
    
    NSMutableArray *timelineTemp = [NSMutableArray array];
    
    for (id obj in _timeline) {
        [timelineTemp addObject:[obj dictionaryValue]];
    }
    
    [timelineTemp writeToFile:[cd stringByAppendingPathComponent:@"timeline.plist"] atomically:YES];
    
    
    NSMutableArray *nonTimelineTweetsTemp = [NSMutableArray array];
    
    for (Tweet *tweet in _nonTimelineTweets) {
        [nonTimelineTweetsTemp addObject:[tweet dictionaryValue]];
    }
    
    [nonTimelineTweetsTemp writeToFile:[cd stringByAppendingPathComponent:@"cached_tweets.plist"] atomically:YES];
}

+ (void)setImage:(UIImage *)image forName:(NSString *)name {
    
    if (!image) {
        return;
    }
    
    if (name.length == 0) {
        return;
    }
    
    name = [[[name pathComponents]objectAtIndex:0]stringByAppendingPathExtension:@"png"];
    [UIImagePNGRepresentation(image) writeToFile:[[Settings cachesDirectory]stringByAppendingPathComponent:name] atomically:YES];
}

+ (UIImage *)imageFromCache:(NSString *)imageName {
    
    if (imageName.length == 0) {
        return nil;
    }
    
    imageName = [[[imageName pathComponents]objectAtIndex:0]stringByAppendingPathExtension:@"png"];
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

@end
