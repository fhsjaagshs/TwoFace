//
//  InterceptTwitPicLinkViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 1/4/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "InterceptImageLinkViewController.h"

@implementation InterceptImageLinkViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(openURL:) name:@"imageOpen" object:nil];
    }
    return self;
}

- (void)openURL:(NSNotification *)notif {
    [self handleImageLink:notif.object];
}

- (void)handleImageLink:(NSString *)url {
    
}

@end
