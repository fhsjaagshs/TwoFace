//
//  TweetDetailViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/6/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "TweetDetailViewController.h"

#define bgviewPadding 23

@implementation TweetDetailViewController

- (instancetype)initWithTweet:(Tweet *)aTweet {
    self = [super init];
    if (self) {
        self.tweet = aTweet;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    NSString *timestamp = [_tweet.createdAt timeElapsedSinceCurrentDate];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[@"Tweet" stringByAppendingFormat:@" - %@ Ago",timestamp]];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(replyOrRetweet)];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];
    
    self.theImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 79, 70, 70)];
    _theImageView.layer.masksToBounds = YES;
    _theImageView.layer.cornerRadius = 35;
    _theImageView.backgroundColor = [UIColor lightGrayColor];
    _theImageView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _theImageView.layer.borderWidth = 1.0f;
    [self.view addSubview:_theImageView];
    
    self.displayName = [[UILabel alloc]initWithFrame:CGRectMake(100, 85, 210, 20)];
    _displayName.text = _tweet.user.name;
    _displayName.font = [UIFont boldSystemFontOfSize:17];
    _displayName.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_displayName];
    
    self.username = [[UILabel alloc]initWithFrame:CGRectMake(100, 110, 210, 20)];
    _username.text = [@"@" stringByAppendingString:_tweet.user.screename];
    _username.font = [UIFont systemFontOfSize:17];
    _username.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_username];
    
    self.tv = [[UITextView alloc]initWithFrame:CGRectMake(5, 150, screenBounds.size.width-10, screenBounds.size.height-150)];
    _tv.text = _tweet.text;
    _tv.font = [UIFont systemFontOfSize:14];
    _tv.dataDetectorTypes = UIDataDetectorTypeLink;
    _tv.backgroundColor = [UIColor clearColor];
    _tv.editable = NO;
    [self.view addSubview:_tv];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(openURL:) name:@"imageOpen" object:nil];
    [self getProfileImage];
    [self performSelector:@selector(setTitleText) withObject:nil afterDelay:1.0f];
}

- (NSString *)imageInCachesDir {
    return [[Settings cachesDirectory]stringByAppendingPathComponent:[[_tweet.user.profileImageURL componentsSeparatedByString:@"/"]lastObject]];
}

- (void)getProfileImage {
    NSString *imageSavePath = [self imageInCachesDir];
    if ([[NSFileManager defaultManager]fileExistsAtPath:imageSavePath]) {
        UIImage *image = [UIImage imageWithContentsOfFile:imageSavePath];
        
        for (UIView *view in self.view.subviews) {
            if ([view isKindOfClass:[UIActivityIndicatorView class]]) {
                [view removeFromSuperview];
            }
        }
        
        [_theImageView setImage:image];
    } else {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        aiv.center = _theImageView.center;
        [self.view addSubview:aiv];
        [self.view bringSubviewToFront:aiv];
        [aiv startAnimating];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                NSString *rawProfileURL = _tweet.user.profileImageURL;

                rawProfileURL = [rawProfileURL stringByReplacingOccurrencesOfString:@"_normal" withString:@"_bigger"]; //
                
                NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:rawProfileURL]];
                
                NSHTTPURLResponse *response = nil;
                NSError *error = nil;
                NSData *theImageData = [NSURLConnection sendSynchronousRequest:imageRequest returningResponse:&response error:&error];

                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        
                        for (UIView *view in self.view.subviews) {
                            if ([view isKindOfClass:[UIActivityIndicatorView class]]) {
                                [view removeFromSuperview];
                            }
                        }
                        
                        if (error) {
                            [_theImageView setHidden:YES];
                        } else {
                            UIImage *downloadedImage = [UIImage imageWithData:theImageData];
                            [UIImagePNGRepresentation(downloadedImage) writeToFile:imageSavePath atomically:YES];
                            [_theImageView setImage:downloadedImage];
                        }
                    }
                });
            }
        });
    }
}

- (void)replyOrRetweet {
    __block BOOL isFavorite = _tweet.isFavorited;
    
    if ([_tweet.user.screename isEqualToString:[[FHSTwitterEngine sharedEngine]authenticatedUsername]]) {
        ReplyViewController *d = [[ReplyViewController alloc]initWithTweet:_tweet];
        [self presentViewController:d animated:YES completion:nil];
    } else {
        UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            if (buttonIndex == 0) {
                ReplyViewController *d = [[ReplyViewController alloc]initWithTweet:_tweet];
                [self presentViewController:d animated:YES completion:nil];
            } else if (buttonIndex == 1) {
                [Settings showHUDWithTitle:@"Retweeting..."];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    @autoreleasepool {
                        id returnValue = [[FHSTwitterEngine sharedEngine]retweet:_tweet.identifier];
                        
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            @autoreleasepool {
                                [Settings hideHUD];
                                if ([returnValue isKindOfClass:[NSError class]]) {
                                    [Settings showSelfHidingHudWithTitle:[NSString stringWithFormat:@"Error %d",[returnValue code]]];
                                }
                            }
                        });
                    }
                });
            } else if (buttonIndex == 2) {
                [Settings showHUDWithTitle:isFavorite?@"Unfavoriting...":@"Favoriting..."];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    @autoreleasepool {
                        id returnValue = [[FHSTwitterEngine sharedEngine]markTweet:_tweet.identifier asFavorite:!isFavorite];
                        
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            @autoreleasepool {
                                [Settings hideHUD];
                                
                                if ([returnValue isKindOfClass:[NSError class]]) {
                                    [Settings showSelfHidingHudWithTitle:[NSString stringWithFormat:@"Error %d",[returnValue code]]];
                                } else {
                                    int index = [[[Cache shared]timeline]indexOfObject:_tweet];
                                    if (index != INT_MAX) {
                                        [_tweet setValue:isFavorite?@"false":@"true" forKey:@"favorited"];
                                        [[Cache shared]timeline][index] = _tweet;
                                    }
                                }
                            }
                        });
                    }
                });
            }
            
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Reply", @"Retweet", isFavorite?@"Unfavorite":@"Favorite", nil];
        as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [as showInView:self.view];
    }
}

- (void)openURL:(NSNotification *)notif {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSString *cachePath = [[Settings cachesDirectory]stringByAppendingPathComponent:[notif.object lastPathComponent]];
            NSData *imageData = [NSData dataWithContentsOfFile:cachePath];
            
            if (imageData.length == 0) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        [Settings showHUDWithTitle:@"Loading Image..."];
                    }
                });
                imageData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:notif.object] returningResponse:nil error:nil];
                
                if (imageData.length > 0) {
                    [imageData writeToFile:cachePath atomically:YES];
                }
            }

            dispatch_sync(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    [Settings hideHUD];
                    if (imageData.length > 0) {
                        ImageDetailViewController *vc = [[ImageDetailViewController alloc]initWithData:imageData];
                        [self presentViewController:vc animated:YES completion:nil];
                    } else {
                        [Settings showSelfHidingHudWithTitle:@"Error Loading Image"];
                    }
                }
            });
        }
    });
}

- (void)setTitleText {
    NSString *timestamp = [_tweet.createdAt timeElapsedSinceCurrentDate];
    _navBar.topItem.title = [NSString stringWithFormat:@"Tweet - %@ Ago",timestamp];
    [self performSelector:@selector(setTitleText) withObject:nil afterDelay:5.0f];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
