//
//  PostsClient.h
//  TwoFace
//
//  Created by Nathaniel Symer on 12/4/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PostsClient : NSObject

+ (BOOL)loadPostsForIDs:(NSArray *)identifiers;
+ (BOOL)loadTweetsForUsernames:(NSArray *)usernames;

@end
