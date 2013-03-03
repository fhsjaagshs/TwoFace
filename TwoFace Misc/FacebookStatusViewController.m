//
//  FacebookStatusViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 7/21/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "FacebookStatusViewController.h"

@implementation FacebookStatusViewController

@synthesize textView, pickedImage, bar, postButton, toID, navBar;

- (id)initWithAutoNib {
    self = [super initWithAutoNib];
    
    if (self) {
        [self.view setBackgroundColor:[UIColor whiteColor]];
    }
    
    return self;
}

- (IBAction)showImageSelector:(id)sender {
    [textView resignFirstResponder];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            
            if (buttonIndex == 0) {
                UIImagePickerController *imagePicker = [[UIImagePickerController alloc]init];
                [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
                imagePicker.delegate = self;
                [self presentModalViewController:imagePicker animated:YES];
            } else if (buttonIndex == 1) {
                UIImagePickerController *imagePicker = [[UIImagePickerController alloc]init];
                [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                imagePicker.delegate = self;
                [self presentModalViewController:imagePicker animated:YES];
            } else {
                [textView becomeFirstResponder];
            }
            
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose from Library...", nil];
        as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [as showInView:self.view];
    } else {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc]init];
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        imagePicker.delegate = self;
        [textView resignFirstResponder];
        [self presentModalViewController:imagePicker animated:YES];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (pickedImage) {
        [self clearImage];
    }
    pickedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    int size = 768;
    if ((pickedImage.size.width > size) && (pickedImage.size.height > size)) {
        float ratio = MIN(size/pickedImage.size.width, size/pickedImage.size.height);
        float width = ratio*pickedImage.size.width;
        float height = ratio*pickedImage.size.height;
        pickedImage = [pickedImage scaleToSize:CGSizeMake(width, height)];
    }
    
    [textView becomeFirstResponder];
    [self dismissModalViewControllerAnimated:YES];
    [self addImageToolbarItems];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissModalViewControllerAnimated:YES];
    [textView becomeFirstResponder];
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    [kAppDelegate hideHUD];
    [self dismissModalViewControllerAnimated:YES];
    NSString *FBerr = [error localizedDescription];
    NSString *message = (FBerr.length == 0 || !FBerr)?@"Confirm that you are logged in correctly and try again.":FBerr;
    qAlert(@"Status Update Error", message);
    [self saveDraft];
}

- (void)request:(FBRequest *)request didLoad:(id)result {
    [kAppDelegate hideHUD];
    [self dismissModalViewControllerAnimated:YES];
    [self deletePostedDraft];
    [self removeObservers];
}

- (IBAction)post {
    [textView resignFirstResponder];
    AppDelegate *ad = kAppDelegate;
    [ad showHUDWithTitle:@"Posting..."];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
    [params setObject:textView.text forKey:@"message"];
    
    if (pickedImage) {
        NSData *imagedata = UIImagePNGRepresentation(pickedImage);
        [params setObject:imagedata forKey:@"source"];
        
        if (toID.length == 0 || toID == nil) {
            [ad.facebook requestWithGraphPath:@"me/photos" andParams:params andHttpMethod:@"POST" andDelegate:self];
        } else {
            [ad.facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/photos",toID] andParams:params andHttpMethod:@"POST" andDelegate:self];
        }
        
    } else {
        if (toID.length == 0 || toID == nil) {
            [ad.facebook requestWithGraphPath:@"me/feed" andParams:params andHttpMethod:@"POST" andDelegate:self];
        } else {
            [ad.facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/feed",toID] andParams:params andHttpMethod:@"POST" andDelegate:self];
        }
    }
}

- (void)clearImage {
    pickedImage = nil;
    NSMutableArray *toolbarItems = [bar.items mutableCopy];
    
    for (UIBarButtonItem *item in [toolbarItems mutableCopy]) {
        if (item.customView != nil) {
            if ([toolbarItems containsObject:item]) {
                [toolbarItems removeObject:item];
            }
        } else if (item.width == 5) {
            if ([toolbarItems containsObject:item]) {
                [toolbarItems removeObject:item];
            }
        }
    }
    bar.items = toolbarItems;
}

- (void)imageTouched:(id)sender {
    
    [textView resignFirstResponder];
    
    UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if (buttonIndex == 1) {
            ImageDetailViewController *idvc = [[ImageDetailViewController alloc]initWithImage:pickedImage];
            idvc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            idvc.shouldShowSaveButton = NO;
            [self presentModalViewController:idvc animated:YES];
        } else {
            [textView becomeFirstResponder];
        }
        
        if (buttonIndex == 0) {
            [self clearImage];
        }
        
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Remove Image" otherButtonTitles:@"View Image...", nil];
    as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [as showInView:self.view];
}

- (void)addImageToolbarItems {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *imageToBeSet = [pickedImage scaleProportionallyToSize:CGSizeMake(36, 36)];
    [button setImage:imageToBeSet forState:UIControlStateNormal];
    button.frame = CGRectMake(274, 4, imageToBeSet.size.width, imageToBeSet.size.height);
    button.layer.cornerRadius = 5.0;
    button.layer.masksToBounds = YES;
    button.layer.borderColor = [UIColor darkGrayColor].CGColor;
    button.layer.borderWidth = 1.0;
    [button addTarget:self action:@selector(imageTouched:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *bbi = [[UIBarButtonItem alloc]initWithCustomView:button];

    NSMutableArray *newItems = [bar.items mutableCopy];
    [newItems addObject:[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [newItems addObject:bbi];
    bar.items = newItems;
}

- (void)viewWillAppear:(BOOL)animated {
    [textView becomeFirstResponder];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [textView resignFirstResponder];
    [super viewWillDisappear:animated];
}

- (void)textViewDidChange:(UITextView *)aTextView {
    if (textView.text.length == 0) {
        postButton.enabled = NO;
    } else {
        postButton.enabled = YES;
    }
}

- (void)saveToID:(NSNotification *)notif {
    toID = notif.object;
    NSString *firstName = [[(NSString *)[[kAppDelegate facebookFriendsDict] objectForKey:toID]componentsSeparatedByString:@" "]firstObjectA];
    navBar.topItem.title = [NSString stringWithFormat:@"To %@",firstName];
    [[UINavigationBar appearance]setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Arial-Bold" size:0.0], UITextAttributeFont, nil]];
}

- (void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(loadDraft:) name:@"draft" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(saveToID:) name:@"passFriendID" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [super viewDidLoad];
    textView.inputAccessoryView = bar;
    [textView becomeFirstResponder];
    [textView setDelegate:self];
    [self.view setBackgroundColor:[UIColor whiteColor]];

    if (is5()) {
        textView.frame = CGRectMake(0, 44, 320, self.view.frame.size.height-44-216-44);
    }
}

- (IBAction)showDraftsBrowser {
    
    [textView resignFirstResponder];
    
    UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        
        if (buttonIndex == 0) {
            DraftsViewController *vc = [[DraftsViewController alloc]initWithAutoNib];
            [self presentModalViewController:vc animated:YES];
        } else if (buttonIndex == 1) {
            FBUserSelectorForPostOnWallViewController *vc = [[FBUserSelectorForPostOnWallViewController alloc]initWithAutoNib];
            [self presentModalViewController:vc animated:YES];
        } else {
            [textView becomeFirstResponder];
        }
        
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Load Draft...", @"Post on Friend's Wall", nil];
    as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [as showInView:self.view];
}

- (void)keyboardWillShow:(NSNotification*)notification {
    [self moveTextViewForKeyboard:notification up:YES];
}

- (void)keyboardWillHide:(NSNotification*)notification {
    [self moveTextViewForKeyboard:notification up:NO];
}

- (void)moveTextViewForKeyboard:(NSNotification*)notification up:(BOOL)up {
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardRect;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    if (up == YES) {
        CGFloat keyboardTop = keyboardRect.origin.y;
        CGRect newTextViewFrame = textView.frame;
        originalTextViewFrame = textView.frame;
        newTextViewFrame.size.height = keyboardTop - textView.frame.origin.y-1.5;
        
        textView.frame = newTextViewFrame;
    } else {
        // Keyboard is going away (down) - restore original frame
        textView.frame = originalTextViewFrame;
    }
    
    [UIView commitAnimations];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"draft" object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"passFriendID" object:nil];
}

- (IBAction)close {
    
    [textView resignFirstResponder];
    
    if ((isLoadedDraft == YES) && ([kDraftsArray containsObject:loadedDraft])) {
        [self removeObservers];
        [self dismissModalViewControllerAnimated:YES];
        return;
    }
    
    BOOL hasImage = pickedImage != nil;
    BOOL hasText = !(textView.text.length == 0 || textView.text == nil);
    
    if ((hasImage && hasText) || (hasImage || hasText)) {
        UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            
            if (buttonIndex == 1) {
                [self saveDraft];
                [self removeObservers];
                [self dismissModalViewControllerAnimated:YES];
            } else if (buttonIndex == 0) {
                [self removeObservers];
                [self dismissModalViewControllerAnimated:YES];
            } else {
                [textView becomeFirstResponder];
            }
            
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Save as Draft", nil];
        as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [as showInView:self.view];
    } else {
        [self removeObservers];
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated {
    [self purgeDraftImages];
    [super dismissModalViewControllerAnimated:animated];
}

- (void)deletePostedDraft {
    NSMutableArray *drafts = kDraftsArray;
    [[NSFileManager defaultManager]removeItemAtPath:[loadedDraft objectForKey:@"imagePath"] error:nil];
    [drafts removeObject:loadedDraft];
    [drafts writeToFile:kDraftsPath atomically:YES];
}

- (void)purgeDraftImages {
    NSString *imageDir = [kDocumentsDirectory stringByAppendingPathComponent:@"draftImages"];
    NSMutableArray *drafts = kDraftsArray;
    
    NSMutableArray *imagesToKeep = [[NSMutableArray alloc]init];
    NSMutableArray *allFiles = [[NSMutableArray alloc]initWithArray:[[NSFileManager defaultManager]contentsOfDirectoryAtPath:imageDir error:nil]];
    
    for (NSDictionary *dict in drafts) {
        
        NSString *imageName = [[dict objectForKey:@"imagePath"]lastPathComponent];
        NSString *thumbnailImageName = [[dict objectForKey:@"thumbnailImagePath"]lastPathComponent];
        
        if (imageName != nil) {
            [imagesToKeep addObject:imageName];
        }
        
        if (thumbnailImageName != nil) {
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
        drafts = [[NSMutableArray alloc]init];
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    
    if (textView.text != nil) {
        [dict setObject:textView.text forKey:@"text"];
    }
    
    if (toID != nil) {
        [dict setObject:toID forKey:@"toID"];
    }
    
    if (pickedImage != nil) {
        
        NSString *filename = [NSString stringWithFormat:@"%lld.jpg",arc4random()%9999999999999999];
        
        NSString *path = [[kDocumentsDirectory stringByAppendingPathComponent:@"draftImages"]stringByAppendingPathComponent:filename];
        
        if (![[NSFileManager defaultManager]fileExistsAtPath:[kDocumentsDirectory stringByAppendingPathComponent:@"draftImages"] isDirectory:nil]) {
            [[NSFileManager defaultManager]createDirectoryAtPath:[kDocumentsDirectory stringByAppendingPathComponent:@"draftImages"] withIntermediateDirectories:NO attributes:nil error:nil];
        }
        
        do {
            filename = [NSString stringWithFormat:@"%lld.jpg",arc4random()%9999999999999999];
            path = [[kDocumentsDirectory stringByAppendingPathComponent:@"draftImages"]stringByAppendingPathComponent:filename];
        } while ([[NSFileManager defaultManager]fileExistsAtPath:path]);
        
        [UIImageJPEGRepresentation(pickedImage, 1.0) writeToFile:path atomically:YES];
        [dict setObject:path forKey:@"imagePath"];
        
        // Thumbnail
        NSString *thumbnailFilename = [path stringByReplacingOccurrencesOfString:@".jpg" withString:@"-thumbnail.jpg"];
        UIImage *thumbnail = [pickedImage thumbnailImageWithSideOfLength:35];
        
        [UIImageJPEGRepresentation(thumbnail, 1.0) writeToFile:thumbnailFilename atomically:YES];
        [dict setObject:thumbnailFilename forKey:@"thumbnailImagePath"];
    }
    
    id tweet = [loadedDraft objectForKey:@"tweet"];
    
    if (tweet != nil) {
        [dict setObject:tweet forKey:@"tweet"];
    }

    [dict setObject:[NSDate date] forKey:@"time"];
    
    [drafts addObject:dict];
    [drafts writeToFile:kDraftsPath atomically:YES];
}

- (void)loadDraft:(NSNotification *)notif {
    
    pickedImage = nil;
    NSMutableArray *newItems = [bar.items mutableCopy];
    
    if ([(UIBarButtonItem *)[newItems lastObject] customView] != nil) {
        [newItems removeLastObject];
    }
    
    if ([(UIBarButtonItem *)[newItems lastObject] width] == 5) {
        [newItems removeLastObject];
    }
    
    bar.items = newItems;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithDictionary:(NSDictionary *)notif.object];
    textView.text = [dict objectForKey:@"text"];
    
    if (textView.text.length == 0) {
        postButton.enabled = NO;
    } else {
        postButton.enabled = YES;
    }
    
    NSString *thetoID = [dict objectForKey:@"toID"];
    
    toID = nil;
    
    if (!(thetoID.length == 0 || thetoID == nil)) {
        toID = thetoID;
        NSString *firstName = [[(NSString *)[[kAppDelegate facebookFriendsDict]objectForKey:toID]componentsSeparatedByString:@" "]firstObjectA];
        navBar.topItem.title = [NSString stringWithFormat:@"To %@",firstName];
    }
    
    pickedImage = [UIImage imageWithContentsOfFile:[dict objectForKey:@"imagePath"]];

    if (pickedImage != nil) {
        [self addImageToolbarItems];
    }
    
    isLoadedDraft = YES;
    loadedDraft = dict;
}

@end
