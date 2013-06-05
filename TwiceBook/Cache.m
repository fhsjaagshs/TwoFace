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
    
}

- (void)cache {
    
}

+ (NSString *)tweetCachePath {
    return [[Settings cachesDirectory]stringByAppendingPathComponent:@"cached_tweets.plist"];
}

+ (NSMutableArray *)tweetCache {
    return [NSMutableArray arrayWithContentsOfFile:[Cache tweetCachePath]];
}

+ (NSMutableArray *)cachedTimeline {
    NSString *cacheLocation = [[Settings cachesDirectory]stringByAppendingPathComponent:@"cachedTimeline.plist"];
    NSMutableArray *cachedTimeline = [NSMutableArray arrayWithContentsOfFile:cacheLocation];
    
    if ([[cachedTimeline firstObjectA]isKindOfClass:[NSDictionary class]]) {
        for (NSString *file in [[NSFileManager defaultManager]contentsOfDirectoryAtPath:[Settings cachesDirectory] error:nil]) {
            [[NSFileManager defaultManager]removeItemAtPath:[[Settings cachesDirectory]stringByAppendingPathComponent:file] error:nil];
        }
    }
    
    return cachedTimeline;
}

+ (void)cacheTimeline:(NSMutableArray *)timeline {
    
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            //NSMutableArray *timeline = [_viewController.timeline mutableCopy];
            if ([timeline containsObject:@"Loading..."]) {
                [timeline removeObject:@"Loading..."];
            }
            
            if ([timeline containsObject:@"Please log in"]) {
                [timeline removeObject:@"Please log in"];
            }
            
            if ([timeline containsObject:@"No Users Selected"]) {
                [timeline removeObject:@"No Users Selected"];
            }
            
            if (timeline.count > 0) {
                NSString *cacheLocation = [[Settings cachesDirectory]stringByAppendingPathComponent:@"cachedTimeline.plist"];
                [timeline writeToFile:cacheLocation atomically:YES];
            }
        }
    });
}

- (void)cacheFetchedUsernames {
    NSString *cacheLocation = [[Settings cachesDirectory]stringByAppendingPathComponent:@"cachedFetchedTwitterUsernames.plist"];
    [_theFetchedUsernames writeToFile:cacheLocation atomically:YES];
}

- (NSMutableArray *)cachedFetchedUsernames {
    NSString *cacheLocation = [[Settings cachesDirectory]stringByAppendingPathComponent:@"cachedFetchedTwitterUsernames.plist"];
    return [NSMutableArray arrayWithContentsOfFile:cacheLocation];
}

- (void)cacheFetchedFacebookFriends {
    NSString *cacheLocation = [[Settings cachesDirectory]stringByAppendingPathComponent:@"cachedFetchedFacebookFriends.plist"];
    [_facebookFriendsDict writeToFile:cacheLocation atomically:YES];
}

- (NSMutableDictionary *)getCachedFetchedFacebookFriends {
    NSString *cacheLocation = [[Settings cachesDirectory]stringByAppendingPathComponent:@"cachedFetchedFacebookFriends.plist"];
    return [NSMutableDictionary dictionaryWithContentsOfFile:cacheLocation];
}

+ (UIImage *)loadImageFromCache:(NSString *)imageName {
    
    if (imageName.length == 0) {
        return nil;
    }
    
    imageName = [[[imageName pathComponents]objectAtIndex:0]stringByAppendingPathExtension:@"png"];
}

- (void)clearImageCache {
    [[NSUserDefaults standardUserDefaults]setDouble:[[NSDate date]timeIntervalSince1970] forKey:@"previousClearTime"];
    NSArray *cachedFiles = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:[Settings cachesDirectory] error:nil];
    
    for (NSString *filename in cachedFiles) {
        if (![filename.pathExtension isEqualToString:@"plist"]) {
            NSString *file = [[Settings cachesDirectory]stringByAppendingPathComponent:filename];
            [[NSFileManager defaultManager]removeItemAtPath:file error:nil];
        }
    }
}

@end
