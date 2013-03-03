//
//  FHSTweet.m
//  ArchBook
//
//  Created by Nathaniel Symer on 6/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FHSTweet.h"

@implementation FHSTweet

- (id)initWithTweetDictionary:(NSDictionary*)_contents {
    
	if(self = [super init]) {
		contents = _contents;
	}
    
	return self;
}

- (NSString *)tweet {
    
	return [contents objectForKey:@"text"];
}

- (NSString *)author {
    
	return [[contents objectForKey:@"user"] objectForKey:@"screen_name"];
}
@end
