//
//  HelperFunctions.h
//  TwoFace
//
//  Created by Nathaniel Symer on 8/5/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

void qAlert(NSString *title, NSString *message);
CGRect resizeRectToWidth(CGRect rect, CGFloat newWidth);
BOOL is5();
BOOL any(BOOL one, BOOL two);
NSString * encodeForURL(NSString *urlString);