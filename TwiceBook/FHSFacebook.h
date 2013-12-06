//
//  FHSFacebook.h
//  TwoFace
//
//  Created by Nathaniel Symer on 12/5/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FHSFacebookDelegate;

@interface FHSFacebook : NSObject

+ (FHSFacebook *)shared;

- (void)authorizeWithPermissions:(NSArray *)permissions;

- (BOOL)isSessionValid;
- (void)invalidateSession;
- (BOOL)handleOpenURL:(NSURL *)url;
- (void)extendAccessTokenIfNeeded;

- (NSMutableURLRequest *)generateRequestWithURL:(NSString *)baseURL params:(NSMutableDictionary *)params HTTPMethod:(NSString *)httpMethod;

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSDate *expirationDate;
@property (nonatomic, strong) NSDate *tokenDate;
@property (nonatomic, strong) NSString *appID;

@property (nonatomic, weak) id<FHSFacebookDelegate> delegate;

@end

@protocol FHSFacebookDelegate <NSObject>

- (void)facebookDidLogin;
- (void)facebookDidNotLogin:(BOOL)cancelled;

@end