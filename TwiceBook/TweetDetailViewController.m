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

@synthesize tv, username, displayName, theImageView, tweet, navBar;

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    self.view.backgroundColor = [UIColor underPageBackgroundColor];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    NSString *timestamp = [twitterDateFromString([self.tweet objectForKey:@"created_at"]) timeElapsedSinceCurrentDate];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[@"Tweet" stringByAppendingFormat:@" - %@ Ago",timestamp]];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(replyOrRetweet)];
                                
    [bar pushNavigationItem:topItem animated:NO];
    
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
    
    self.tv = [[UITextView alloc]initWithFrame:CGRectMake(5, 124, screenBounds.size.width-10, screenBounds.size.height-124)];
    self.tv.font = [UIFont systemFontOfSize:14];
    self.tv.text = [self.tweet objectForKey:@"text"];
    self.tv.dataDetectorTypes = UIDataDetectorTypeLink;
    self.tv.backgroundColor = [UIColor clearColor];
    self.tv.editable = NO;
    
    [self.view addSubview:self.tv];
    [self.view bringSubviewToFront:self.tv];
    
    self.displayName = [[UILabel alloc]initWithFrame:CGRectMake(14, 57, 219, 21)];
    self.displayName.text = [[self.tweet objectForKey:@"user"]objectForKey:@"name"];
    self.displayName.font = [UIFont boldSystemFontOfSize:17];
    self.displayName.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.displayName];
    [self.view bringSubviewToFront:self.displayName];
    
    self.username = [[UILabel alloc]initWithFrame:CGRectMake(14, 86, 219, 21)];
    self.username.font = [UIFont systemFontOfSize:17];
    self.username.text = [@"@" stringByAppendingString:[[self.tweet objectForKey:@"user"]objectForKey:@"screen_name"]];
    self.username.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.username];
    [self.view bringSubviewToFront:self.username];
    
    self.theImageView = [[UIImageView alloc]initWithFrame:CGRectMake(229, 53, 71, 71)];
    self.theImageView.layer.masksToBounds = YES;
    self.theImageView.layer.borderColor = [UIColor blackColor].CGColor;
    self.theImageView.layer.borderWidth = 1;
    self.theImageView.layer.cornerRadius = 5;
    self.theImageView.backgroundColor = [UIColor darkGrayColor];
    
    [self.view addSubview:self.theImageView];
    [self.view bringSubviewToFront:self.theImageView];
    
    CGSize labelSize = self.tv.contentSize;
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
    NSString *imageName = [[[[self.tweet objectForKey:@"user"]objectForKey:@"profile_image_url"]componentsSeparatedByString:@"/"]lastObject];
    return [kCachesDirectory stringByAppendingPathComponent:imageName];
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

                NSString *rawProfileURL = [[self.tweet objectForKey:@"user"]objectForKey:@"profile_image_url"];

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

- (id)initWithTweet:(NSDictionary *)aTweet {
    if (self = [super init]) {
        [self setTweet:aTweet];
    }
    return self;
}

- (void)replyOrRetweet {
    AppDelegate *ad = kAppDelegate;
    BOOL isLoggedInUser = [[[self.tweet objectForKey:@"user"]objectForKey:@"screen_name"]isEqualToString:ad.engine.loggedInUsername];

    __block BOOL isFavorite = [[self.tweet objectForKey:@"favorited"]boolValue];
    
    if (isLoggedInUser) {
        ReplyViewController *d = [[ReplyViewController alloc]initWithTweet:self.tweet];
        [self presentModalViewController:d animated:YES];
    } else {
        UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            
            if (buttonIndex == 0) {
                ReplyViewController *d = [[ReplyViewController alloc]initWithTweet:self.tweet];
                [self presentModalViewController:d animated:YES];
            } else if (buttonIndex == 1) {
                [ad showHUDWithTitle:@"Retweeting..."];
                
                dispatch_async(GCDBackgroundThread, ^{
                    @autoreleasepool {
                        
                        NSError *error = [ad.engine retweet:[self.tweet objectForKey:@"id_str"]];
                        
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
                        
                        NSError *error = [ad.engine markTweet:[self.tweet objectForKey:@"id_str"] asFavorite:!isFavorite];
                        
                        dispatch_sync(GCDMainThread, ^{
                            @autoreleasepool {
                                [ad hideHUD];
                                
                                if (error) {
                                    [ad showSelfHidingHudWithTitle:[NSString stringWithFormat:@"Error %d",error.code]];
                                } else {
                                    int index = [[[kAppDelegate viewController]timeline]indexOfObject:self.tweet];
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
    
    AppDelegate *ad = kAppDelegate;
    
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            
            NSString *cachePath = [kCachesDirectory stringByAppendingPathComponent:[notif.object lastPathComponent]];
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
    NSString *timestamp = [twitterDateFromString([self.tweet objectForKey:@"created_at"]) timeElapsedSinceCurrentDate];
    self.navBar.topItem.title = [@"Tweet" stringByAppendingFormat:@" - %@ Ago",timestamp];
    [self performSelector:@selector(setTitleText) withObject:nil afterDelay:5.0f];
}

- (void)close {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"imageOpen" object:nil];
    [self dismissModalViewControllerAnimated:YES];
}

@end
