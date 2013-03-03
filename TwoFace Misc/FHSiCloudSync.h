//
//  FHSiCloudSync.h
//  TwoFace
//
//  Created by Nate Symer on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FHSiCloudSync : NSObject

+ (void)syncWithDelegate:(id)delegate;
+ (void)sync;

+ (void)syncTaskWithDelegate:(id)delegate;

+ (void)resetUbiquitousStore;

@end

@protocol FHSiCloudSyncDelegate <NSObject>

@optional 
- (void)syncingDidFinish;

@end