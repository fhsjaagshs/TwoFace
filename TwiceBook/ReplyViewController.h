//
//  Reply View Controller.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/6/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReplyViewController : UIViewController 

- (instancetype)initWithToID:(NSString *)toId;
- (instancetype)initWithTweet:(Tweet *)tweets;

@end
