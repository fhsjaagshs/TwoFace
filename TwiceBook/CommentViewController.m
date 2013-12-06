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
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Reply"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Post" style:UIBarButtonItemStyleDone target:self action:@selector(post)];
    [_navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:_navBar];
    
    self.commentField = [[UITextView alloc]initWithFrame:CGRectMake(0, self.navBar.frame.size.height, screenBounds.size.width, screenBounds.size.height-44)];
    _commentField.backgroundColor = [UIColor whiteColor];
    _commentField.editable = YES;
    _commentField.clipsToBounds = YES;
    _commentField.font = [UIFont systemFontOfSize:14];
    _commentField.delegate = self;
    [self.view addSubview:_commentField];
    [self.view bringSubviewToFront:_commentField];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [_commentField becomeFirstResponder];
    [_commentField setDelegate:self];
    _navBar.topItem.rightBarButtonItem.enabled = (_commentField.text.length > 0);
}

- (void)keyboardWillShow:(NSNotification*)notification {
    [self moveTextViewForKeyboard:notification up:YES];
}

- (void)keyboardWillHide:(NSNotification*)notification {
    [self moveTextViewForKeyboard:notification up:NO];
}

- (void)moveTextViewForKeyboard:(NSNotification*)notification up:(BOOL)up {
    UIViewAnimationCurve animationCurve;
    
    [[notification userInfo][UIKeyboardAnimationCurveUserInfoKey]getValue:&animationCurve];
    NSTimeInterval animationDuration = [[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardRect = [self.view convertRect:[[notification userInfo][UIKeyboardFrameEndUserInfoKey]CGRectValue] fromView:nil];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    if (up) {
        CGRect newTextViewFrame = _commentField.frame;
        _originalTextViewFrame = _commentField.frame;
        newTextViewFrame.size.height = keyboardRect.origin.y-_commentField.frame.origin.y;
        _commentField.frame = newTextViewFrame;
    } else {
        _commentField.frame = _originalTextViewFrame;
    }
    
    [UIView commitAnimations];
}

- (void)post {
    AppDelegate *ad = [Settings appDelegate];
    
    [_commentField resignFirstResponder];
    [ad showHUDWithTitle:@"Posting..."];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/comments",_postIdentifier]]];
    [req setHTTPMethod:@"POST"];
    
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    
    [req addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"access_token\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[FHSFacebook.shared.accessToken dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"message\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[_commentField.text dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [req setHTTPBody:body];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        [ad hideHUD];
        
        if (error) {
            [_commentField becomeFirstResponder];
            qAlert(@"Facebook Error", @"Failed to post comment, please try again at a later time.");
        } else {
            [self dismissModalViewControllerAnimated:YES];
            [[NSNotificationCenter defaultCenter]postNotificationName:@"commentsNotif" object:nil];
        }
    }];
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [super dismissModalViewControllerAnimated:animated];
}

- (id)initWithPostID:(NSString *)postID {
    if (self = [super init]) {
        self.postIdentifier = postID;
    }
    return self;
}

- (void)textViewDidChange:(UITextView *)textView {
    _navBar.topItem.rightBarButtonItem.enabled = (_commentField.text.length > 0);
}

@end
