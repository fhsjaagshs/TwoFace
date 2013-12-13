//
//  PostsClient.m
//  TwoFace
//
//  Created by Nathaniel Symer on 12/4/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "PostsClient.h"

@implementation PostsClient

+ (BOOL)loadPostsForIDs:(NSArray *)identifiers {
    
    if (identifiers.count == 0) {
        return YES;
    }
    
    NSMutableArray *reqs = [NSMutableArray array];

    for (NSString *identifier in identifiers) {
        NSString *req = [NSString stringWithFormat:@"{\"method\":\"GET\",\"relative_url\":\"%@/feed?&date_format=U&limit=25\"}",identifier];
        [reqs addObject:req];
    }
    
    NSString *reqString = [NSString stringWithFormat:@"[%@]",[reqs componentsJoinedByString:@","]];
    
    NSString *string = [NSString stringWithFormat:@"https://graph.facebook.com/?batch=%@&access_token=%@",reqString.fhs_URLEncode,FHSFacebook.shared.accessToken];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:string]];
    [req setHTTPMethod:@"POST"];
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
    
    if (error) {
        return NO;
    }
    
    NSArray *result = removeNull([NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);

    BOOL returnValue = YES;
    for (NSDictionary *dictionary in result) {
        NSMutableArray *data = ((NSDictionary *)removeNull([NSJSONSerialization JSONObjectWithData:[dictionary[@"body"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil]))[@"data"];
        NSMutableArray *parsedPosts = [NSMutableArray array];
        
        for (NSMutableDictionary *post in data) {
            if (post[@"error"]) {
                returnValue = NO;
                continue;
            }
            
            NSMutableDictionary *minusComments = [post mutableCopy];
            [minusComments removeObjectForKey:@"comments"];
            
            Status *status = [Status statusWithDictionary:minusComments];
            
            if (!([(NSString *)post[@"story"]length] > 0 && [status.type isEqualToString:@"status"])) {
                BOOL shouldAddPost = YES;
                
                if (status.message.length == 0) {
                    if ([status.type isEqualToString:@"link"] && status.link.length == 0) {
                        shouldAddPost = NO;
                    } else if ([status.type isEqualToString:@"photo"] && status.objectIdentifier.length == 0) {
                        shouldAddPost = NO;
                    } else if ([status.type isEqualToString:@"status"]) {
                        shouldAddPost = NO;
                    }
                }
                
                if (shouldAddPost) {
                    [parsedPosts addObject:status];
                }
            }
        }
        [Cache.shared.timeline addObjectsFromArray:parsedPosts];
    }
    return returnValue;
}

+ (BOOL)loadTweetsForUsernames:(NSArray *)usernames {
    BOOL returnValue = YES;
    
    NSMutableArray *tweets = [NSMutableArray array];
    NSMutableArray *nonTimelineTweets = [[Cache shared]nonTimelineTweets];
    
    NSMutableArray *invalidUsers = [NSMutableArray array];
    
    for (NSString *username in usernames) {
        id fetched = [[FHSTwitterEngine sharedEngine]getTimelineForUser:username isID:NO count:3];
        
        if ([fetched isKindOfClass:[NSError class]]) {
            if ([(NSError *)fetched code] == 404) {
                [invalidUsers addObject:username];
            }
        } else if ([fetched isKindOfClass:[NSArray class]]) {
            for (NSDictionary *dict in fetched) {
                Tweet *tweet = [Tweet tweetWithDictionary:dict];
                
                if (!tweet.inReplyToTweetIdentifier.length == 0) {
                    
                    id retrievedTweet = nil;
                    
                    if (nonTimelineTweets.count > 0) {
                        for (Tweet *fromcache in nonTimelineTweets) {
                            if ([tweet.inReplyToTweetIdentifier isEqualToString:fromcache.inReplyToTweetIdentifier]) {
                                retrievedTweet = fromcache;
                                break;
                            }
                        }
                    }
                    
                    if (retrievedTweet == nil) {
                        retrievedTweet = [[FHSTwitterEngine sharedEngine]getDetailsForTweet:tweet.inReplyToTweetIdentifier];
                    }
                    
                    if ([retrievedTweet isKindOfClass:[NSDictionary class]]) {
                        Tweet *irt = [Tweet tweetWithDictionary:retrievedTweet];
                        [[[Cache shared]nonTimelineTweets]addObject:irt];
                        [tweets addObject:irt];
                    } else if ([retrievedTweet isKindOfClass:[Tweet class]]) {
                        [tweets addObject:retrievedTweet];
                    } else if ([retrievedTweet isKindOfClass:[NSError class]]) {
                        returnValue = NO;
                    }
                }
                
                [tweets addObject:tweet];
            }
        }
    }
    
    if (invalidUsers.count > 0) {
        NSMutableArray *selectedUsers = [Settings selectedTwitterUsernames];
        [selectedUsers removeObjectsInArray:invalidUsers];
        [[NSUserDefaults standardUserDefaults]setObject:selectedUsers forKey:kSelectedUsernamesListKey];
    }
    
    [[[Cache shared]timeline]addObjectsFromArray:[[NSSet setWithArray:tweets]allObjects]];
    return YES;
}

@end
