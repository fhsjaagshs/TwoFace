//
//  DBSyncClient.h
//  TwoFace
//
//  Created by Nathaniel Symer on 12/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBSyncClient : NSObject

+ (void)resetDropboxSync;
+ (void)dropboxSync;

@end
