//
//  CommentViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 7/11/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "CommentViewController.h"

@implementation CommentViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    
    self.commentField = [[UITextView alloc]initWithFrame:screenBounds];
    _commentField.backgroundColor = [UIColor whiteColor];
    _commentField.editable = YES;
    _commentField.clipsToBounds = YES;
    _commentField.font = [UIFont systemFontOfSize:14];
    _commentField.delegate = self;
    _commentField.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _commentField.scrollIndicatorInsets = _commentField.contentInset;
    [self.view addSubview:_commentField];
    
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Reply"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Post" style:UIBarButtonItemStyleDone target:self action:@selector(post)];
    [_navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:_navBar];
    
    [_commentField becomeFirstResponder];
    _navBar.topItem.rightBarButtonItem.enabled = (_commentField.text.length > 0);
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification*)notification {
    [self moveTextViewForKeyboard:notification up:YES];
}

- (void)keyboardWillHide:(NSNotification*)notification {
    [self moveTextViewForKeyboard:notification up:NO];
}

- (void)moveTextViewForKeyboard:(NSNotification*)notification up:(BOOL)up {
    UIViewAnimationCurve animationCurve;
    
    [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    NSTimeInterval animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardRect = [self.view convertRect:[notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    _commentField.contentInset = UIEdgeInsetsMake(64, 0, up?keyboardRect.size.height:0, 0);
    _commentField.scrollIndicatorInsets = _commentField.contentInset;
    
    [UIView commitAnimations];
}

- (void)post {
    [_commentField resignFirstResponder];
    [Settings showHUDWithTitle:@"Posting..."];

    NSMutableURLRequest *req = [FHSFacebook.shared generateRequestWithURL:[NSString stringWithFormat:@"https://graph.facebook.com/%@/comments",_postIdentifier] params:@{ @"message": _commentField.text } HTTPMethod:@"POST"];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        [Settings hideHUD];
        
        if (error) {
            [_commentField becomeFirstResponder];
            qAlert(@"Facebook Error", @"Failed to post comment, please try again at a later time.");
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
            [[NSNotificationCenter defaultCenter]postNotificationName:@"commentsNotif" object:nil];
        }
    }];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (id)initWithPostID:(NSString *)postID {
    self = [super init];
    if (self) {
        self.postIdentifier = postID;
    }
    return self;
}

- (void)textViewDidChange:(UITextView *)textView {
    _navBar.topItem.rightBarButtonItem.enabled = (_commentField.text.length > 0);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
