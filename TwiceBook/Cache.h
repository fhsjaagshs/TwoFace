//
//  Cache.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/5/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Cache : NSObject

@property (nonatomic, strong) NSMutableDictionary *twitterFriends; // theFetchedUsernames
//@property (nonatomic, strong) NSMutableDictionary *facebookFriends; // facebookFriendsDict
@property (nonatomic, strong) NSMutableArray *timeline;
@property (nonatomic, strong) NSMutableArray *nonTimelineTweets;

- (void)cache;

- (void)sortTimeline;

+ (Cache *)shared;

+ (void)clearImageCache;
+ (UIImage *)imageFromCache:(NSString *)imageName;
+ (void)setImage:(UIImage *)image forName:(NSString *)name;

- (void)setImageURL:(NSString *)imageURL forLinkURL:(NSString *)linkURL;
- (NSString *)getImageURLForLinkURL:(NSString *)linkURL;

- (NSMutableDictionary *)facebookFriendsFromCache:(NSMutableArray **)array;
- (void)cacheFacebookDicts:(NSArray *)array;
- (NSString *)nameForFacebookID:(NSString *)uid;

@end
