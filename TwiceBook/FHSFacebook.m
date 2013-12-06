//
//  FHSFacebook.m
//  TwoFace
//
//  Created by Nathaniel Symer on 12/5/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "FHSFacebook.h"

static NSString *kStringBoundary = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";

@interface FHSFacebook ()

@property (nonatomic, assign) BOOL isExtendingAccessToken;

@end

@implementation FHSFacebook

+ (FHSFacebook *)shared {
    static FHSFacebook *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[FHSFacebook alloc]init];
    });
    return shared;
}

- (BOOL)isSessionValid {
    return (_accessToken != nil && _expirationDate != nil && NSOrderedDescending == [_expirationDate compare:[NSDate date]]);
}

- (void)invalidateSession {
    self.accessToken = nil;
    self.expirationDate = nil;
    
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *facebookCookies = [cookies cookiesForURL:[NSURL URLWithString:@"http://login.facebook.com"]];
    
    for (NSHTTPCookie *cookie in facebookCookies) {
        [cookies deleteCookie:cookie];
    }
}

- (NSMutableURLRequest *)generateRequestWithURL:(NSString *)baseURL params:(NSMutableDictionary *)params HTTPMethod:(NSString *)httpMethod {
    NSString *url = [[self class]serializeURL:baseURL params:params httpMethod:@"GET"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:httpMethod];
    
    if ([httpMethod isEqualToString: @"POST"]) {
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",kStringBoundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[self generatePostBody:params]];
    }
    
    [params setValue:@"json" forKey:@"format"];
    [params setValue:@"ios" forKey:@"sdk"];
    [params setValue:@"2" forKey:@"sdk_version"];
    if ([self isSessionValid]) {
        [params setValue:_accessToken forKey:@"access_token"];
    }
    
    [self extendAccessTokenIfNeeded];
    
    return request;
}

- (NSString *)baseURL {
    return [NSString stringWithFormat:@"fb%@://authorize",_appID];
}

- (void)authorizeWithPermissions:(NSArray *)permissions {
    
    NSMutableDictionary *params = @{@"client_id": @"",
                                    @"type": @"user_agent",
                                    @"redirect_uri": @"fbconnect://success",
                                    @"display": @"touch",
                                    @"sdk": @"ios"
                                    }.mutableCopy;

    if (permissions != nil) {
        NSString *scope = [permissions componentsJoinedByString:@","];
        [params setValue:scope forKey:@"scope"];
    }

    NSString *fbAppUrl = [[self class]serializeURL:@"fbauth://authorize" params:params httpMethod:@"GET"];
    BOOL didOpenOtherApp = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
    
    if (!didOpenOtherApp) {
        NSString *nextUrl = [self baseURL];
        [params setValue:nextUrl forKey:@"redirect_uri"];
        NSString *fbAppUrl = [[self class]serializeURL:@"https://m.facebook.com/dialog/oauth" params:params httpMethod:@"GET"];
        didOpenOtherApp = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
    }
}

- (BOOL)handleOpenURL:(NSURL *)url {
    if (![url.absoluteString hasPrefix:[self baseURL]]) {
        return NO;
    }
    
    NSString *query = url.fragment;

    if (!query) { // support v3.2.3 of the Facebook app
        query = url.query;
    }
    
    NSDictionary *params = [self parseURLParams:query];
    
    NSString *accessToken = params[@"access_token"];
    
    if (accessToken.length == 0) {
        if ([_delegate respondsToSelector:@selector(facebookDidNotLogin:)]) {
            NSString *errorReason = params[@"error"];
            [_delegate facebookDidNotLogin:!params[@"error_code"] && (errorReason.length == 0 || [errorReason isEqualToString:@"access_denied"])];
        }
        return YES;
    }
    
    NSString *expTime = params[@"expires_in"];
    NSDate *expirationDate = [NSDate distantFuture];
    if (expTime.length > 0) {
        int expVal = expTime.intValue;
        if (expVal != 0) {
            expirationDate = [NSDate dateWithTimeIntervalSinceNow:expVal];
        }
    }
    
    self.accessToken = accessToken;
    self.expirationDate = expirationDate;
    self.tokenDate = [NSDate date];
    
    if ([_delegate respondsToSelector:@selector(facebookDidLogin)]) {
        [_delegate facebookDidLogin];
    }
    
    return YES;
}

- (NSDictionary *)parseURLParams:(NSString *)query {
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val = [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		params[kv[0]] = val;
	}
    return params;
}

- (void)extendAccessTokenIfNeeded {
    
    if (_isExtendingAccessToken) {
        return;
    }
    
    BOOL shouldExtend = NO;
    
    if ([self isSessionValid]) {
        NSCalendar *calendar = [[NSCalendar alloc]initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [calendar components:NSHourCalendarUnit fromDate:_tokenDate toDate:[NSDate date] options:0];
        
        if (components.hour >= 24) {
            shouldExtend = YES;
        }
    }

    if (shouldExtend) {
        self.isExtendingAccessToken = YES;
        
        NSString * fullURL = @"https://api.facebook.com/method/auth.extendSSOAccessToken";
        
        NSMutableDictionary *params = @{@"format": @"json", @"sdk": @"ios", @"sdk_version": @"2"}.mutableCopy;
        
        if ([self isSessionValid]) {
            [params setValue:_accessToken forKey:@"access_token"];
        }
        
        NSString *url = [[self class]serializeURL:fullURL params:params httpMethod:@"GET"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0f];
        [request setHTTPMethod:@"GET"];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            self.isExtendingAccessToken = NO;
        }];
    }
}

+ (NSString *)serializeURL:(NSString *)baseUrl params:(NSDictionary *)params httpMethod:(NSString *)httpMethod {
    NSURL *parsedURL = [NSURL URLWithString:baseUrl];
    NSString *queryPrefix = parsedURL.query?@"&":@"?";
    
    NSMutableArray *pairs = [NSMutableArray array];
    
    for (NSString *key in [params keyEnumerator]) {
        if ([httpMethod isEqualToString:@"GET"]) {
            if ([params[key]isKindOfClass:[UIImage class]] || [params[key]isKindOfClass:[NSData class]]) {
                NSLog(@"can not use GET to upload a file");
                continue;
            }
        }

        NSString *escaped_value = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(nil, (CFStringRef)params[key], nil,(CFStringRef)@"!*'();:@&=+$,/?%#[]",kCFStringEncodingUTF8));
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
    }
    
    return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, [pairs componentsJoinedByString:@"&"]];
}

- (NSMutableData *)generatePostBody:(NSMutableDictionary *)params {
    NSMutableData *body = [NSMutableData data];
    NSData *endLine = [[NSString stringWithFormat:@"\r\n--%@\r\n", kStringBoundary]dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", kStringBoundary]dataUsingEncoding:NSUTF8StringEncoding]];
    
    for (id key in params.keyEnumerator) {
        
        if ([params[key]isKindOfClass:[UIImage class]] || [params[key]isKindOfClass:[NSData class]]) {
            dataDictionary[key] = params[key];
            continue;
        }
        
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key]dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[params[key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:endLine];
    }
    
    if (dataDictionary.count > 0) {
        for (id key in dataDictionary) {
            NSObject *dataParam = dataDictionary[key];
            if ([dataParam isKindOfClass:[UIImage class]]) {
                NSData *imageData = UIImagePNGRepresentation((UIImage *)dataParam);
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; filename=\"%@\"\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:imageData];
            } else {
                NSAssert([dataParam isKindOfClass:[NSData class]], @"dataParam must be a UIImage or NSData");
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; filename=\"%@\"\r\n", key]dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[@"Content-Type: content/unknown\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:(NSData *)dataParam];
            }
            [body appendData:endLine];
        }
    }
    return body;
}

@end
