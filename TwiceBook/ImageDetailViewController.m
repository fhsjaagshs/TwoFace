//
//  ImageDetailViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 7/11/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ImageDetailViewController.h"

@interface ImageDetailViewController ()

@property (strong, nonatomic) ZoomingImageView *zoomingImageView;
@property (strong, nonatomic) UINavigationBar *navBar;
@property (strong, nonatomic) UIImage *image;

@end

@implementation ImageDetailViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.shouldShowSaveButton = YES;
    }
    return self;
}

- (instancetype)initWithImagePath:(NSString *)path {
    if (self = [self init]) {
        if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool {
                    self.image = [UIImage imageWithContentsOfFile:path];
                }
            });
        }
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data {
    if (self = [self init]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                if (data.length > 0) {
                    self.image = [UIImage imageWithData:data];
                }
            }
        });
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)imagey {
    self = [self init];
    if (self) {
        self.image = imagey;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    self.view.multipleTouchEnabled = YES;
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = [UIColor blackColor];
    
    self.zoomingImageView = [[ZoomingImageView alloc]initWithFrame:UIScreen.mainScreen.bounds];
    _zoomingImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _zoomingImageView.decelerationRate = UIScrollViewDecelerationRateFast;
    [self.view addSubview:_zoomingImageView];
    _zoomingImageView.image = _image;
    
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 20, 320, 44)];
    _navBar.barStyle = UIBarStyleBlackTranslucent;
    
    UINavigationItem *item = [[UINavigationItem alloc]initWithTitle:[NSString stringWithFormat:@"%.0f x %.0f", _image.size.width, _image.size.height]];
    item.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    
    if (_shouldShowSaveButton) {
        item.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(saveImage)];
    }
    
    [_navBar pushNavigationItem:item animated:YES];
    [self.view addSubview:_navBar];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(showControls) name:kEnteringForegroundNotif object:nil];
    [self performSelector:@selector(hideControls) withObject:nil afterDelay:5.0f];
    
    UITapGestureRecognizer *tt = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewWasDoubleTapped:)];
    [tt setNumberOfTapsRequired:2]; // 2
    [tt setNumberOfTouchesRequired:1]; // 1
    [tt setDelegate:self];
    [_zoomingImageView addGestureRecognizer:tt];
    
    UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewWasSingleTapped:)];
    [t setNumberOfTapsRequired:1];
    [t setNumberOfTouchesRequired:1];
    [t setDelegate:self];
    [_zoomingImageView addGestureRecognizer:t];
    [t requireGestureRecognizerToFail:tt];
}

- (void)imageViewWasSingleTapped:(UIGestureRecognizer *)rec {
    __weak ImageDetailViewController *weakself = self;
    [UIView animateWithDuration:0.2f animations:^{
        weakself.navBar.alpha = (weakself.navBar.alpha == 1.0f)?0.0f:1.0f;
        
        UIView *statusBar = [[UIApplication sharedApplication]valueForKey:@"statusBar"];
        statusBar.alpha = (statusBar.alpha == 1.0f)?0.0f:1.0f;
        
        weakself.view.backgroundColor = (weakself.view.backgroundColor == [UIColor blackColor])?[UIColor whiteColor]:[UIColor blackColor];
    }];
}

- (void)imageViewWasDoubleTapped:(UIGestureRecognizer *)rec {
    if (_zoomingImageView.zoomScale > _zoomingImageView.minimumZoomScale) {
        [_zoomingImageView zoomOut];
    } else {
        [_zoomingImageView zoomToPoint:[rec locationInView:self.view] withScale:_zoomingImageView.maximumZoomScale animated:YES];
    }
}

- (void)saveImage {
    UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if (buttonIndex == 0) {
            [Settings showHUDWithTitle:@"Saving..."];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool {
                    UIImageWriteToSavedPhotosAlbum(_image, nil, nil, nil);
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            [Settings hideHUD];
                        }
                    });
                }
            });
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add to Camera Roll...", nil];
    as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [as showInView:self.view];
}

- (void)close {
 //   [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls) object:nil];
    //[[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
  //  [[UIApplication sharedApplication]setStatusBarHidden:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

/*- (void)viewWillAppear:(BOOL)animated {
    if (_navBar.alpha == 0) {
        [_navBar setAlpha:1];
        [[UIApplication sharedApplication]setStatusBarHidden:NO];
        [self performSelector:@selector(hideControls) withObject:nil afterDelay:5.0f];
    }
    [_zoomingImageView setHidden:NO];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls) object:nil];
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [[UIApplication sharedApplication]setStatusBarHidden:NO];
    [_zoomingImageView setHidden:YES];
    [super viewWillDisappear:animated];
}*/

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
