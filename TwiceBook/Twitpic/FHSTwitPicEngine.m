//
//  FHSTwitPicEngine.m
//  TwoFace
//
//  Created by Nathaniel Symer on 1/3/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "FHSTwitPicEngine.h"
#import "OAuthConsumer.h"
#import <CommonCrypto/CommonHMAC.h>
#include "Base64TranscoderFHS.h"

id removeNullTwit(id rootObject) {
    if ([rootObject isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *sanitizedDictionary = [NSMutableDictionary dictionaryWithDictionary:rootObject];
        [rootObject enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            id sanitized = removeNull(obj);
            if (!sanitized) {
                [sanitizedDictionary setObject:@"" forKey:key];
            } else {
                [sanitizedDictionary setObject:sanitized forKey:key];
            }
        }];
        return [NSMutableDictionary dictionaryWithDictionary:sanitizedDictionary];
    }
    
    if ([rootObject isKindOfClass:[NSArray class]]) {
        NSMutableArray *sanitizedArray = [NSMutableArray arrayWithArray:rootObject];
        [rootObject enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            id sanitized = removeNull(obj);
            if (!sanitized) {
                [sanitizedArray replaceObjectAtIndex:[sanitizedArray indexOfObject:obj] withObject:@""];
            } else {
                [sanitizedArray replaceObjectAtIndex:[sanitizedArray indexOfObject:obj] withObject:sanitized];
            }
        }];
        return [NSMutableArray arrayWithArray:sanitizedArray];
    }
    
    if ([rootObject isKindOfClass:[NSNull class]]) {
        return (id)nil;
    } else {
        return rootObject;
    }
}

NSString * urlencode(NSString *urlString) {
    CFStringRef url = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)urlString, nil, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
    NSString *result = (__bridge NSString *)url;
	return result;
}

@implementation FHSTwitPicEngine

+ (id)uploadPictureToTwitPic:(NSData *)file withMessage:(NSString *)message withConsumer:(OAConsumer *)consumer accessToken:(OAToken *)accessToken andTwitPicAPIKey:(NSString *)twitPicAPIKey {
    
    CFUUIDRef theUUID = CFUUIDCreate(nil);
    CFStringRef string = CFUUIDCreateString(nil, theUUID);
    CFRelease(theUUID);
    NSString *nonce = [NSString stringWithString:(__bridge NSString *)string];
    CFRelease(string);
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/verify_credentials.json"];
    
    NSString *realm = @"http://api.twitter.com/";
    NSString *timestamp = [NSString stringWithFormat:@"%ld", time(nil)];
    
    NSMutableArray *parameterPairs = [NSMutableArray  arrayWithCapacity:6];
    [parameterPairs addObject:[NSString stringWithFormat:@"oauth_consumer_key=%@",urlencode(consumer.key)]];
    [parameterPairs addObject:[NSString stringWithFormat:@"oauth_signature_method=%@",urlencode(@"HMAC-SHA1")]];
    [parameterPairs addObject:[NSString stringWithFormat:@"oauth_nonce=%@",urlencode(nonce)]];
    [parameterPairs addObject:[NSString stringWithFormat:@"oauth_timestamp=%@",urlencode(timestamp)]];
    [parameterPairs addObject:@"oauth_version=1.0"];
    [parameterPairs addObject:[NSString stringWithFormat:@"oauth_token=%@",accessToken.key]];
    
    NSArray *sortedPairs = [parameterPairs sortedArrayUsingSelector:@selector(compare:)];
    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];

    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@", @"GET", urlencode(@"https://api.twitter.com/1.1/account/verify_credentials.json"), urlencode(normalizedRequestParameters)];
    
    NSString *secretForSigning = [NSString stringWithFormat:@"%@&%@", urlencode(consumer.secret), urlencode(accessToken.secret)];

    NSData *secretData = [secretForSigning dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [signatureBaseString dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
	CCHmac(kCCHmacAlgSHA1, [secretData bytes], [secretData length], [clearTextData bytes], [clearTextData length], result);
    char base64Result[32];
    size_t theResultLength = 32;
    Base64EncodeDataFHS(result, 20, base64Result, &theResultLength);
    NSData *theData = [NSData dataWithBytes:base64Result length:theResultLength];
    NSString *signature = [[NSString alloc]initWithData:theData encoding:NSUTF8StringEncoding];

    NSString *oauthToken = [NSString stringWithFormat:@"oauth_token=\"%@\", ", urlencode(accessToken.key)];
    
    NSString *oauthHeaders = [NSString stringWithFormat:@"OAuth realm=\"%@\", oauth_consumer_key=\"%@\", %@oauth_signature_method=\"%@\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", oauth_version=\"1.0\"", urlencode(realm), urlencode(consumer.key), oauthToken, urlencode(@"HMAC-SHA1"), urlencode(signature), timestamp, nonce];
    
    NSURL *url = [NSURL URLWithString:@"http://api.twitpic.com/2/upload.json"];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setValue:oauthHeaders forHTTPHeaderField:@"X-Verify-Credentials-Authorization"];
    [req setValue:baseURL.absoluteString forHTTPHeaderField:@"X-Auth-Service-Provider"];

    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    
    [req addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];

    // message
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"message\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // key
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"key\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[twitPicAPIKey dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // picture
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media\"; filename=\"%@.jpg\"\r\n",nonce] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpeg\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:UIImageJPEGRepresentation([UIImage imageWithData:file], 0.8)];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [req setHTTPBody:body];
    
    [req setValue:[NSString stringWithFormat:@"%d",body.length] forHTTPHeaderField:@"Content-Length"];
    
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
    
    id parsedJSONResponse = removeNullTwit([NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil]);
    
    if (error) {
        return error;
    }

    if (response.statusCode >= 304) {
        return error;
    }
    
    if ([parsedJSONResponse isKindOfClass:[NSDictionary class]]) {
        NSString *errorMessage = [parsedJSONResponse objectForKey:@"error"];
        NSArray *errorArray = [parsedJSONResponse objectForKey:@"errors"];
        if (errorMessage.length > 0) {
            return [NSError errorWithDomain:errorMessage code:[[parsedJSONResponse objectForKey:@"code"]intValue] userInfo:[NSDictionary dictionaryWithObject:req forKey:@"request"]];
        } else if (errorArray.count > 0) {
            if (errorArray.count > 1) {
                return [NSError errorWithDomain:@"Multiple Errors" code:1337 userInfo:[NSDictionary dictionaryWithObject:req forKey:@"request"]];
            } else {
                NSDictionary *theError = [errorArray objectAtIndex:0];
                return [NSError errorWithDomain:[theError objectForKey:@"message"] code:[[theError objectForKey:@"code"]integerValue] userInfo:[NSDictionary dictionaryWithObject:req forKey:@"request"]];
            }
        }
    }
    
    return parsedJSONResponse;
}

@end
