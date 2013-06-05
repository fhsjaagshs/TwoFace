//
//  InterceptTwitPicLink.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/3/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "InterceptTwitPicLink.h"

@implementation InterceptTwitPicLink

@synthesize picTwitterLinks;

- (BOOL)openURLWithoutHandling:(NSURL *)url; {
    return [super openURL:url];
}

- (BOOL)openURL:(NSURL *)url {
    
    NSString *urlString = [NSString stringWithFormat:@"%@",url];
    
    if ([urlString containsString:@"twitpic.com/"]) {
        urlString = [NSString stringWithFormat:@"http://twitpic.com/show/large/%@.jpg",[url lastPathComponent]];
        url = [NSURL URLWithString:urlString];
    }
    
    NSString *extension = url.pathExtension;
    
    if (extension.length >= 3) {
        extension = [extension substringToIndex:3];
    }

    BOOL isImage = ([extension isEqualToString:@"png"] || [extension isEqualToString:@"jpg"] || [extension isEqualToString:@"tif"] || [extension isEqualToString:@"jpe"] || [urlString containsString:@"pic.twitter.com/"]);
    
    if (isImage) {
        NSString *newURL = [[Settings appDelegate]getImageURLForLinkURL:[[urlString stringByReplacingOccurrencesOfString:@"http://" withString:@""]stringByReplacingOccurrencesOfString:@"https://" withString:@""]];
        
        if (!(newURL.length == 0 || newURL == nil)) {
            urlString = newURL;
            url = [NSURL URLWithString:urlString];
        }
        [[NSNotificationCenter defaultCenter]postNotificationName:@"imageOpen" object:url];
        return YES;
    } else {
        return [super openURL:url];
    }
}

@end
