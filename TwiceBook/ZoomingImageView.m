//
//  ZoomingImageView.m
//  ZoomingImageView
//
//  Created by Nathaniel Symer on 7/11/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ZoomingImageView.h"

@implementation ZoomingImageView

@synthesize theImageView;

- (void)setup {
    self.multipleTouchEnabled = YES;
    self.maximumZoomScale = 5.0;
    self.minimumZoomScale = 1.0;
    self.delegate = self;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.backgroundColor = [UIColor blackColor];
    
    self.theImageView = [[UIImageView alloc]initWithFrame:self.frame];
    self.theImageView.backgroundColor = [UIColor blackColor];
    self.theImageView.contentMode = UIViewContentModeCenter;
    [self addSubview:self.theImageView];
}

- (id)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [self setup];
}

- (void)adjustFrame {
    CGRect photoImageViewFrame;
    photoImageViewFrame.origin = CGPointZero;
    photoImageViewFrame.size = self.theImageView.image.size;
    self.theImageView.frame = photoImageViewFrame;
    self.contentSize = photoImageViewFrame.size;
    
    [self setMaxMinZoomScalesForCurrentBounds];
}

- (void)loadImage:(UIImage *)image {
    
    [self.theImageView setImage:image];
   
    self.zoomScale = self.minimumZoomScale;
    
    CGRect photoImageViewFrame;
    photoImageViewFrame.origin = CGPointZero;
    photoImageViewFrame.size = image.size;
    self.theImageView.frame = photoImageViewFrame;
    self.contentSize = photoImageViewFrame.size;
    
    [self setMaxMinZoomScalesForCurrentBounds];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.theImageView;
}

- (void)zoomOut {
    [self zoomToPoint:CGPointMake(0, 0) withScale:self.minimumZoomScale animated:YES];
    self.zoomScale = self.minimumZoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds {

	if (self.theImageView.image == nil) {
        return;
    }

    self.zoomScale = self.minimumZoomScale;
	self.maximumZoomScale = 1;
	self.minimumZoomScale = 1;
	
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = self.theImageView.frame.size;

    CGFloat xScale = boundsSize.width/imageSize.width;
    CGFloat yScale = boundsSize.height/imageSize.height;
    CGFloat minScale = MIN(xScale, yScale);

	if (xScale > 1 && yScale > 1) {
		minScale = 1.0;
	}
	
	self.maximumZoomScale = 5;
	self.minimumZoomScale = minScale;
	self.zoomScale = minScale;
	
	self.theImageView.frame = CGRectMake(0, 0, self.theImageView.frame.size.width, self.theImageView.frame.size.height);
	[self setNeedsLayout];
}

- (void)layoutSubviews {
	[super layoutSubviews];

    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.theImageView.frame;

    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
	} else {
        frameToCenter.origin.x = 0;
	}

    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
	} else {
        frameToCenter.origin.y = 0;
	}
    
	if (!CGRectEqualToRect(self.theImageView.frame, frameToCenter)) {
		self.theImageView.frame = frameToCenter;
    }
}

@end
