//
//  InterceptTwitPicLink.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/3/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "InterceptImageLink.h"

@implementation InterceptImageLink

- (BOOL)openURLWithoutHandling:(NSURL *)url; {
    return [super openURL:url];
}

- (BOOL)openURL:(NSURL *)url {
    NSString *urlString = url.absoluteString;
    
    NSLog(@"%@: %@",urlString,[urlString testRegex:@"\\A.*pic\\.twitter\\.com.*\\z"]?@"YES":@"NO");
    
    if ([urlString testRegex:@"\\A.*twitpic\\.com.*\\z"]) {
        urlString = [NSString stringWithFormat:@"http://twitpic.com/show/large/%@.jpg",url.lastPathComponent];
        url = [NSURL URLWithString:urlString];
    } /*else if ([urlString testRegex:@"\\A.*pic\\.twitter\\.com.*\\z"]) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\Ahttp.*://pic\\.twitter\\.com/(\\w+)\\z" options:NSRegularExpressionCaseInsensitive error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:urlString options:0 range:NSMakeRange(0, urlString.length)];
        NSLog(@"Match: %@",match);
        NSString *imageCode = [urlString substringWithRange:[[regex firstMatchInString:urlString options:0 range:NSMakeRange(0, urlString.length)]rangeAtIndex:1]];

        urlString = [NSString stringWithFormat:@"https://p.twimg.com/%@.jpg:large",imageCode];
    }*/
    
    NSString *extension = url.pathExtension;
    
    if (extension.length >= 3) {
        extension = [extension substringToIndex:3];
    }

    if ([@[@"png", @"jpg", @"tif", @"jpe"] containsObject:extension]) {
        NSString *linkURL = [[urlString stringByReplacingOccurrencesOfString:@"http://" withString:@""]stringByReplacingOccurrencesOfString:@"https://" withString:@""];
        NSString *newURL = [Core.shared getImageURLForLinkURL:linkURL];
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
