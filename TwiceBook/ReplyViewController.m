//
//  Reply View Controller.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/6/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ReplyViewController.h"
#import "FHSTwitPicEngine.h"
#import "OAConsumer.h"

@implementation ReplyViewController

- (void)saveToID:(NSNotification *)notif {
    self.toID = notif.object;
    _navBar.topItem.title = [NSString stringWithFormat:@"To %@",[[(NSString *)[[kAppDelegate facebookFriendsDict]objectForKey:self.toID]componentsSeparatedByString:@" "]firstObjectA]];
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    [self dismissModalViewControllerAnimated:YES];
    qAlert(@"Status Update Error", (error.localizedDescription.length == 0)?@"Confirm that you are logged in correctly and try again.":error.localizedDescription);
    [self saveDraft];
}

- (void)request:(FBRequest *)request didLoad:(id)result {
    [self dismissModalViewControllerAnimated:YES];
    [self deletePostedDraft];
}

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Compose Tweet"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Post" style:UIBarButtonItemStyleDone target:self action:@selector(sendReply)];
    [self.navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:self.navBar];
    
    self.replyZone = [[UITextView alloc]initWithFrame:CGRectMake(0, self.navBar.frame.size.height, screenBounds.size.width, screenBounds.size.height-44)];
    self.replyZone.backgroundColor = [UIColor whiteColor];
    self.replyZone.editable = YES;
    self.replyZone.clipsToBounds = YES;
    self.replyZone.font = [UIFont systemFontOfSize:14];
    self.replyZone.delegate = self;
    self.replyZone.text = @"";
    [self.view addSubview:self.replyZone];
    [self.view bringSubviewToFront:self.navBar];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(loadDraft:) name:@"draft" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(saveToID:) name:@"passFriendID" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    self.bar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
    
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    space.width = 5;
    
    self.bar.items = [NSArray arrayWithObjects:[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(showImageSelector)], space, [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(showDraftsBrowser)], nil];
    
    if (!self.isFacebook) {
        self.charactersLeft = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 310, 44)];
        self.charactersLeft.font = [UIFont boldSystemFontOfSize:20];
        self.charactersLeft.textAlignment = UITextAlignmentRight;
        self.charactersLeft.textColor = [UIColor whiteColor];
        self.charactersLeft.backgroundColor = [UIColor clearColor];
        self.charactersLeft.shadowColor = [UIColor blackColor];
        self.charactersLeft.shadowOffset = CGSizeMake(0, -1);
        [self.bar addSubview:self.charactersLeft];
    }
    
    self.replyZone.inputAccessoryView = self.bar;

    if (self.tweet) {
        self.replyZone.text = [NSString stringWithFormat:@"@%@ ",_tweet.user.screename];
        self.navBar.topItem.title = @"Reply";
    }
    
    if (self.isFacebook) {
        self.navBar.topItem.title = @"Compose Status";
    }
    
    [self.replyZone becomeFirstResponder];
    [self refreshCounter];
}

- (void)scaleImageFromCameraRoll {
    if (self.imageFromCameraRoll.size.width > 768 && self.imageFromCameraRoll.size.height > 768) {
        float ratio = MIN(768/self.imageFromCameraRoll.size.width, 768/self.imageFromCameraRoll.size.height);
        self.imageFromCameraRoll = [self.imageFromCameraRoll scaleToSize:CGSizeMake(ratio*self.imageFromCameraRoll.size.width, ratio*self.imageFromCameraRoll.size.height)];
    }
}

- (void)kickoffTweetPost {
    AppDelegate *ad = kAppDelegate;
    NSString *messageBody = [self.replyZone.text stringByTrimmingWhitespace];
    [ad showHUDWithTitle:@"Tweeting..."];
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            NSError *error = nil;
            
            if (self.tweet) {
                error = [[FHSTwitterEngine sharedEngine]postTweet:messageBody inReplyTo:_tweet.identifier];
            } else {
                error = [[FHSTwitterEngine sharedEngine]postTweet:messageBody];
            }
            
            dispatch_sync(GCDMainThread, ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                [self dismissModalViewControllerAnimated:YES];
                
                if (error) {
                    qAlert([NSString stringWithFormat:@"Error %d",error.code], error.domain);
                    [self saveDraft];
                } else {
                    [self deletePostedDraft];
                }
            });
        }
    });
}

- (void)showImageSelector {
    [self.replyZone resignFirstResponder];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc]init];
            imagePicker.delegate = self;
            
            if (buttonIndex == 0) {
                [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
                [self presentModalViewController:imagePicker animated:YES];
            } else if (buttonIndex == 1) {
                [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                [self presentModalViewController:imagePicker animated:YES];
            } else {
                [self.replyZone becomeFirstResponder];
            }
            
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose from Library...", nil];
        as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [as showInView:self.view];
    } else {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc]init];
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        imagePicker.delegate = self;
        [self.replyZone resignFirstResponder];
        [self presentModalViewController:imagePicker animated:YES];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [self dismissModalViewControllerAnimated:YES];
    
    self.imageFromCameraRoll = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self scaleImageFromCameraRoll];
    
    NSMutableArray *toolbarItems = [self.bar.items mutableCopy];
    
    for (UIBarButtonItem *item in [toolbarItems mutableCopy]) {
        if (item.customView) {
            if ([toolbarItems containsObject:item]) {
                [toolbarItems removeObject:item];
            }
        }
    }
    self.bar.items = toolbarItems;
    
    [self addImageToolbarItems];
    [self.replyZone becomeFirstResponder];
}

- (void)imageTouched {
    
    [self.replyZone resignFirstResponder];
    
    UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if (buttonIndex == 1) {
            ImageDetailViewController *idvc = [[ImageDetailViewController alloc]initWithImage:self.imageFromCameraRoll];
            idvc.shouldShowSaveButton = NO;
            [self presentModalViewController:idvc animated:YES];
        } else {
            [self.replyZone becomeFirstResponder];
        }

        if (buttonIndex == 0) {
            self.imageFromCameraRoll = nil;

            NSMutableArray *toolbarItems = [self.bar.items mutableCopy];
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
    [self dismissModalViewControllerAnimated:YES];
    [self.replyZone becomeFirstResponder];
}

- (id)initWithTweet:(Tweet *)aTweet {
    self = [super init];
    if (self) {
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

    [[[notification userInfo]objectForKey:UIKeyboardAnimationCurveUserInfoKey]getValue:&animationCurve];
    NSTimeInterval animationDuration = [[[notification userInfo]objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardRect = [self.view convertRect:[[[notification userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue] fromView:nil];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    if (up) {
        CGRect newTextViewFrame = self.replyZone.frame;
        self.originalTextViewFrame = self.replyZone.frame;
        newTextViewFrame.size.height = keyboardRect.origin.y-self.replyZone.frame.origin.y;
        self.replyZone.frame = newTextViewFrame;
    } else {
        self.replyZone.frame = self.originalTextViewFrame;
    }
    
    [UIView commitAnimations];
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated {
    [self purgeDraftImages];
    [kAppDelegate hideHUD];
    [self removeObservers];
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
    NSMutableArray *drafts = kDraftsArray;
    
    if ([drafts containsObject:self.loadedDraft]) {
        [[NSFileManager defaultManager]removeItemAtPath:[self.loadedDraft objectForKey:@"thumbnailImagePath"] error:nil];
        [[NSFileManager defaultManager]removeItemAtPath:[self.loadedDraft objectForKey:@"imagePath"] error:nil];
        [drafts removeObject:self.loadedDraft];
        [drafts writeToFile:kDraftsPath atomically:YES];
    }
}

- (void)purgeDraftImages {
    NSString *imageDir = [kDocumentsDirectory stringByAppendingPathComponent:@"draftImages"];
    NSMutableArray *drafts = kDraftsArray;
    
    NSMutableArray *imagesToKeep = [NSMutableArray array];
    NSMutableArray *allFiles = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager]contentsOfDirectoryAtPath:imageDir error:nil]];
    
    for (NSDictionary *dict in drafts) {
        
        NSString *imageName = [[dict objectForKey:@"imagePath"]lastPathComponent];
        NSString *thumbnailImageName = [[dict objectForKey:@"thumbnailImagePath"]lastPathComponent];

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
    NSMutableArray *drafts = kDraftsArray;
    
    if (drafts == nil) {
        drafts = [NSMutableArray array];
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    
    NSString *thetoID = self.isFacebook?self.toID:[self.loadedDraft objectForKey:@"toID"];
    
    if (thetoID.length > 0) {
        [dict setObject:thetoID forKey:@"toID"];
    }
    
    if (self.replyZone.text.length > 0) {
        [dict setObject:self.replyZone.text forKey:@"text"];
    }
    
    if (self.imageFromCameraRoll) {
        NSString *filename = [NSString stringWithFormat:@"%lld.jpg",arc4random()%9999999999999999];
        NSString *path = [[kDocumentsDirectory stringByAppendingPathComponent:@"draftImages"]stringByAppendingPathComponent:filename];

        if (![[NSFileManager defaultManager]fileExistsAtPath:[kDocumentsDirectory stringByAppendingPathComponent:@"draftImages"] isDirectory:nil]) {
            [[NSFileManager defaultManager]createDirectoryAtPath:[kDocumentsDirectory stringByAppendingPathComponent:@"draftImages"] withIntermediateDirectories:NO attributes:nil error:nil];
        }
        
        do {
            filename = [NSString stringWithFormat:@"%lld.jpg",arc4random()%9999999999999999];
            path = [[kDocumentsDirectory stringByAppendingPathComponent:@"draftImages"]stringByAppendingPathComponent:filename];
        } while ([[NSFileManager defaultManager]fileExistsAtPath:path]);
        
        [UIImageJPEGRepresentation(self.imageFromCameraRoll, 1.0) writeToFile:path atomically:YES];
        [dict setObject:path forKey:@"imagePath"];
        
        // Thumbnail
        NSString *thumbnailFilename = [path stringByReplacingOccurrencesOfString:@".jpg" withString:@"-thumbnail.jpg"];
        UIImage *thumbnail = [self.imageFromCameraRoll thumbnailImageWithSideOfLength:35];
        
        [UIImageJPEGRepresentation(thumbnail, 1.0) writeToFile:thumbnailFilename atomically:YES];
        [dict setObject:thumbnailFilename forKey:@"thumbnailImagePath"];
    }
    
    if (self.tweet) {
        [dict setObject:self.tweet forKey:@"tweet"];
    }
    
    [dict setObject:[NSDate date] forKey:@"time"];
    
    [drafts addObject:dict];
    [drafts writeToFile:kDraftsPath atomically:YES];
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
    self.replyZone.text = [dict objectForKey:@"text"];
    
    self.imageFromCameraRoll = [UIImage imageWithContentsOfFile:[dict objectForKey:@"imagePath"]];
    self.tweet = [dict objectForKey:@"tweet"];
    self.toID = self.isFacebook?[dict objectForKey:@"toID"]:nil;
    
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
    if (self.replyZone.text.length == 0) {
        if (self.isFacebook) {
            return;
        }
    }
    
    AppDelegate *ad = kAppDelegate;
    [self.replyZone resignFirstResponder];
    
    if (self.isFacebook) {
        [ad showHUDWithTitle:@"Posting..."];
        
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params setObject:self.replyZone.text forKey:@"message"];
        
        if (self.imageFromCameraRoll) {
            [params setObject:UIImagePNGRepresentation(self.imageFromCameraRoll) forKey:@"source"];
            
            if (self.toID.length == 0) {
                [ad.facebook requestWithGraphPath:@"me/photos" andParams:params andHttpMethod:@"POST" andDelegate:self];
            } else {
                [ad.facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/photos",self.toID] andParams:params andHttpMethod:@"POST" andDelegate:self];
            }
            
        } else {
            if (self.toID.length == 0) {
                [ad.facebook requestWithGraphPath:@"me/feed" andParams:params andHttpMethod:@"POST" andDelegate:self];
            } else {
                [ad.facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/feed",self.toID] andParams:params andHttpMethod:@"POST" andDelegate:self];
            }
        }
    } else {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        if (self.imageFromCameraRoll) {
            [self scaleImageFromCameraRoll];
            [ad showHUDWithTitle:@"Uploading..."];
            NSString *message = [self.replyZone.text stringByTrimmingWhitespace];
            
            dispatch_async(GCDBackgroundThread, ^{
                @autoreleasepool {
                    id returnValue = [FHSTwitPicEngine uploadPictureToTwitPic:UIImageJPEGRepresentation(self.imageFromCameraRoll, 0.8) withMessage:message withConsumer:[[OAConsumer alloc]initWithKey:kOAuthConsumerKey secret:kOAuthConsumerSecret] accessToken:[[FHSTwitterEngine sharedEngine]accessToken] andTwitPicAPIKey:@"264b928f14482c7ad2ec20f35f3ead22"];
                    
                    dispatch_sync(GCDMainThread, ^{
                        @autoreleasepool {
                            if ([returnValue isKindOfClass:[NSError class]]) {
                                [ad hideHUD];
                                [self.replyZone becomeFirstResponder];
                                qAlert(@"Image Upload Failed", [NSString stringWithFormat:@"%@",[(NSError *)returnValue localizedDescription]]);
                            } else if ([returnValue isKindOfClass:[NSDictionary class]]) {
                                NSString *link = [(NSDictionary *)returnValue objectForKey:@"url"];
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
            [self presentModalViewController:vc animated:YES];
        } else if (buttonIndex == 1) {
            if (self.isFacebook) {
                UserSelectorViewController *vc = [[UserSelectorViewController alloc]initWithIsFacebook:YES isImmediateSelection:YES];
                [self presentModalViewController:vc animated:YES];
            } else {
                [self.replyZone becomeFirstResponder];
            }
        } else {
            [self.replyZone becomeFirstResponder];
        }
    };
    
    UIActionSheet *as = nil;
    
    if (self.isFacebook) {
        as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:completionHandler cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Load Draft...", @"Post on Friend's Wall", nil];
    } else {
        as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:completionHandler cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Load Draft...", nil];
    }
    
    as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [as showInView:self.view];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"draft" object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"passFriendID" object:nil];
}

- (void)close {
    [self.replyZone resignFirstResponder];
    
    if (self.isLoadedDraft && [kDraftsArray containsObject:self.loadedDraft]) {
        [self dismissModalViewControllerAnimated:YES];
        return;
    }

    BOOL isJustMention = ([self.replyZone.text componentsSeparatedByString:@" "].count == 1) && (self.replyZone.text.length > 0)?[[self.replyZone.text substringToIndex:1]isEqualToString:@"@"]:NO;
    
    if (oneIsCorrect(self.imageFromCameraRoll != nil, (self.replyZone.text.length > 0 && !isJustMention))) {
        UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            
            if (buttonIndex == 1) {
                [self saveDraft];
                [self dismissModalViewControllerAnimated:YES];
            } else if (buttonIndex == 0) {
                [self dismissModalViewControllerAnimated:YES];
            } else {
                [self.replyZone becomeFirstResponder];
            }
                             
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Save as Draft", nil];
        as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [as showInView:self.view];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

@end
