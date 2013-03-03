//
//  Facebook+Facebook_cancel.m
//  TwoFace
//
//  Created by Nathaniel Symer on 8/15/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "Facebook+Facebook_cancel.h"

@implementation Facebook (Facebook_cancel)

- (void)cancelPendingRequest:(FBRequest *)releasingRequest shouldHideNetworkActivityIndicator:(BOOL)shouldHide {
    if ([_requests containsObject:releasingRequest]) {
        [releasingRequest.connection cancel];
        [_requests removeObject:releasingRequest];
        [releasingRequest removeObserver:self forKeyPath:@"state"];
    }
    
    if (![self isPendingRequests]) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = !shouldHide;
    }
}

- (void)cancelPendingRequest:(FBRequest *)releasingRequest {
    [self cancelPendingRequest:releasingRequest shouldHideNetworkActivityIndicator:YES];
}

- (void)cancelAllRequests {
    for (FBRequest *req in [_requests mutableCopy]) {
        [_requests removeObject:req];
        [req.connection cancel];
        [req removeObserver:self forKeyPath:@"state"];
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (BOOL)isPendingRequests {
    if (_requests.count == 0) {
        return NO;
    }
    return YES;
}

@end
