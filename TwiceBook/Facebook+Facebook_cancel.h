//
//  Facebook+Facebook_cancel.h
//  TwoFace
//
//  Created by Nathaniel Symer on 8/15/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "Facebook.h"

@interface Facebook (Facebook_cancel)

- (void)cancelPendingRequest:(FBRequest *)releasingRequest shouldHideNetworkActivityIndicator:(BOOL)shouldHide;
- (void)cancelPendingRequest:(FBRequest *)releasingRequest;
- (void)cancelAllRequests;
- (BOOL)isPendingRequests;

@end
