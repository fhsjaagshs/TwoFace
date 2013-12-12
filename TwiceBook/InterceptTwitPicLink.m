//
//  InterceptTwitPicLink.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/3/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "InterceptTwitPicLink.h"

@implementation InterceptTwitPicLink

- (BOOL)openURLWithoutHandling:(NSURL *)url; {
    return [super openURL:url];
}

- (BOOL)openURL:(NSURL *)url {
    NSString *urlString = url.absoluteString;
    
    if ([urlString containsString:@"twitpic.com/"]) {
        urlString = [NSString stringWithFormat:@"http://twitpic.com/show/large/%@.jpg",url.lastPathComponent];
        url = [NSURL URLWithString:urlString];
    }
    
    NSString *extension = url.pathExtension;
    
    if (extension.length >= 3) {
        extension = [extension substringToIndex:3];
    }

    if ([@[@"png", @"jpg", @"tif", @"jpe"] containsObject:extension]) {
        NSString *linkURL = [[urlString stringByReplacingOccurrencesOfString:@"http://" withString:@""]stringByReplacingOccurrencesOfString:@"https://" withString:@""];
        NSString *newURL = [Cache.shared getImageURLForLinkURL:linkURL];
        if (newURL.length > 0) {
            url = [NSURL URLWithString:newURL];
        }
        [[NSNotificationCenter defaultCenter]postNotificationName:@"imageOpen" object:url];
        return YES;
    } else {
        return [super openURL:url];
    }
}

@end
