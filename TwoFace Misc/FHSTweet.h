//
//  FHSTweet.h
//  ArchBook
//
//  Created by Nathaniel Symer on 6/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FHSTweet : NSObject { 
    NSDictionary *contents;
}

- (NSString *)tweet;
- (NSString *)author;

- (id)initWithTweetDictionary:(NSDictionary*)_contents;

@end
