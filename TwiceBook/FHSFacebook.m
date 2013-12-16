//
//  FHSFacebook.m
//  TwoFace
//
//  Created by Nathaniel Symer on 12/5/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "FHSFacebook.h"
#import "FacebookUser.h"

static NSString *kStringBoundary = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";

static NSString *kTokenKeychainKey = @"kTokenKeychainKey";
static NSString *kExprDateKeychainKey = @"kExprDateKeychainKey";
static NSString *kTokenDateKeychainKey = @"kTokenDateKeychainKey";
static NSString *kUserKeychainKey = @"kUserKeychianKey";

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

- (instancetype)init {
    self = [super init];
    if (self) {
        NSDictionary *tokenDict = [Keychain objectForKey:kFacebookAccessTokenKey];
        self.accessToken = tokenDict[kTokenKeychainKey];
        self.expirationDate = tokenDict[kExprDateKeychainKey];
        self.tokenDate = tokenDict[kTokenDateKeychainKey];
        self.user = [FacebookUser facebookUserWithDictionary:tokenDict[kUserKeychainKey]];
    }
    return self;
}

- (BOOL)isSessionValid {
    if (![_expirationDate isKindOfClass:[NSDate class]]) {
        return NO;
    }
    
    return (_accessToken != nil && _expirationDate != nil && NSOrderedDescending == [_expirationDate compare:[NSDate date]]);
}

- (void)invalidateSession {
    self.user = nil;
    self.accessToken = nil;
    self.expirationDate = nil;
    
    [Keychain removeObjectForKey:kFacebookAccessTokenKey];
    
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *facebookCookies = [cookies cookiesForURL:[NSURL URLWithString:@"http://login.facebook.com"]];
    
    for (NSHTTPCookie *cookie in facebookCookies) {
        [cookies deleteCookie:cookie];
    }
}

- (NSMutableURLRequest *)generateRequestWithURL:(NSString *)baseURL params:(NSDictionary *)paramsImmutable HTTPMethod:(NSString *)httpMethod {
    
    [self extendAccessTokenIfNeeded];
    
    NSMutableDictionary *params = paramsImmutable.mutableCopy;
    
    params[@"format"] = @"json";
    params[@"sdk"] = @"ios";
    params[@"sdk_version"] = @"2";
    params[@"app_id"] = _appID;
    
    if ([self isSessionValid]) {
        params[@"access_token"] = _accessToken;
    }
    
    NSString *url = [[self class]serializeURL:baseURL params:params httpMethod:@"GET"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:httpMethod];
    
    if ([httpMethod isEqualToString: @"POST"]) {
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",kStringBoundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[self generatePostBody:params]];
    }
    
    return request;
}

- (NSString *)baseURL {
    return [NSString stringWithFormat:@"fb%@://authorize",_appID];
}

- (void)authorizeWithPermissions:(NSArray *)permissions {

    NSMutableDictionary *params = @{@"client_id": _appID,
                                    @"type": @"user_agent",
                                    @"redirect_uri": @"fbconnect://success",
                                    @"display": @"touch",
                                    @"sdk": @"ios",
                                    @"app_id": _appID
                                    }.mutableCopy;

    if (permissions != nil) {
        params[@"scope"] = [permissions componentsJoinedByString:@","];
    }

    NSString *fbAppUrl = [[self class]serializeURL:@"fbauth://authorize" params:params httpMethod:@"GET"];

    if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]]) {
        params[@"redirect_uri"] = [self baseURL];
        fbAppUrl = [[self class]serializeURL:@"https://m.facebook.com/dialog/oauth" params:params httpMethod:@"GET"];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
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
            
            BOOL cancelled = !params[@"error_code"] && (errorReason.length == 0 || [errorReason isEqualToString:@"access_denied"]);
            
            if (!cancelled) {
                [Keychain removeObjectForKey:kFacebookAccessTokenKey];
            }
            
            [_delegate facebookDidNotLogin:cancelled];
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
    
    [Keychain setObject:@{ kTokenKeychainKey: _accessToken, kExprDateKeychainKey: _expirationDate, kTokenDateKeychainKey: _tokenDate } forKey:kFacebookAccessTokenKey];
    
    NSURL *userlookupURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@",_accessToken]];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:userlookupURL] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (!error) {
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            self.user = [FacebookUser facebookUserWithDictionary:responseDict];
            
            [Keychain setObject:@{ kTokenKeychainKey: _accessToken, kExprDateKeychainKey: _expirationDate, kTokenDateKeychainKey: _tokenDate, kUserKeychainKey: _user.dictionaryValue } forKey:kFacebookAccessTokenKey];
        }
        
        if ([_delegate respondsToSelector:@selector(facebookDidLogin)]) {
            [_delegate facebookDidLogin];
        }
    }];
    
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
            params[@"access_token"] = _accessToken;
        }
        
        NSString *url = [[self class]serializeURL:fullURL params:params httpMethod:@"GET"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0f];
        [request setHTTPMethod:@"GET"];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            
            self.isExtendingAccessToken = NO;
            
            if (!error) {
                NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                self.accessToken = responseDict[@"access_token"];
                self.expirationDate = responseDict[@"expires_at"];
                self.tokenDate = [NSDate date];
                
                [Keychain setObject:@{ kTokenKeychainKey: _accessToken, kExprDateKeychainKey: _expirationDate, kTokenDateKeychainKey: _tokenDate, kUserKeychainKey: _user.dictionaryValue } forKey:kFacebookAccessTokenKey];

                if ([_delegate respondsToSelector:@selector(facebookDidExtendAccessToken)]) {
                    [_delegate facebookDidExtendAccessToken];
                }
            }
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
