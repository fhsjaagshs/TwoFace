//
//  FacebookStatusViewController.h
//  TwoFace
//
//  Created by Nathaniel Symer on 7/21/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FacebookStatusViewController : UIViewController <FBRequestDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UITextViewDelegate> {
    BOOL isLoadedDraft;
    NSMutableDictionary *loadedDraft;
    CGRect originalTextViewFrame;
}

@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UIToolbar *bar;
@property (strong, nonatomic) UIImage *pickedImage;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *postButton;
@property (strong, nonatomic) NSString *toID;
@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;

@end
