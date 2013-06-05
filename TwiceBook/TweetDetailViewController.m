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

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    self.view.backgroundColor = [UIColor underPageBackgroundColor];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    NSString *timestamp = [_tweet.createdAt timeElapsedSinceCurrentDate];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[@"Tweet" stringByAppendingFormat:@" - %@ Ago",timestamp]];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(replyOrRetweet)];
                                
    [bar pushNavigationItem:topItem animated:NO];
    
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
    
    self.tv = [[UITextView alloc]initWithFrame:CGRectMake(5, 124, screenBounds.size.width-10, screenBounds.size.height-124)];
    _tv.text = _tweet.text;
    _tv.font = [UIFont systemFontOfSize:14];
    _tv.dataDetectorTypes = UIDataDetectorTypeLink;
    _tv.backgroundColor = [UIColor clearColor];
    _tv.editable = NO;
    
    [self.view addSubview:_tv];
    [self.view bringSubviewToFront:_tv];
    
    self.displayName = [[UILabel alloc]initWithFrame:CGRectMake(14, 57, 219, 21)];
    _displayName.text = _tweet.user.name;
    _displayName.font = [UIFont boldSystemFontOfSize:17];
    _displayName.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_displayName];
    [self.view bringSubviewToFront:_displayName];
    
    self.username = [[UILabel alloc]initWithFrame:CGRectMake(14, 86, 219, 21)];
    _username.text = [@"@" stringByAppendingString:_tweet.user.screename];
    _username.font = [UIFont systemFontOfSize:17];
    _username.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:_username];
    [self.view bringSubviewToFront:_username];
    
    self.theImageView = [[UIImageView alloc]initWithFrame:CGRectMake(229, 53, 71, 71)];
    _theImageView.layer.masksToBounds = YES;
    _theImageView.layer.borderColor = [UIColor blackColor].CGColor;
    _theImageView.layer.borderWidth = 1;
    _theImageView.layer.cornerRadius = 5;
    _theImageView.backgroundColor = [UIColor darkGrayColor];
    
    [self.view addSubview:_theImageView];
    [self.view bringSubviewToFront:_theImageView];
    
    CGSize labelSize = _tv.contentSize;
    CGFloat height = 73+labelSize.height;
    
    CGFloat maxHeight = self.view.frame.size.height-49-5;
    
    if (height > maxHeight) {
        height = maxHeight;
    }
    
    CGRect bgviewFrame = CGRectMake(5, 49, 310, height);
    
    FHSGradientView *gradientBG = [[FHSGradientView alloc]initWithFrame:bgviewFrame];
    [self.view addSubview:gradientBG];
    [self.view sendSubviewToBack:gradientBG];
    
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
        UIImage *image = [[UIImage alloc]initWithContentsOfFile:imageSavePath];
        
        for (UIView *view in self.view.subviews) {
            if ([view isKindOfClass:[UIActivityIndicatorView class]]) {
                [view removeFromSuperview];
            }
        }
        
        [self.theImageView setImage:image];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    } else {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        aiv.center = self.theImageView.center;
        [self.view addSubview:aiv];
        [self.view bringSubviewToFront:aiv];
        [aiv startAnimating];
        
        dispatch_async(GCDBackgroundThread, ^{
            @autoreleasepool {
                id image = nil;

                NSString *rawProfileURL = _tweet.user.profileImageURL;

                rawProfileURL = [rawProfileURL stringByReplacingOccurrencesOfString:@"_normal" withString:@"_bigger"]; //
                
                NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:rawProfileURL]];
                
                NSHTTPURLResponse *response = nil;
                NSError *error = nil;
                NSData *theImageData = [NSURLConnection sendSynchronousRequest:imageRequest returningResponse:&response error:&error];
                
                if (oneIsCorrect(response == nil, error != nil)) {
                    image = nil;
                } else if (response.statusCode >= 304) {
                    image = nil;
                } else {
                    image = [UIImage imageWithData:theImageData];
                }

                if (image == nil) {
                    dispatch_sync(GCDMainThread, ^{
                        @autoreleasepool {
                            for (UIView *view in self.view.subviews) {
                                if ([view isKindOfClass:[UIActivityIndicatorView class]]) {
                                    [view removeFromSuperview];
                                }
                            }
                            [self.theImageView setHidden:YES];
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        }
                    });
                } else {
                    dispatch_sync(GCDMainThread, ^{
                        @autoreleasepool {
                            for (UIView *view in self.view.subviews) {
                                if ([view isKindOfClass:[UIActivityIndicatorView class]]) {
                                    [view removeFromSuperview];
                                }
                            }
                            
                            if ([image isKindOfClass:[UIImage class]]) {
                                UIImage *downloadedImage = (UIImage *)image;
                                [UIImagePNGRepresentation(downloadedImage) writeToFile:imageSavePath atomically:YES];
                                [self.theImageView setImage:downloadedImage];
                            } else {
                                [self.theImageView setHidden:YES];
                            }
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        }
                    });
                }
            }
        });
    }
}

- (id)initWithTweet:(Tweet *)aTweet {
    if (self = [super init]) {
        self.tweet = aTweet;
    }
    return self;
}

- (void)replyOrRetweet {
    AppDelegate *ad = [Settings appDelegate];

    __block BOOL isFavorite = _tweet.isFavorited;
    
    if ([_tweet.user.screename isEqualToString:[[FHSTwitterEngine sharedEngine]loggedInUsername]]) {
        ReplyViewController *d = [[ReplyViewController alloc]initWithTweet:_tweet];
        [self presentModalViewController:d animated:YES];
    } else {
        UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            
            if (buttonIndex == 0) {
                ReplyViewController *d = [[ReplyViewController alloc]initWithTweet:_tweet];
                [self presentModalViewController:d animated:YES];
            } else if (buttonIndex == 1) {
                [ad showHUDWithTitle:@"Retweeting..."];
                
                dispatch_async(GCDBackgroundThread, ^{
                    @autoreleasepool {
                        
                        NSError *error = [[FHSTwitterEngine sharedEngine]retweet:_tweet.identifier];
                        
                        dispatch_sync(GCDMainThread, ^{
                            @autoreleasepool {
                                [ad hideHUD];
                                if (error) {
                                    [ad showSelfHidingHudWithTitle:[NSString stringWithFormat:@"Error %d",error.code]];
                                }
                            }
                        });
                    }
                });
            } else if (buttonIndex == 2) {
                
                if (!isFavorite) {
                    [ad showHUDWithTitle:@"Favoriting..."];
                } else {
                    [ad showHUDWithTitle:@"Unfavoriting..."];
                }
                
                dispatch_async(GCDBackgroundThread, ^{
                    @autoreleasepool {
                        
                        NSError *error = [[FHSTwitterEngine sharedEngine]markTweet:_tweet.identifier asFavorite:!isFavorite];
                        
                        dispatch_sync(GCDMainThread, ^{
                            @autoreleasepool {
                                [ad hideHUD];
                                
                                if (error) {
                                    [ad showSelfHidingHudWithTitle:[NSString stringWithFormat:@"Error %d",error.code]];
                                } else {
                                    int index = [[[[Settings appDelegate]viewController]timeline]indexOfObject:self.tweet];
                                    if (index != INT_MAX) {
                                        [self.tweet setValue:isFavorite?@"false":@"true" forKey:@"favorited"];
                                        [[[ad viewController]timeline]replaceObjectAtIndex:index withObject:self.tweet];
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
    
    AppDelegate *ad = [Settings appDelegate];
    
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            
            NSString *cachePath = [[Settings cachesDirectory]stringByAppendingPathComponent:[notif.object lastPathComponent]];
            NSData *imageData = [NSData dataWithContentsOfFile:cachePath];
            
            if (imageData.length == 0) {
                dispatch_sync(GCDMainThread, ^{
                    @autoreleasepool {
                        [ad showHUDWithTitle:@"Loading Image..."];
                    }
                });
                imageData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[notif object]] returningResponse:nil error:nil];
            }
            
            [ad hideHUD];
            
            if (imageData.length == 0) {
                dispatch_sync(GCDMainThread, ^{
                    @autoreleasepool {
                        [ad showSelfHidingHudWithTitle:@"Error Loading Image"];
                    }
                });
            } else {
                [imageData writeToFile:cachePath atomically:YES];
                dispatch_sync(GCDMainThread, ^{
                    @autoreleasepool {
                        ImageDetailViewController *vc = [[ImageDetailViewController alloc]initWithData:imageData];
                        [self presentModalViewController:vc animated:YES];
                    }
                });
            }
        }
    });
}

- (void)setTitleText {
    NSString *timestamp = [_tweet.createdAt timeElapsedSinceCurrentDate];
    self.navBar.topItem.title = [@"Tweet" stringByAppendingFormat:@" - %@ Ago",timestamp];
    [self performSelector:@selector(setTitleText) withObject:nil afterDelay:5.0f];
}

- (void)close {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"imageOpen" object:nil];
    [self dismissModalViewControllerAnimated:YES];
}

@end
