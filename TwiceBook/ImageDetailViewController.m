//
//  ImageDetailViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 7/11/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ImageDetailViewController.h"

@implementation ImageDetailViewController

- (void)loadView {
    [super loadView];
    self.view = [[UIView alloc]initWithFrame:[[UIScreen mainScreen]bounds]];
    self.view.multipleTouchEnabled = YES;
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = [UIColor blackColor];
    
    self.zoomingImageView = [[ZoomingImageView alloc]initWithFrame:[[UIScreen mainScreen]bounds]];
    [self.view addSubview:self.zoomingImageView];

    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 20, 320, 44)];
    [self.navBar setBarStyle:UIBarStyleBlackTranslucent];
    
    UINavigationItem *item = [[UINavigationItem alloc]initWithTitle:@""];
    
    if (self.shouldShowSaveButton) {
        item.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(saveImage)];
    }
    
    item.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    
    [self.navBar pushNavigationItem:item animated:YES];
    [self.view addSubview:self.navBar];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(showControls) name:kEnteringForegroundNotif object:nil];
    
    self.navBar.topItem.title = [[NSString alloc]initWithFormat:@"%.0f x %.0f", self.image.size.width, self.image.size.height];
    [self.zoomingImageView setContentSize:self.image.size];
    [self.zoomingImageView loadImage:self.image];
    
    [self performSelector:@selector(hideControls) withObject:nil afterDelay:5.0f];
    
    UITapGestureRecognizer *tt = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewWasDoubleTapped:)];
    [tt setNumberOfTapsRequired:2]; // 2
    [tt setNumberOfTouchesRequired:1]; // 1
    [tt setDelegate:self];
    [self.zoomingImageView addGestureRecognizer:tt];
    
    UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewWasTapped)];
    [t setNumberOfTapsRequired:1];
    [t setNumberOfTouchesRequired:1];
    [t setDelegate:self];
    [self.zoomingImageView addGestureRecognizer:t];
    [t requireGestureRecognizerToFail:tt];
}

- (id)init {
    if (self = [super init]) {
        self.shouldShowSaveButton = YES;
        self.wantsFullScreenLayout = YES;
    }
    return self;
}

- (id)initWithImagePath:(NSString *)path {
    if (self = [self init]) {
        if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            dispatch_async(GCDBackgroundThread, ^{
                @autoreleasepool {
                    self.image = [UIImage imageWithContentsOfFile:path];
                }
            });
        }
    }
    return self;
}

- (id)initWithData:(NSData *)data {
    if (self = [self init]) {
        dispatch_async(GCDBackgroundThread, ^{
            @autoreleasepool {
                if (data.length > 0) {
                    self.image = [UIImage imageWithData:data];
                }
            }
        });
    }
    return self;
}

- (id)initWithImage:(UIImage *)imagey {
    if (self = [self init]) {
        [self setImage:imagey];
    }
    return self;
}

- (void)imageViewWasTapped {
    if (self.navBar.alpha == 0) {
        [self showControls];
    } else {
        [self hideControls];
    }
}

- (void)imageViewWasDoubleTapped:(UIGestureRecognizer *)rec {
    if (self.zoomingImageView.zoomScale > self.zoomingImageView.minimumZoomScale) {
        [self.zoomingImageView zoomOut];
    } else {
        [self.zoomingImageView zoomToPoint:[rec locationInView:self.view] withScale:3 animated:YES];
    }
}

- (void)saveImage {
    UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if (buttonIndex == 0) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[kAppDelegate window] animated:YES];
            hud.mode = MBProgressHUDModeIndeterminate;
            hud.labelText = @"Saving...";
            
            dispatch_async(GCDBackgroundThread, ^{
                @autoreleasepool {
                    UIImageWriteToSavedPhotosAlbum(self.image, nil, nil, nil);
                    dispatch_sync(GCDMainThread, ^{
                        [MBProgressHUD hideHUDForView:[kAppDelegate window] animated:YES];
                    });
                }
            });
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add to Camera Roll...", nil];
    as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [as showInView:self.view];
}

- (void)close {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kEnteringForegroundNotif object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls) object:nil];
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [[UIApplication sharedApplication]setStatusBarHidden:NO];
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

- (void)showControls {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationDelay:0.0];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [self.navBar setAlpha:1];
    [[UIApplication sharedApplication]setStatusBarHidden:NO];
    [self performSelector:@selector(hideControls) withObject:nil afterDelay:5.0f];
    [UIView commitAnimations];
}

- (void)hideControls {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationDelay:0.0];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [self.navBar setAlpha:0];
    [[UIApplication sharedApplication]setStatusBarHidden:YES];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls) object:nil];
    [UIView commitAnimations];
}

- (void)viewWillAppear:(BOOL)animated {
    if (_navBar.alpha == 0) {
        [_navBar setAlpha:1];
        [[UIApplication sharedApplication]setStatusBarHidden:NO];
        [self performSelector:@selector(hideControls) withObject:nil afterDelay:5.0f];
    }
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
    [_zoomingImageView setHidden:NO];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls) object:nil];
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [[UIApplication sharedApplication]setStatusBarHidden:NO];
    [_zoomingImageView setHidden:YES];
    [super viewWillDisappear:animated];
}

@end
