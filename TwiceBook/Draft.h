//
//  Draft.h
//  TwoFace
//
//  Created by Nathaniel Symer on 12/16/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Draft : NSObject

+ (Draft *)draft;

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *guid;
@property (nonatomic, strong) NSString *to_id;

@end
