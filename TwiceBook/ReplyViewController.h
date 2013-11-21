//
//  Reply View Controller.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/6/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReplyViewController : UIViewController <FBRequestDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

// Facebook
@property (assign, nonatomic) BOOL isFacebook;
@property (strong, nonatomic) NSString *toID;

// Twitter
@property (strong, nonatomic) UILabel *charactersLeft;
@property (strong, nonatomic) Tweet *tweet;

// UI
@property (strong, nonatomic) UITextView *replyZone;
@property (strong, nonatomic) UIToolbar *bar;
@property (strong, nonatomic) UINavigationBar *navBar;

// Content Handling
@property (strong, nonatomic) UIImage *imageFromCameraRoll;
@property (strong, nonatomic) NSMutableDictionary *loadedDraft;
@property (assign, nonatomic) BOOL isLoadedDraft;
@property (assign, nonatomic) CGRect originalTextViewFrame;

- (instancetype)initWithToID:(NSString *)toId;
- (id)initWithTweet:(Tweet *)tweets;
- (void)refreshCounter;

@end
