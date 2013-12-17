//
//  ZoomingImageViewTwo.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "ZoomingImageView.h"

@interface ZoomingImageView () <UIScrollViewDelegate>

@property (nonatomic, strong) UIImageView *theImageView;

@end

@implementation ZoomingImageView

- (void)setup {
    self.multipleTouchEnabled = YES;
    self.delegate = self;
    self.showsVerticalScrollIndicator = YES;
    self.showsHorizontalScrollIndicator = YES;
    self.backgroundColor = [UIColor clearColor];
    
    self.theImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
    _theImageView.backgroundColor = [UIColor clearColor];
    [self addSubview:_theImageView];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setImage:(UIImage *)image {
    _image = image;
    [self loadImage:_image];
}

- (void)zoomOut {
    [self setZoomScale:self.minimumZoomScale animated:YES];
}

- (CGRect)boundsWithContentInsets {
    CGRect bounds = self.bounds;
    bounds.origin.x += self.contentInset.left;
    bounds.origin.y += self.contentInset.top;
    bounds.size.width -= (self.contentInset.right+self.contentInset.left);
    bounds.size.height -= (self.contentInset.top+self.contentInset.bottom);
    return bounds;
}

- (void)loadImage:(UIImage *)image {
    _theImageView.frame = [self boundsWithContentInsets];
    self.contentSize = CGSizeZero;
    
    _theImageView.image = image;
    
    CGRect photoImageViewFrame;
    photoImageViewFrame.origin = CGPointZero;
    photoImageViewFrame.size = image.size;
    
    _theImageView.frame = photoImageViewFrame;
    self.contentSize = photoImageViewFrame.size;
    
    [self setNeedsLayout];
    
    // Reset - Absolutely crucial
    self.maximumZoomScale = 1;
	self.minimumZoomScale = 1;
	self.zoomScale = 1;
    
    // Bail
	if (!_theImageView.image) {
        return;
    }
    
	// Sizes
    CGSize boundsSize = [self boundsWithContentInsets].size;
    CGSize imageSize = _theImageView.frame.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width/imageSize.width;
    CGFloat yScale = boundsSize.height/imageSize.height;
    CGFloat minScale = MIN(xScale, yScale);
    
	self.maximumZoomScale = minScale*5;
	self.minimumZoomScale = minScale;
	self.zoomScale = self.minimumZoomScale;
    [self setNeedsLayout];
}

- (void)resetImage {
    [self loadImage:_theImageView.image];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _theImageView;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = [self boundsWithContentInsets].size;
    CGRect frameToCenter = _theImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width-frameToCenter.size.width) / 2.0);
	} else {
        frameToCenter.origin.x = 0;
	}
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height-frameToCenter.size.height) / 2.0);
	} else {
        frameToCenter.origin.y = 0;
	}
    
    // Center
    _theImageView.frame = frameToCenter;
}

- (void)zoomToPoint:(CGPoint)zoomPoint withScale:(CGFloat)scale animated:(BOOL)animated {
    //Normalize current content size back to content scale of 1.0f
    CGSize contentSize;
    contentSize.width = (self.contentSize.width/self.zoomScale);
    contentSize.height = (self.contentSize.height/self.zoomScale);
    
    //translate the zoom point to relative to the content rect
    zoomPoint.x = (zoomPoint.x/self.bounds.size.width)*contentSize.width;
    zoomPoint.y = (zoomPoint.y/self.bounds.size.height)*contentSize.height;
    
    //derive the size of the region to zoom to
    CGSize zoomSize;
    zoomSize.width = self.bounds.size.width/scale;
    zoomSize.height = self.bounds.size.height/scale;
    
    //offset the zoom rect so the actual zoom point is in the middle of the rectangle
    CGRect zoomRect;
    zoomRect.origin.x = zoomPoint.x-zoomSize.width/2.0f;
    zoomRect.origin.y = zoomPoint.y-zoomSize.height/2.0f;
    zoomRect.size.width = zoomSize.width;
    zoomRect.size.height = zoomSize.height;
    //apply the resize
    [self zoomToRect:zoomRect animated:animated];
}

@end
