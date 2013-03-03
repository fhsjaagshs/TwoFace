//
//  FHSTwitPicEngine.h
//  TwoFace
//
//  Created by Nathaniel Symer on 1/3/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FHSTwitPicEngine : NSObject

+ (id)uploadPictureToTwitPic:(NSData *)file withMessage:(NSString *)message withConsumer:(OAConsumer *)consumer accessToken:(OAToken *)accessToken andTwitPicAPIKey:(NSString *)twitPicAPIKey;

@end
