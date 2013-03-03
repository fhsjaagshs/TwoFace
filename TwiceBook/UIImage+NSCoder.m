//
//  UIImage+NSCoder.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/7/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "UIImage+NSCoder.h"

@implementation UIImage (NSCoder)

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeDataObject:UIImagePNGRepresentation(self)];
}

- (id)initWithCoder:(NSCoder *)decoder {
    return [self initWithData:[decoder decodeDataObject]];
}

@end
