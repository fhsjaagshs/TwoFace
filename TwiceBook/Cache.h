//
//  Cache.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/5/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Cache : NSObject

@property (nonatomic, strong) NSMutableArray *twitterFriends; // theFetchedUsernames
@property (nonatomic, strong) NSMutableDictionary *facebookFriends; // facebookFriendsDict
@property (nonatomic, strong) NSMutableArray *timeline;

- (void)cache;
- (void)loadCaches;

+ (Cache *)sharedCache;

@end
