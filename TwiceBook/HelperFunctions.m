//
//  HelperFunctions.m
//  TwoFace
//
//  Created by Nathaniel Symer on 8/5/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "HelperFunctions.h"

void qAlert(NSString *title, NSString *message) {
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
}

CGRect resizeRectToWidth(CGRect rect, CGFloat newWidth) {
    CGFloat origWidth = rect.size.width;
    CGFloat ratio = newWidth/origWidth;
    return CGRectMake(rect.origin.x*ratio, rect.origin.y*ratio, rect.size.width*ratio, rect.size.height*ratio);
}

BOOL is5() {
    return ([[UIScreen mainScreen]bounds].size.height == 568);
}

BOOL any(BOOL one, BOOL two) {
    return ((one || two) || (one && two));
}

NSString * encodeForURL(NSString *urlString) {
    CFStringRef url = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)urlString, nil, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
    NSString *result = (__bridge NSString *)url;
	return result;
}