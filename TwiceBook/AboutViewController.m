//
//  AboutViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 10/27/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "AboutViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation AboutViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    [self.view setBackgroundColor:[UIColor underPageBackgroundColor]];
    
    UINavigationBar *navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"About"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:navBar];

    UIImageView *theImageView = [[UIImageView alloc]initWithFrame:CGRectMake(103, 71, 114, 114)];
    [theImageView setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"iTunesArtwork_512" ofType:@"png"]]];
    theImageView.layer.masksToBounds = YES;
    theImageView.layer.cornerRadius = 15;
    [self.view addSubview:theImageView];
    
    UIView *view = [[UIView alloc]initWithFrame:theImageView.frame];
    view.backgroundColor = [UIColor clearColor];
    view.layer.masksToBounds = NO;
    view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
    view.layer.shadowRadius = 8.0;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOpacity = 0.8;
    [self.view addSubview:view];
    [self.view sendSubviewToBack:view];
    
    UILabel *twoFace = [[UILabel alloc]initWithFrame:CGRectMake(0, 210, 320, 51)];
    twoFace.font = [UIFont boldSystemFontOfSize:28];
    twoFace.text = @"TwoFace";
    twoFace.textAlignment = UITextAlignmentCenter;
    twoFace.backgroundColor = [UIColor clearColor];
    [self.view addSubview:twoFace];
    
    UILabel *version = [[UILabel alloc]initWithFrame:CGRectMake(0, 247, 320, 51)];
    version.font = [UIFont boldSystemFontOfSize:19];
    version.text = [@"v" stringByAppendingString:[[NSBundle mainBundle]infoDictionary][@"CFBundleVersion"]];
    version.textAlignment = UITextAlignmentCenter;
    version.backgroundColor = [UIColor clearColor];
    [self.view addSubview:version];
    
    UILabel *nathaniel = [[UILabel alloc]initWithFrame:CGRectMake(0, 292, 320, 51)];
    nathaniel.textAlignment = UITextAlignmentCenter;
    nathaniel.text = @"By Nathaniel Symer";
    nathaniel.font = [UIFont systemFontOfSize:17];
    nathaniel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:nathaniel];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = theImageView.frame;
    button.backgroundColor = [UIColor clearColor];
    button.layer.masksToBounds = YES;
    button.layer.cornerRadius = 15;
    button.alpha = 0.55;
    [button addTarget:self action:@selector(openURL) forControlEvents:UIControlEventTouchUpInside];
    UIGraphicsBeginImageContextWithOptions(theImageView.bounds.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetFillColorWithColor(context, [UIColor darkGrayColor].CGColor);
    CGContextFillRect(context, view.bounds);
    CGContextRestoreGState(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [button setImage:image forState:UIControlStateHighlighted];
    [self.view addSubview:button];
    
    UITextView *socrates = [[UITextView alloc]initWithFrame:CGRectMake(20, screenBounds.size.height-71, 280, 71)];
    socrates.backgroundColor = [UIColor clearColor];
    socrates.font = [UIFont systemFontOfSize:14];
    socrates.text = @"\"There is only one good, knowledge, and one evil, ignorance.\"\n― Socrates";
    socrates.editable = NO;
    [self.view addSubview:socrates];
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)openURL {
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/twoface/id539358106?ls=1&mt=8"]];
}

@end
