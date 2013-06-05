//
//  PostDetailViewController.m
//  TwoFace
//
//  Created by Nathaniel Symer on 7/10/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "PostDetailViewController.h"
#import "InterceptTwitPicLink.h"

#define bgViewPadding 33
#define messageViewYval 124
#define whereBGViewStarts 49
#define betweenMessageViewAndStartOfBGView 53

@implementation PostDetailViewController

- (void)loadView {
    [super loadView];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(openURL:) name:@"imageOpen" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(loadTheCommentsMethinks) name:@"commentsNotif" object:nil];
    
    NSString *posterName = _post.from.name;
    NSString *postBody = _post.message;
    NSString *imageURL = _post.pictureURL;
    NSString *linkURL = _post.link;
    NSString *type = _post.type;
    NSMutableArray *comments = _post.comments;
    NSString *toName = _post.to.name;
    
    BOOL hasActions = [_post.actionsAvailable isEqualToString:@"yes"];//[[self.post objectForKey:@"actions_available"]isEqualToString:@"yes"];
    BOOL hasImage = (imageURL.length > 0);
    BOOL hasLink = (linkURL.length > 0);
    BOOL isPhoto = [type isEqualToString:@"photo"];
    
    self.view = [[UIView alloc]initWithFrame:[[UIScreen mainScreen]applicationFrame]];
    self.view.backgroundColor = [UIColor underPageBackgroundColor];
    
    NSString *timestamp = [_post.createdAt timeElapsedSinceCurrentDate];
    NSString *title = [[type stringByCapitalizingFirstLetter]stringByAppendingFormat:@" - %@ ago",timestamp];
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    UINavigationItem *item = [[UINavigationItem alloc]initWithTitle:title];
    item.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(showReply)];
    item.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    
    [self.navBar pushNavigationItem:item animated:YES];
    
    [self.view addSubview:self.navBar];
    [self.view bringSubviewToFront:self.navBar];
    
    self.displayNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(14, 53, 292, 21)];
    self.displayNameLabel.textAlignment = UITextAlignmentCenter;
    self.displayNameLabel.font = [UIFont boldSystemFontOfSize:17];
    self.displayNameLabel.backgroundColor = [UIColor clearColor];
    self.displayNameLabel.text = (toName.length > 0)?[posterName stringByAppendingFormat:@" to %@",toName]:posterName;
    [self.view addSubview:self.displayNameLabel];
    [self.view bringSubviewToFront:self.displayNameLabel];
    
    self.theImageView = [[UIImageView alloc]initWithFrame:CGRectMake(218, 82, 92, 92)];
    self.theImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.theImageView.hidden = YES;
    self.theImageView.backgroundColor = [UIColor darkGrayColor];
    self.theImageView.layer.masksToBounds = YES;
    self.theImageView.layer.borderColor = [UIColor blackColor].CGColor;
    self.theImageView.layer.borderWidth = 1;
    self.theImageView.layer.cornerRadius = 5;
    [self.view addSubview:self.theImageView];
    [self.view bringSubviewToFront:self.theImageView];

    self.messageView = [[UITextView alloc]initWithFrame:CGRectMake(7, 82, (hasImage?214:307), 236)]; // 236 or (460-(44*3)-10-82)
    self.messageView.editable = NO;
    self.messageView.font = [UIFont systemFontOfSize:15];
    self.messageView.backgroundColor = [UIColor clearColor];
    self.messageView.dataDetectorTypes = UIDataDetectorTypeLink;
    self.messageView.scrollEnabled = YES;
    self.messageView.showsVerticalScrollIndicator = YES;
    self.messageView.text = postBody;
    [self.view addSubview:self.messageView];
    [self.view bringSubviewToFront:self.messageView];
    
    self.commentsTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 199, 320, 261)];
    self.commentsTableView.delegate = self;
    self.commentsTableView.dataSource = self;
    self.commentsTableView.separatorColor = [UIColor clearColor];
    UIView *bgView = [[UIView alloc]initWithFrame:self.commentsTableView.frame];
    self.commentsTableView.backgroundColor = [UIColor clearColor];
    bgView.backgroundColor = [UIColor clearColor];
    [self.commentsTableView setBackgroundView:bgView];
    [self.view addSubview:self.commentsTableView];
    [self.view bringSubviewToFront:self.commentsTableView];
    
    self.linkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.linkButton.frame = CGRectMake(215, 173, 95, 37);
    self.linkButton.titleLabel.font = [UIFont boldSystemFontOfSize:19];
    [self.linkButton setTitle:@"Visit Link" forState:UIControlStateNormal];
    self.linkButton.titleLabel.textColor = [UIColor colorWithRed:31.0f/255.0f green:102.0f/255.0f blue:146.0f/255.0f alpha:1.0f];
    [self.linkButton addTarget:self action:@selector(linkAction) forControlEvents:UIControlEventTouchUpInside];
    self.linkButton.hidden = YES;
    [self.view addSubview:self.linkButton];
    [self.view bringSubviewToFront:self.linkButton];
    
    if (!hasActions) {
        [self.navBar.topItem.rightBarButtonItem setEnabled:NO];
    }

    if (hasImage) {
        [_theImageView setHidden:NO];
        
        if (isPhoto) {
            [self loadImageURLMethinks];
        } else {
            [self getImageAtURL:imageURL];
        }
    }
    
    if (hasLink) {
        _linkButton.hidden = isPhoto;
        
        if (oneIsCorrect(postBody.length == 0, [postBody isEqualToString:linkURL])) {
            _messageView.text = [NSString stringWithFormat:@"%@ wants to share a %@ with you. %@.",posterName,type,isPhoto?@"Tap the preview on the right for a full-size image.":@"Please tap \"Visit Link\""];
        }
        
        if (!hasImage) {
            CGRect f = _linkButton.frame;
            _linkButton.frame = CGRectMake((f.origin.x/2), MIN(_messageView.contentSize.height, _messageView.frame.size.height)+124, f.size.width, f.size.height);
        }
    } else {
        _linkButton.hidden = YES;
    }
    
    self.aivy = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [_aivy setHidesWhenStopped:YES];
    _aivy.center = _commentsTableView.center;
    [self.view addSubview:_aivy];
    
    if (hasActions) {
        self.pull = [[PullToRefreshView alloc]initWithScrollView:self.commentsTableView];
        [_pull setDelegate:self];
        [_pull setSubtitleText:@"Comments"];
        [_pull setBackgroundColor:[UIColor clearColor]];
        [_commentsTableView addSubview:_pull];
    }
    
    if (comments.count == 0) {
        [self loadTheCommentsMethinks];
    }
    
    [self layoutViews];
    [self performSelector:@selector(setTitleText) withObject:nil afterDelay:1.0f];
}

- (void)adjustImageDimentions {
    
    if (![_post.type isEqualToString:@"photo"]) {
        if (oneIsCorrect(!_theImageView.image, _theImageView.hidden)) {
            return;
        }
    }

    float imgWidth = _theImageView.image.size.width;
    float imgHeight = _theImageView.image.size.height;
    
    float scaleFactor = MAX(imgHeight/_theImageView.frame.size.height,imgWidth/_theImageView.frame.size.width);

    float adjustByValueWidth = ((imgWidth/scaleFactor)-_theImageView.frame.size.width)/2; // subtract from the messageView's width.
    float adjustByValueHeight = ((imgHeight/scaleFactor)-_theImageView.frame.size.height)/2; // push the link button down by this much
    
    CGRect m = _messageView.frame;
    CGRect l = _linkButton.frame;
    CGRect i = _theImageView.frame;
    
    _messageView.frame = CGRectMake(m.origin.x, m.origin.y, _theImageView.frame.origin.x-8, m.size.height);
    _linkButton.frame = CGRectMake(l.origin.x, l.origin.y+adjustByValueHeight, l.size.width, l.size.height);
    _theImageView.frame = CGRectMake(i.origin.x-adjustByValueWidth, i.origin.y-(adjustByValueHeight/5), (imgWidth/scaleFactor), (imgHeight/scaleFactor));
}

- (CGRect)getTextRect {
    CGSize constrainedRect = CGSizeMake(_messageView.frame.size.width, MAXFLOAT);
    CGSize textSize = [_messageView.text sizeWithFont:_messageView.font constrainedToSize:constrainedRect lineBreakMode:UILineBreakModeWordWrap];
    return CGRectMake(_messageView.frame.origin.x, _messageView.frame.origin.y, textSize.width, textSize.height);
}

- (NSString *)imageInCachesDir {
    return [[Settings cachesDirectory]stringByAppendingPathComponent:[_post.identifier stringByAppendingString:@".png"]];
}

- (void)removeImageViewSpinner {
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[UIActivityIndicatorView class]]) {
            if (![view isEqual:_aivy]) {
                [view removeFromSuperview];
            }
        }
    }
}

- (void)loadImageURLMethinks {
    NSString *imageInCachesDir = [self imageInCachesDir];
    if ([[NSFileManager defaultManager]fileExistsAtPath:imageInCachesDir]) {
        [_theImageView setImage:[UIImage imageWithContentsOfFile:imageInCachesDir]];
        [self layoutViews];
        return;
    }
    
    if (![FHSTwitterEngine isConnectedToInternet]) {
        [self removeImageViewSpinner];
        UIImage *caution = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"Caution" ofType:@"png"]];
        [_theImageView setImage:caution];
        _theImageView.backgroundColor = [UIColor clearColor];
        _theImageView.layer.borderWidth = 0;
        [self layoutViews];
        return;
    }
    
    self.isLoadingImage = YES;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    aiv.center = _theImageView.center;
    [self.view addSubview:aiv];
    [self.view bringSubviewToFront:aiv];
    [aiv startAnimating];
    
    AppDelegate *ad = [Settings appDelegate];
    
    NSString *string = [NSString stringWithFormat:@"https://graph.facebook.com/%@/?&type=normal&access_token=%@", encodeForURL(_post.objectIdentifier),ad.facebook.accessToken];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:string]];
    [req setHTTPMethod:@"GET"];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        self.isLoadingComments = NO;
        
        if (![ad.facebook isPendingRequests]) {
            if (!_isLoadingImage) {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }
        }
        
        if (error) {
            [self removeImageViewSpinner];
            UIImage *caution = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"Caution" ofType:@"png"]];
            [_theImageView setImage:caution];
            _theImageView.backgroundColor = [UIColor clearColor];
            _theImageView.layer.borderWidth = 0;
            [self layoutViews];
        } else {
            id result = removeNull([NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);
            NSDictionary *resultDict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)result];
            NSArray *images = [resultDict objectForKey:@"images"];
            NSDictionary *imageContents = [NSDictionary dictionaryWithDictionary:(NSDictionary *)[images objectAtIndex:(images.count > 1)?1:0]];
            [self getImageAtURL:[imageContents objectForKey:@"source"]];
        }
    }];
}

- (void)loadTheCommentsMethinks {
    
    if ([_post.actionsAvailable isEqualToString:@"no"]) {
        return;
    }
    
    if (![FHSTwitterEngine isConnectedToInternet]) {
        [_pull finishedLoading];
        return;
    }

    if (_post.comments.count == 0) {
        [_aivy startAnimating];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.isLoadingComments = YES;
    
    AppDelegate *ad = [Settings appDelegate];
    
    NSString *string = [NSString stringWithFormat:@"https://graph.facebook.com/%@/comments?&access_token=%@", encodeForURL(_post.identifier),ad.facebook.accessToken];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:string]];
    [req setHTTPMethod:@"GET"];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        self.isLoadingComments = NO;
        
        if (![ad.facebook isPendingRequests]) {
            if (!self.isLoadingImage) {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }
        }
        
        if (!error) {
            NSMutableArray *timeline = [[Cache sharedCache]timeline];
            
            id result = removeNull([NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);
            
            NSArray *comments = [(NSDictionary *)result objectForKey:@"data"];
            
            NSMutableArray *parsedComments = [[NSMutableArray alloc]init];
            
            NSDateFormatter *df = [[NSDateFormatter alloc]init];
            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
            NSLocale *usLocale = [[NSLocale alloc]initWithLocaleIdentifier:@"en_US"];
            [df setLocale:usLocale];
            [df setDateStyle:NSDateFormatterLongStyle];
            [df setFormatterBehavior:NSDateFormatterBehavior10_4];
            
            for (NSDictionary *rawComment in comments) {
                
                NSMutableDictionary *comment = [[NSMutableDictionary alloc]init];
                
                NSString *postID = [rawComment objectForKey:@"id"];
                NSString *posterName = [[rawComment objectForKey:@"from"]objectForKey:@"name"];
                NSString *posterID = [[rawComment objectForKey:@"from"]objectForKey:@"id"];
                NSString *message = [rawComment objectForKey:@"message"];
                NSDate *created_time = [df dateFromString:[rawComment objectForKey:@"created_time"]];
                
                [comment setObject:created_time forKey:@"created_time"];
                [comment setObject:postID forKey:@"post_id"];
                [comment setObject:posterName forKey:@"poster_name"];
                [comment setObject:posterID forKey:@"poster_id"];
                [comment setObject:message forKey:@"message"];
                
                [parsedComments addObject:comment];
            }
            
            if (comments.count == 0) {
                NSMutableDictionary *dictionary = [[NSMutableDictionary alloc]init];
                [dictionary setValue:@" " forKey:@"poster_name"];
                [parsedComments addObject:dictionary];
            }
            
            if ([timeline containsObject:_post]) {
                int index = [timeline indexOfObject:_post];
                
                if (index < INT_MAX) {
                    _post.comments = parsedComments;
                    [[[Cache sharedCache]timeline]replaceObjectAtIndex:index withObject:_post];
                    [ad cacheTimeline];
                }
            }
            
            [_commentsTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self layoutViews];
            [_aivy stopAnimating];
        }
        [_pull finishedLoading];
    }];
}

- (void)getImageAtURL:(NSString *)imageURLz {
    
    NSString *cachepath = [self imageInCachesDir];
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:cachepath]) {
        NSData *data = [NSData dataWithContentsOfFile:cachepath];
        [_theImageView setImage:[UIImage imageWithData:data]];

        if (![[[Settings appDelegate]facebook]isPendingRequests]) {
            if (!_isLoadingComments) {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }
        }
        [self layoutViews];
    } else {
        _isLoadingImage = YES;
        [self removeImageViewSpinner];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        aiv.center = _theImageView.center;
        [self.view addSubview:aiv];
        [self.view bringSubviewToFront:aiv];
        [aiv startAnimating];
        
        NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURLz] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
        
        [NSURLConnection sendAsynchronousRequest:theRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            
            [self removeImageViewSpinner];
            
            if (error) {
                UIImage *caution = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"Caution" ofType:@"png"]];
                [_theImageView setImage:caution];
                _theImageView.backgroundColor = [UIColor clearColor];
                _theImageView.layer.borderWidth = 0;
            } else {
                NSString *savepath = [self imageInCachesDir];
                [data writeToFile:savepath atomically:NO];
                UIImage *image = [[UIImage alloc]initWithData:data];
                [_theImageView setImage:image];
            }

            _isLoadingImage = NO;
            
            if (![[[Settings appDelegate]facebook]isPendingRequests]) {
                if (!_isLoadingComments) {
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                }
            }
            [self layoutViews];
        }];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellText = [[_post.comments objectAtIndex:indexPath.row]objectForKey:@"message"];
    UIFont *cellFont = [UIFont fontWithName:@"Helvetica" size:17.0];
    CGSize constraintSize = CGSizeMake(300.0f, MAXFLOAT);
    CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
    return labelSize.height+35;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _post.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.textLabel.text = [[_post.comments objectAtIndex:indexPath.row]objectForKey:@"poster_name"];
    cell.detailTextLabel.text = [[_post.comments objectAtIndex:indexPath.row]objectForKey:@"message"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showReply {
    CommentViewController *cvc = [[CommentViewController alloc]initWithPostID:_post.identifier];
    [self presentModalViewController:cvc animated:YES];
}

- (void)close {
    [[[Settings appDelegate]facebook]cancelAllRequests];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self dismissModalViewControllerAnimated:YES];
}

- (id)initWithPost:(Status *)posty {
    self = [super init];
    if (self) {
        [self setPost:posty];
        [self.view setBackgroundColor:[UIColor underPageBackgroundColor]];
    }
    return self;
}

- (void)openURL:(NSNotification *)notif {
    
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            
            AppDelegate *ad = [Settings appDelegate];
            
            NSString *cachePath = [[Settings cachesDirectory]stringByAppendingPathComponent:[notif.object lastPathComponent]];
            NSData *imageDataD = [NSData dataWithContentsOfFile:cachePath];
            
            if (imageDataD.length == 0) {
                dispatch_sync(GCDMainThread, ^{
                    @autoreleasepool {
                        [[Settings appDelegate]showHUDWithTitle:@"Loading Image..."];
                    }
                });
                imageDataD = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[notif object]] returningResponse:nil error:nil];
            }
            
            if (imageDataD.length == 0) {
                dispatch_sync(GCDMainThread, ^{
                    @autoreleasepool {
                        [ad hideHUD];
                        [ad showSelfHidingHudWithTitle:@"Error Loading Image"];
                    }
                });
            } else {
                [imageDataD writeToFile:cachePath atomically:YES];
                dispatch_sync(GCDMainThread, ^{
                    @autoreleasepool {
                        [ad hideHUD];
                        ImageDetailViewController *vc = [[ImageDetailViewController alloc]initWithData:imageDataD];
                        vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                        [self presentModalViewController:vc animated:YES];
                    }
                });
            }
        }
    });
}

- (void)linkAction {
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:_post.link]];
}

- (void)showImageDetailViewer {
    if (!_isLoadingImage) {
        
        if (![[NSFileManager defaultManager]fileExistsAtPath:[self imageInCachesDir]]) {
            return;
        }
        
        ImageDetailViewController *idvc = [[ImageDetailViewController alloc]initWithImage:self.theImageView.image];
        idvc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:idvc animated:YES];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
    CGRect adjustedRect = CGRectMake(_theImageView.frame.origin.x-5, _theImageView.frame.origin.y-5, _theImageView.frame.size.width+10, _theImageView.frame.size.height+10);
    BOOL inImageView = CGRectContainsPoint(adjustedRect, touchPoint);
    if (inImageView) {
        for (UIView *view in self.theImageView.subviews) {
            if ([view isKindOfClass:[UIImageView class]]) {
                [view removeFromSuperview];
            }
        }
        
        BOOL isTooSmall = (_theImageView.frame.size.height > _theImageView.image.size.height) && (_theImageView.frame.size.width > _theImageView.image.size.width);
        
        if (isTooSmall) {
            return;
        }
        
        [self showImageDetailViewer];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
    CGRect adjustedRect = CGRectMake(_theImageView.frame.origin.x-5, _theImageView.frame.origin.y-5, _theImageView.frame.size.width+10, _theImageView.frame.size.height+10);
    if (!CGRectContainsPoint(adjustedRect, touchPoint)) {
        for (UIView *view in _theImageView.subviews) {
            if ([view isKindOfClass:[UIImageView class]]) {
                [view removeFromSuperview];
            }
        }
    } else {
        BOOL shouldOverlay = YES;
        
        for (UIView *view in _theImageView.subviews) {
            if ([view isKindOfClass:[UIImageView class]]) {
                shouldOverlay = NO;
            }
        }
        
        if (shouldOverlay) {
            if ((_theImageView.frame.size.height > _theImageView.image.size.height) && (_theImageView.frame.size.width > _theImageView.image.size.width)) {
                return;
            }
            
            UIImage *shadowNonStretchedImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"inner-shadow" ofType:@"png"]];
            UIImage *shadow = [shadowNonStretchedImage stretchableImageWithLeftCapWidth:0.0f topCapHeight:0.0f];
            UIImageView *overlayImageView = [[UIImageView alloc]initWithImage:shadow];
            overlayImageView.frame = _theImageView.bounds;
            [_theImageView addSubview:overlayImageView];
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if ((_theImageView.frame.size.height > _theImageView.image.size.height) && (_theImageView.frame.size.width > _theImageView.image.size.width)) {
        return;
    }
    
    if (CGRectContainsPoint(_theImageView.frame, [[touches anyObject]locationInView:self.view])) {
        UIImage *shadowNonStretchedImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"inner-shadow" ofType:@"png"]];
        UIImage *shadow = [shadowNonStretchedImage stretchableImageWithLeftCapWidth:0.0f topCapHeight:0.0f];
        UIImageView *overlayImageView = [[UIImageView alloc]initWithImage:shadow];
        overlayImageView.frame = _theImageView.bounds;
        [_theImageView addSubview:overlayImageView];
    }
}

- (CGRect)rectInTextView:(UITextView *)textView stringRange:(CFRange)stringRange {
    UITextPosition *begin = [textView positionFromPosition:textView.beginningOfDocument offset:stringRange.location];
    UITextPosition *end = [textView positionFromPosition:begin offset:stringRange.length];
    UITextRange *textRange = [textView textRangeFromPosition:begin toPosition:end];
    return [textView firstRectForRange:textRange];
}

- (CGRect)getBGViewRect {
    
    float mvContentHeight = (_messageView.frame.origin.y-49)+_messageView.contentSize.height-8;
    float mvFrameHeight = (_messageView.frame.origin.y-49)+_messageView.frame.size.height;
    float imgViewInBGViewHeight = (_theImageView.frame.origin.y-49)+_theImageView.frame.size.height;
    float lnkBtnInBGViewHeight = (_linkButton.frame.origin.y-49)+_linkButton.frame.size.height;

    float height = 0;

    if (!_linkButton.hidden) {
        if (lnkBtnInBGViewHeight > height) {
            height = lnkBtnInBGViewHeight;
        }
    }

    if (!_theImageView.hidden) {
        if (imgViewInBGViewHeight > height) {
            height = imgViewInBGViewHeight;
        }
    }
    
    float textHeight = mvFrameHeight;
    
    if (textHeight > mvContentHeight-8) {
        textHeight = mvContentHeight;
    }
    
    if (textHeight > height) {
        height = textHeight;
    }
    
    CGFloat maxHeight = 283;
    
    if (height > maxHeight) {
        height = maxHeight;
        _messageView.frame = CGRectMake(_messageView.frame.origin.x, _messageView.frame.origin.y, _messageView.frame.size.width, height-33);
    }
    
    height = height+5;
    
    return CGRectMake(5, 49, 310, height);
}

- (float)getTextHeight {
    return [_messageView.text sizeWithFont:_messageView.font constrainedToSize:CGSizeMake(_messageView.frame.size.width-50, 999.0f) lineBreakMode:UILineBreakModeTailTruncation].height+10;
}

- (void)layoutViews {
    
    NSString *type = _post.type;
    
    if (([type isEqualToString:@"photo"] || [type isEqualToString:@"link"]) && [[NSFileManager defaultManager]fileExistsAtPath:[self imageInCachesDir]]) {
        [self adjustImageDimentions];
    }
    
    CGRect bgviewFrame = [self getBGViewRect];
    
    if (!_gradientView) {
        self.gradientView = [[FHSGradientView alloc]init];
    }
    
    _gradientView.frame = bgviewFrame;
    
    if (!_gradientView.superview) {
        [self.view addSubview:_gradientView];
        [self.view sendSubviewToBack:_gradientView];
    }
    
    _commentsTableView.frame = CGRectMake(0, (bgviewFrame.size.height+49), 320, (self.view.frame.size.height-bgviewFrame.size.height-49));
    
    if (_messageView.frame.size.height < self.messageView.contentSize.height-8) {
        [_messageView flashScrollIndicators];
    }
    
    if (_commentsTableView.frame.size.height < _commentsTableView.contentSize.height-8) {
        [_commentsTableView flashScrollIndicators];
    }    
}
- (void)setTitleText {
    _navBar.topItem.title = [NSString stringWithFormat:@"%@ - %@ ago",[_post.type stringByCapitalizingFirstLetter],[_post.createdAt timeElapsedSinceCurrentDate]];
    [self performSelector:@selector(setTitleText) withObject:nil afterDelay:5.0f];
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    [self loadTheCommentsMethinks];
}

@end
