//
//  Reply View Controller.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/6/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ReplyViewController.h"
#import "FHSTwitterEngine.h"

@interface ReplyViewController () <UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (assign, nonatomic) BOOL isFacebook;

@property (strong, nonatomic) Draft *draft;
@property (assign, nonatomic) BOOL isLoadedDraft;

@property (strong, nonatomic) UITextView *replyZone;
@property (strong, nonatomic) UIToolbar *bar;
@property (strong, nonatomic) UINavigationBar *navBar;
@property (strong, nonatomic) UILabel *charactersLeft;

@property (strong, nonatomic) NSString *atUsername;

@end

@implementation ReplyViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.draft = [Draft draft];
    }
    return self;
}

- (instancetype)initWithToID:(NSString *)toId {
    self = [self init];
    if (self) {
        _draft.to_id = toId;
        _draft.type = kFacebookType;
        self.isFacebook = YES;
    }
    return self;
}

- (instancetype)initWithTweet:(Tweet *)aTweet {
    self = [self init];
    if (self) {
        _draft.to_id = aTweet.identifier;
        _draft.type = kTwitterType;
        self.isFacebook = NO;
        self.atUsername = aTweet.user.screename;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]bounds];

    self.replyZone = [[UITextView alloc]initWithFrame:screenBounds];
    _replyZone.font = [UIFont systemFontOfSize:14];
    _replyZone.backgroundColor = [UIColor whiteColor];
    _replyZone.editable = YES;
    _replyZone.delegate = self;
    _replyZone.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _replyZone.scrollIndicatorInsets = _replyZone.contentInset;
    [self.view addSubview:_replyZone];
    [_replyZone addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:nil];
    
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Compose Tweet"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Post" style:UIBarButtonItemStyleDone target:self action:@selector(sendReply)];
    [_navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:_navBar];
    
    self.bar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
    
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    space.width = 5;
    
    _bar.items = @[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(showImageSelector)], space, [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(showDraftsBrowser)]];
    
    if (!_isFacebook) {
        self.charactersLeft = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 310, 44)];
        _charactersLeft.font = [UIFont boldSystemFontOfSize:20];
        _charactersLeft.textAlignment = NSTextAlignmentRight;
        _charactersLeft.textColor = [UIColor blackColor];
        _charactersLeft.backgroundColor = [UIColor clearColor];
        [_bar addSubview:_charactersLeft];
        
        if (_atUsername.length > 0) {
            _replyZone.text = [NSString stringWithFormat:@"@%@ ",_atUsername];
        }
        
        _navBar.topItem.title = @"Reply";
    } else {
        _navBar.topItem.title = @"Compose Status";
    }
    
    _replyZone.inputAccessoryView = _bar;
    
    [_replyZone becomeFirstResponder];
    [self refreshCounter];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(loadDraft:) name:@"draft" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(saveToID:) name:@"passFriendID" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:_replyZone] && [keyPath isEqualToString:@"text"]) {
        _draft.text = _replyZone.text;
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    [self refreshCounter];
    _draft.text = _replyZone.text;
}

- (void)saveToID:(NSNotification *)notif {
    _draft.to_id = notif.object;
    _navBar.topItem.title = [NSString stringWithFormat:@"To %@",[[[Core.shared nameForFacebookID:_draft.to_id]componentsSeparatedByString:@" "]firstObject]];
}

- (void)scaleImageFromCameraRoll {
    if (_draft.image.size.width > 768 && _draft.image.size.height > 768) {
        float ratio = MIN(768/_draft.image.size.width, 768/_draft.image.size.height);
        _draft.image = [_draft.image scaleToSize:CGSizeMake(ratio*_draft.image.size.width, ratio*_draft.image.size.height)];
    }
}

- (void)kickoffTweetPost {
    [Settings showHUDWithTitle:@"Tweeting..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            // Is legit because FHSTwitterEngine does postTweet: if inReplyTo is nil
            id ret = [[FHSTwitterEngine sharedEngine]postTweet:_replyZone.text.stringByTrimmingWhitespace inReplyTo:_draft.to_id];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                [Settings hideHUD];
                [self dismissViewControllerAnimated:YES completion:nil];
                
                if ([ret isKindOfClass:[NSError class]]) {
                    qAlert([NSString stringWithFormat:@"Error %d",[ret code]], [ret localizedDescription]);
                    [self saveDraft];
                } else {
                    [self deletePostedDraft];
                }
            });
        }
    });
}

- (void)showImageSelector {
    [_replyZone resignFirstResponder];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc]init];
            imagePicker.delegate = self;
            
            if (buttonIndex == 0) {
                [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
                [self presentViewController:imagePicker animated:YES completion:nil];
            } else if (buttonIndex == 1) {
                [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                [self presentViewController:imagePicker animated:YES completion:nil];
            } else {
                [_replyZone becomeFirstResponder];
            }
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose from Library...", nil];
        as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [as showInView:self.view];
    } else {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc]init];
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        imagePicker.delegate = self;
        [_replyZone resignFirstResponder];
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];

    _draft.image = info[UIImagePickerControllerOriginalImage];
    [self scaleImageFromCameraRoll];
    
    NSMutableArray *toolbarItems = _bar.items.mutableCopy;
    
    for (UIBarButtonItem *item in toolbarItems.mutableCopy) {
        if (item.customView) {
            [toolbarItems removeObject:item];
        }
    }
    _bar.items = toolbarItems;
    
    [self addImageToolbarItems];
    [_replyZone becomeFirstResponder];
}

- (void)imageTouched {
    [_replyZone resignFirstResponder];
    
    UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if (buttonIndex == 1) {
            ImageDetailViewController *idvc = [[ImageDetailViewController alloc]initWithImage:_draft.image];
            idvc.shouldShowSaveButton = NO;
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [_replyZone becomeFirstResponder];
        }

        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            _draft.image = nil;

            NSMutableArray *toolbarItems = _bar.items.mutableCopy;
            [toolbarItems removeLastObject];
            [toolbarItems removeLastObject];
            _bar.items = toolbarItems;
            
            self.isLoadedDraft = NO;
        }
        
        [self refreshCounter];
        
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Remove Image" otherButtonTitles:@"View Image...", nil];
    as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [as showInView:self.view];
}

- (void)addImageToolbarItems {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *imageToBeSet = [_draft.image scaleProportionallyToSize:CGSizeMake(36, 36)];
    [button setImage:imageToBeSet forState:UIControlStateNormal];
    button.frame = CGRectMake(274, 4, imageToBeSet.size.width, imageToBeSet.size.height);
    button.layer.cornerRadius = 5.0;
    button.layer.masksToBounds = YES;
    button.layer.borderColor = [UIColor darkGrayColor].CGColor;
    button.layer.borderWidth = 1.0;
    [button addTarget:self action:@selector(imageTouched) forControlEvents:UIControlEventTouchUpInside];

    NSMutableArray *newItems = _bar.items.mutableCopy;
    
    UIBarButtonItem *bbiz = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    bbiz.width = 5;
    
    [newItems addObject:bbiz];
    [newItems addObject:[[UIBarButtonItem alloc]initWithCustomView:button]];
    _bar.items = newItems;
    [self refreshCounter];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
    [_replyZone becomeFirstResponder];
}

- (void)refreshCounter {
    int charsLeft = 140-(_draft.image?_replyZone.text.length+20:_replyZone.text.length);
    
    _charactersLeft.text = [NSString stringWithFormat:@"%d",charsLeft];
    
    if (charsLeft < 0) {
        _charactersLeft.textColor = [UIColor redColor];
        _navBar.topItem.rightBarButtonItem.enabled = NO;
    } else if (charsLeft == 140) {
        _navBar.topItem.rightBarButtonItem.enabled = NO;
    } else {
        _charactersLeft.textColor = [UIColor blackColor];
        _navBar.topItem.rightBarButtonItem.enabled = YES;
    }
}

- (void)keyboardWillShow:(NSNotification *)notification {
    [self moveTextViewForKeyboard:notification up:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self moveTextViewForKeyboard:notification up:NO];
}

- (void)moveTextViewForKeyboard:(NSNotification *)notification up:(BOOL)up {
    UIViewAnimationCurve animationCurve;

    [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey]getValue:&animationCurve];
    NSTimeInterval animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardRect = [self.view convertRect:[notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];

    _replyZone.contentInset = UIEdgeInsetsMake(64, 0, up?keyboardRect.size.height+44:0, 0);
    _replyZone.scrollIndicatorInsets = _replyZone.contentInset;
    
    [UIView commitAnimations];
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated {
    [self purgeDraftImages];
    [Settings hideHUD];
    [super dismissModalViewControllerAnimated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [_replyZone resignFirstResponder];
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [_replyZone becomeFirstResponder];
    [super viewWillAppear:animated];
}

- (void)deletePostedDraft {
    [Core.shared deleteDraft:_draft];
}

- (void)purgeDraftImages {
    NSString *imageDir = [[Settings documentsDirectory]stringByAppendingPathComponent:@"draft_images"];

    NSMutableArray *imagesToKeep = [NSMutableArray array];
    NSMutableArray *allFiles = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:imageDir error:nil].mutableCopy;
    
    for (Draft *draft in [Core.shared loadDrafts]) {
        
        NSString *imageName = draft.imagePath.lastPathComponent;

        if (imageName.length > 0) {
            [imagesToKeep addObject:imageName];
        }
    }
    
    [allFiles removeObjectsInArray:imagesToKeep];
    
    for (NSString *filename in allFiles) {
        NSString *file = [imageDir stringByAppendingPathComponent:filename];
        [[NSFileManager defaultManager]removeItemAtPath:file error:nil];
    }
}

- (void)saveDraft {
    [Core.shared saveDraft:_draft];
    self.isLoadedDraft = YES;
}

- (void)loadDraft:(NSNotification *)notif {
    NSMutableArray *newItems = _bar.items.mutableCopy;
    
    if ([newItems.lastObject customView]) {
        [newItems removeLastObject];
    }
    
    if ([newItems.lastObject width] == 5) {
        [newItems removeLastObject];
    }
    
    _bar.items = newItems;
    
    self.isLoadedDraft = YES;
    
    self.draft = notif.object;
    _replyZone.text = _draft.text;
    
    if (_draft.image) {
        [self addImageToolbarItems];
    }
    
    if (_replyZone.text.length == 0 && !_draft.image) {
        _navBar.topItem.rightBarButtonItem.enabled = NO;
    } else {
        _navBar.topItem.rightBarButtonItem.enabled = YES;
    }

    [self refreshCounter];
}

- (void)sendReply {
    if (_replyZone.text.length == 0 && _isFacebook) {
        return;
    }

    [_replyZone resignFirstResponder];
    
    if (_isFacebook) {
        [Settings showHUDWithTitle:@"Posting..."];
        
        NSMutableDictionary *params = @{ @"message": _replyZone.text }.mutableCopy;
        
        NSString *graphURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/%@",(_draft.to_id.length == 0)?@"me":_draft.to_id, (_draft.image != nil)?@"photos":@"feed"];
        
        if (_draft.image) {
            params[@"source"] = UIImagePNGRepresentation(_draft.image);
        }
        
        NSMutableURLRequest *request = [FHSFacebook.shared generateRequestWithURL:graphURL params:params HTTPMethod:@"POST"];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            [self dismissViewControllerAnimated:YES completion:nil];
            
            if (error) {
                qAlert(@"Status Update Error", (error.localizedDescription.length == 0)?@"Confirm that you are logged in correctly and try again.":error.localizedDescription);
                [self saveDraft];
            } else {
                [self deletePostedDraft];
            }
        }];
        
    } else {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        if (_draft.image) {
            [self scaleImageFromCameraRoll];
            [Settings showHUDWithTitle:@"Uploading..."];
            NSString *message = [_replyZone.text stringByTrimmingWhitespace];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool {
                    id returnValue = [[FHSTwitterEngine sharedEngine]uploadImageToTwitPic:UIImageJPEGRepresentation(_draft.image, 0.8) withMessage:message twitPicAPIKey:@"264b928f14482c7ad2ec20f35f3ead22"];
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            if ([returnValue isKindOfClass:[NSError class]]) {
                                [Settings hideHUD];
                                [_replyZone becomeFirstResponder];
                                qAlert(@"Image Upload Failed", [NSString stringWithFormat:@"%@",[(NSError *)returnValue localizedDescription]]);
                            } else if ([returnValue isKindOfClass:[NSDictionary class]]) {
                                NSString *link = ((NSDictionary *)returnValue)[@"url"];
                                _replyZone.text = [[_replyZone.text stringByTrimmingWhitespace]stringByAppendingFormat:@" %@",link];
                                self.isLoadedDraft = NO;
                                [self kickoffTweetPost];
                            }
                        }
                    });
                }
            });
        } else {
            [self kickoffTweetPost];
        }
    }
}

- (void)showDraftsBrowser {
    [_replyZone resignFirstResponder];
    
    void (^completionHandler)(NSUInteger, UIActionSheet *) = ^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if (buttonIndex == 0) {
            DraftsViewController *vc = [[DraftsViewController alloc]init];
            [self presentViewController:vc animated:YES completion:nil];
        } else if (buttonIndex == 1) {
            if (_isFacebook) {
                UserSelectorViewController *vc = [[UserSelectorViewController alloc]initWithIsFacebook:YES isImmediateSelection:YES];
                [self presentViewController:vc animated:YES completion:nil];
            } else {
                [_replyZone becomeFirstResponder];
            }
        } else {
            [_replyZone becomeFirstResponder];
        }
    };
    
    UIActionSheet *as = nil;
    
    if (_isFacebook) {
        as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:completionHandler cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Load Draft...", @"Post on Friend's Wall", nil];
    } else {
        as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:completionHandler cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Load Draft...", nil];
    }
    
    as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [as showInView:self.view];
}

- (void)close {
    [_replyZone resignFirstResponder];
    
    if (_isLoadedDraft && [Core.shared draftExists:_draft]) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }

    BOOL isJustMention = ([_replyZone.text componentsSeparatedByString:@" "].count == 1) && (_replyZone.text.length > 0)?[[_replyZone.text substringToIndex:1]isEqualToString:@"@"]:NO;
    
    if (any(_draft.image != nil, (_replyZone.text.length > 0 && !isJustMention))) {
        UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            if (buttonIndex == 1) {
                [self saveDraft];
                [self dismissViewControllerAnimated:YES completion:nil];
            } else if (buttonIndex == 0) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                [_replyZone becomeFirstResponder];
            }
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Save as Draft", nil];
        as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [as showInView:self.view];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)dealloc {
    [_replyZone removeObserver:self forKeyPath:@"text"];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
