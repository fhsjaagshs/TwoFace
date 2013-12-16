//
//  Reply View Controller.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/6/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ReplyViewController.h"
#import "FHSTwitterEngine.h"

@implementation ReplyViewController

- (void)saveToID:(NSNotification *)notif {
    self.toID = notif.object;
    _navBar.topItem.title = [NSString stringWithFormat:@"To %@",[[[Cache.shared nameForFacebookID:_toID]componentsSeparatedByString:@" "]firstObject]];
}

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]bounds];

    self.replyZone = [[UITextView alloc]initWithFrame:screenBounds];
    _replyZone.backgroundColor = [UIColor whiteColor];
    _replyZone.editable = YES;
    _replyZone.clipsToBounds = NO;
    _replyZone.font = [UIFont systemFontOfSize:14];
    _replyZone.delegate = self;
    _replyZone.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _replyZone.scrollIndicatorInsets = _replyZone.contentInset;
    [self.view addSubview:_replyZone];
    
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Compose Tweet"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Post" style:UIBarButtonItemStyleDone target:self action:@selector(sendReply)];
    [_navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:_navBar];

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(loadDraft:) name:@"draft" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(saveToID:) name:@"passFriendID" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
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
        
        _navBar.topItem.title = @"Compose Status";
    }
    
    _replyZone.inputAccessoryView = _bar;

    if (_tweet) {
        _replyZone.text = [NSString stringWithFormat:@"@%@ ",_tweet.user.screename];
        _navBar.topItem.title = @"Reply";
    }
    
    [_replyZone becomeFirstResponder];
    [self refreshCounter];
}

- (void)scaleImageFromCameraRoll {
    if (_imageFromCameraRoll.size.width > 768 && _imageFromCameraRoll.size.height > 768) {
        float ratio = MIN(768/_imageFromCameraRoll.size.width, 768/_imageFromCameraRoll.size.height);
        _imageFromCameraRoll = [_imageFromCameraRoll scaleToSize:CGSizeMake(ratio*_imageFromCameraRoll.size.width, ratio*_imageFromCameraRoll.size.height)];
    }
}

- (void)kickoffTweetPost {
    [Settings showHUDWithTitle:@"Tweeting..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            id ret = nil;
            
            if (_tweet) {
                ret = [[FHSTwitterEngine sharedEngine]postTweet:_replyZone.text.stringByTrimmingWhitespace inReplyTo:_tweet.identifier];
            } else {
                ret = [[FHSTwitterEngine sharedEngine]postTweet:_replyZone.text.stringByTrimmingWhitespace];
            }
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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
        [self.replyZone resignFirstResponder];
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];

    self.imageFromCameraRoll = info[UIImagePickerControllerOriginalImage];
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
    [self.replyZone resignFirstResponder];
    
    UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if (buttonIndex == 1) {
            ImageDetailViewController *idvc = [[ImageDetailViewController alloc]initWithImage:self.imageFromCameraRoll];
            idvc.shouldShowSaveButton = NO;
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.replyZone becomeFirstResponder];
        }

        if (buttonIndex == 0) {
            self.imageFromCameraRoll = nil;

            NSMutableArray *toolbarItems = _bar.items.mutableCopy;
            [toolbarItems removeLastObject];
            [toolbarItems removeLastObject];
            self.bar.items = toolbarItems;
            
            self.isLoadedDraft = NO;
        }
        
        [self refreshCounter];
        
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Remove Image" otherButtonTitles:@"View Image...", nil];
    as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [as showInView:self.view];
}

- (void)addImageToolbarItems {
    self.isLoadedDraft = NO;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *imageToBeSet = [self.imageFromCameraRoll scaleProportionallyToSize:CGSizeMake(36, 36)];
    [button setImage:imageToBeSet forState:UIControlStateNormal];
    button.frame = CGRectMake(274, 4, imageToBeSet.size.width, imageToBeSet.size.height);
    button.layer.cornerRadius = 5.0;
    button.layer.masksToBounds = YES;
    button.layer.borderColor = [UIColor darkGrayColor].CGColor;
    button.layer.borderWidth = 1.0;
    [button addTarget:self action:@selector(imageTouched) forControlEvents:UIControlEventTouchUpInside];

    NSMutableArray *newItems = [self.bar.items mutableCopy];
    
    UIBarButtonItem *bbiz = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    bbiz.width = 5;
    
    [newItems addObject:bbiz];
    [newItems addObject:[[UIBarButtonItem alloc]initWithCustomView:button]];
    self.bar.items = newItems;
    [self refreshCounter];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self.replyZone becomeFirstResponder];
}

- (instancetype)initWithToID:(NSString *)toId {
    self = [super init];
    if (self) {
        self.toID = toId;
        self.isFacebook = YES;
    }
    return self;
}

- (id)initWithTweet:(Tweet *)aTweet {
    self = [super init];
    if (self) {
        self.isFacebook = NO;
        self.tweet = aTweet;
    }
    return self;
}

- (void)refreshCounter {
    int charsLeft = 140-(self.imageFromCameraRoll?self.replyZone.text.length+20:self.replyZone.text.length);
    
    self.charactersLeft.text = [NSString stringWithFormat:@"%d",charsLeft];
    
    if (charsLeft < 0) {
        self.charactersLeft.textColor = [UIColor redColor];
        self.navBar.topItem.rightBarButtonItem.enabled = NO;
    } else if (charsLeft == 140) {
        self.navBar.topItem.rightBarButtonItem.enabled = NO;
    } else {
        self.charactersLeft.textColor = [UIColor whiteColor];
        self.navBar.topItem.rightBarButtonItem.enabled = YES;
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    [self refreshCounter];
    self.isLoadedDraft = NO;
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
    NSTimeInterval animationDuration = [[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardRect = [self.view convertRect:[[notification userInfo][UIKeyboardFrameEndUserInfoKey]CGRectValue] fromView:nil];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];

    _replyZone.contentInset = UIEdgeInsetsMake(64, 0, up?keyboardRect.size.height:0, 0);
    _replyZone.scrollIndicatorInsets = _replyZone.contentInset;
    
    [UIView commitAnimations];
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated {
    [self purgeDraftImages];
    [Settings hideHUD];
    [super dismissModalViewControllerAnimated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.replyZone resignFirstResponder];
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.replyZone becomeFirstResponder];
    [super viewWillAppear:animated];
}

- (void)deletePostedDraft {
    NSMutableArray *drafts = [Settings drafts];
    
    if ([drafts containsObject:_loadedDraft]) {
        [[NSFileManager defaultManager]removeItemAtPath:_loadedDraft[@"thumbnailImagePath"] error:nil];
        [[NSFileManager defaultManager]removeItemAtPath:_loadedDraft[@"imagePath"] error:nil];
        [drafts removeObject:_loadedDraft];
        [drafts writeToFile:[Settings draftsPath] atomically:YES];
    }
}

- (void)purgeDraftImages {
    NSString *imageDir = [[Settings documentsDirectory]stringByAppendingPathComponent:@"draftImages"];
    NSMutableArray *drafts = [Settings drafts];
    
    NSMutableArray *imagesToKeep = [NSMutableArray array];
    NSMutableArray *allFiles = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager]contentsOfDirectoryAtPath:imageDir error:nil]];
    
    for (NSDictionary *dict in drafts) {
        
        NSString *imageName = [dict[@"imagePath"]lastPathComponent];
        NSString *thumbnailImageName = [dict[@"thumbnailImagePath"]lastPathComponent];

        if (imageName.length > 0) {
            [imagesToKeep addObject:imageName];
        }
        
        if (thumbnailImageName.length > 0) {
            [imagesToKeep addObject:thumbnailImageName];
        }
    }
    
    [allFiles removeObjectsInArray:imagesToKeep];
    
    for (NSString *filename in allFiles) {
        NSString *file = [imageDir stringByAppendingPathComponent:filename];
        [[NSFileManager defaultManager]removeItemAtPath:file error:nil];
    }
}

- (void)saveDraft {
    NSMutableArray *drafts = [Settings drafts];
    
    if (drafts == nil) {
        drafts = [NSMutableArray array];
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    
    NSString *thetoID = _isFacebook?_toID:_loadedDraft[@"toID"];
    
    if (thetoID.length > 0) {
        dict[@"toID"] = thetoID;
    }
    
    if (_replyZone.text.length > 0) {
        dict[@"text"] = _replyZone.text;
    }
    
    if (self.imageFromCameraRoll) {
        NSString *filename = [NSString stringWithFormat:@"%lld.jpg",arc4random()%9999999999999999];
        NSString *path = [[[Settings documentsDirectory]stringByAppendingPathComponent:@"draftImages"]stringByAppendingPathComponent:filename];

        if (![[NSFileManager defaultManager]fileExistsAtPath:[[Settings documentsDirectory]stringByAppendingPathComponent:@"draftImages"] isDirectory:nil]) {
            [[NSFileManager defaultManager]createDirectoryAtPath:[[Settings documentsDirectory]stringByAppendingPathComponent:@"draftImages"] withIntermediateDirectories:NO attributes:nil error:nil];
        }
        
        do {
            filename = [NSString stringWithFormat:@"%lld.jpg",arc4random()%9999999999999999];
            path = [[[Settings documentsDirectory]stringByAppendingPathComponent:@"draftImages"]stringByAppendingPathComponent:filename];
        } while ([[NSFileManager defaultManager]fileExistsAtPath:path]);
        
        [UIImageJPEGRepresentation(self.imageFromCameraRoll, 1.0) writeToFile:path atomically:YES];
        dict[@"imagePath"] = path;
        
        // Thumbnail
        NSString *thumbnailFilename = [path stringByReplacingOccurrencesOfString:@".jpg" withString:@"-thumbnail.jpg"];
        UIImage *thumbnail = [self.imageFromCameraRoll thumbnailImageWithSideOfLength:35];
        
        [UIImageJPEGRepresentation(thumbnail, 1.0) writeToFile:thumbnailFilename atomically:YES];
        dict[@"thumbnailImagePath"] = thumbnailFilename;
    }
    
    if (self.tweet) {
        dict[@"tweet"] = self.tweet;
    }
    
    dict[@"time"] = [NSDate date];
    
    [drafts addObject:dict];
    [drafts writeToFile:[Settings draftsPath] atomically:YES];
}

- (void)loadDraft:(NSNotification *)notif {
    
    self.imageFromCameraRoll = nil;
    NSMutableArray *newItems = [self.bar.items mutableCopy];
    
    if ([(UIBarButtonItem *)[newItems lastObject]customView]) {
        [newItems removeLastObject];
    }
    
    if ([(UIBarButtonItem *)[newItems lastObject]width] == 5) {
        [newItems removeLastObject];
    }
    
    self.bar.items = newItems;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithDictionary:(NSDictionary *)notif.object];
    self.replyZone.text = dict[@"text"];
    
    self.imageFromCameraRoll = [UIImage imageWithContentsOfFile:dict[@"imagePath"]];
    self.tweet = dict[@"tweet"];
    self.toID = self.isFacebook?dict[@"toID"]:nil;
    
    if (self.imageFromCameraRoll) {
        [self addImageToolbarItems];
    }
    
    if (self.replyZone.text.length == 0 && !self.imageFromCameraRoll) {
        self.navBar.topItem.rightBarButtonItem.enabled = NO;
    } else {
        self.navBar.topItem.rightBarButtonItem.enabled = YES;
    }
    
    self.isLoadedDraft = YES;
    self.loadedDraft = dict;
    [self refreshCounter];
}

- (void)sendReply {
    if (_replyZone.text.length == 0 && _isFacebook) {
        return;
    }

    [_replyZone resignFirstResponder];
    
    if (_isFacebook) {
        [Settings showHUDWithTitle:@"Posting..."];
        
        NSMutableDictionary *params = @{ @"message":_replyZone.text }.mutableCopy;
        
        NSString *graphURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/%@",(_toID.length == 0)?@"me":_toID, (_imageFromCameraRoll != nil)?@"photos":@"feed"];
        
        if (_imageFromCameraRoll) {
            params[@"source"] = UIImagePNGRepresentation(_imageFromCameraRoll);
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
        
        if (self.imageFromCameraRoll) {
            [self scaleImageFromCameraRoll];
            [Settings showHUDWithTitle:@"Uploading..."];
            NSString *message = [self.replyZone.text stringByTrimmingWhitespace];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool {
                    id returnValue = [[FHSTwitterEngine sharedEngine]uploadImageToTwitPic:UIImageJPEGRepresentation(self.imageFromCameraRoll, 0.8) withMessage:message twitPicAPIKey:@"264b928f14482c7ad2ec20f35f3ead22"];
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            if ([returnValue isKindOfClass:[NSError class]]) {
                                [Settings hideHUD];
                                [self.replyZone becomeFirstResponder];
                                qAlert(@"Image Upload Failed", [NSString stringWithFormat:@"%@",[(NSError *)returnValue localizedDescription]]);
                            } else if ([returnValue isKindOfClass:[NSDictionary class]]) {
                                NSString *link = ((NSDictionary *)returnValue)[@"url"];
                                self.replyZone.text = [[self.replyZone.text stringByTrimmingWhitespace]stringByAppendingFormat:@" %@",link];
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
    [self.replyZone resignFirstResponder];
    
    void (^completionHandler)(NSUInteger, UIActionSheet *) = ^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        
        if (buttonIndex == 0) {
            DraftsViewController *vc = [[DraftsViewController alloc]init];
            [self presentViewController:vc animated:YES completion:nil];
        } else if (buttonIndex == 1) {
            if (self.isFacebook) {
                UserSelectorViewController *vc = [[UserSelectorViewController alloc]initWithIsFacebook:YES isImmediateSelection:YES];
                [self presentViewController:vc animated:YES completion:nil];
            } else {
                [self.replyZone becomeFirstResponder];
            }
        } else {
            [self.replyZone becomeFirstResponder];
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
    
    if (_isLoadedDraft && [[Settings drafts]containsObject:_loadedDraft]) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }

    BOOL isJustMention = ([self.replyZone.text componentsSeparatedByString:@" "].count == 1) && (self.replyZone.text.length > 0)?[[self.replyZone.text substringToIndex:1]isEqualToString:@"@"]:NO;
    
    if (any(_imageFromCameraRoll != nil, (_replyZone.text.length > 0 && !isJustMention))) {
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
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
