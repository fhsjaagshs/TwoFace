//
//  Status.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Status : NSObject

@property (nonatomic, strong) FacebookUser *from;
@property (nonatomic, strong) FacebookUser *to;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSString *type; // status, link, photo, video, event
@property (nonatomic, strong) NSString *url; // either a link url, other stuff. Assign to the visit link button
@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *thumbnailURL; // display the image in the image View, a thumbnail
@property (nonatomic, strong) NSString *link; // Link to the photo on Facebook, or to the link content
@property (nonatomic, strong) NSString *pictureURL;
@property (nonatomic, strong) NSMutableArray *comments;

@property (nonatomic, strong) NSString *actionsAvailable;
@property (nonatomic, strong) NSString *objectIdentifier;

- (id)initWithDictionary:(NSDictionary *)dict;
+ (Status *)statusWithDictionary:(NSDictionary *)dict;

@end
