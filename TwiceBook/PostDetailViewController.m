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

@synthesize theImageView, linkButton, displayNameLabel, messageView, navBar, isLoadingImage, commentsTableView, post, isLoadingComments, gradientView, pull;

- (void)loadView {
    [super loadView];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(openURL:) name:@"imageOpen" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(loadTheCommentsMethinks) name:@"commentsNotif" object:nil];
    
    NSString *posterName = [self.post objectForKey:@"poster_name"];
    NSString *postBody = [[self.post objectForKey:@"message"]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *imageURL = [self.post objectForKey:@"image_url"];
    NSString *linkURL = [self.post objectForKey:@"link"];
    NSString *type = [self.post objectForKey:@"type"];
    NSArray *comments = [self.post objectForKey:@"comments"];
    NSString *toName = [self.post objectForKey:@"to_name"];
    
    BOOL hasActions = [[self.post objectForKey:@"actions_available"]isEqualToString:@"yes"];
    BOOL hasImage = (imageURL.length > 0);
    BOOL hasLink = (linkURL.length > 0);
    BOOL isPhoto = [type isEqualToString:@"photo"];
    
    self.view = [[UIView alloc]initWithFrame:[[UIScreen mainScreen]applicationFrame]];
    self.view.backgroundColor = [UIColor underPageBackgroundColor];
    
    NSString *timestamp = [[self.post objectForKey:@"poster_created_time"]timeElapsedSinceCurrentDate];
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
        [self.theImageView setHidden:NO];
        
        if (isPhoto) {
            [self loadImageURLMethinks];
        } else {
            [self getImageAtURL:imageURL];
        }
    }
    
    if (hasLink) {
        self.linkButton.hidden = isPhoto;
        
        if (oneIsCorrect(postBody.length == 0, [postBody isEqualToString:linkURL])) {
            NSString *message = [NSString stringWithFormat:@"%@ wants to share a %@ with you. %@.",posterName,type,isPhoto?@"Tap the preview on the right for a full-size image.":@"Please tap \"Visit Link\""];
            
            [self.messageView setText:message];
        }
        
        if (!hasImage) {
            CGRect f = self.linkButton.frame;
            self.linkButton.frame = CGRectMake((f.origin.x/2), MIN(self.messageView.contentSize.height, self.messageView.frame.size.height)+124, f.size.width, f.size.height);
        }
    } else {
        self.linkButton.hidden = YES;
    }
    
    aivy = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [aivy setHidesWhenStopped:YES];
    aivy.center = self.commentsTableView.center;
    [self.view addSubview:aivy];
    
    if (hasActions) {
        self.pull = [[PullToRefreshView alloc]initWithScrollView:self.commentsTableView];
        [self.pull setDelegate:self];
        [self.pull setSubtitleText:@"Comments"];
        [self.pull setBackgroundColor:[UIColor clearColor]];
        [self.commentsTableView addSubview:self.pull];
    }
    
    if (comments.count == 0) {
        [self loadTheCommentsMethinks];
    }
    
    [self layoutViews];
    [self performSelector:@selector(setTitleText) withObject:nil afterDelay:1.0f];
}

- (void)adjustImageDimentions {
    
    if (![[self.post objectForKey:@"type"]isEqualToString:@"photo"]) {
        if (oneIsCorrect(!self.theImageView.image, self.theImageView.hidden)) {
            return;
        }
    }

    float imgWidth = self.theImageView.image.size.width;
    float imgHeight = self.theImageView.image.size.height;
    
    float scaleFactor = MAX(imgHeight/self.theImageView.frame.size.height,imgWidth/self.theImageView.frame.size.width);

    float adjustByValueWidth = ((imgWidth/scaleFactor)-self.theImageView.frame.size.width)/2; // subtract from the messageView's width.
    float adjustByValueHeight = ((imgHeight/scaleFactor)-self.theImageView.frame.size.height)/2; // push the link button down by this much
    
    CGRect m = self.messageView.frame;
    CGRect l = self.linkButton.frame;
    CGRect i = self.theImageView.frame;
    
    self.messageView.frame = CGRectMake(m.origin.x, m.origin.y, self.theImageView.frame.origin.x-8, m.size.height);
    self.linkButton.frame = CGRectMake(l.origin.x, l.origin.y+adjustByValueHeight, l.size.width, l.size.height);
    self.theImageView.frame = CGRectMake(i.origin.x-adjustByValueWidth, i.origin.y-(adjustByValueHeight/5), (imgWidth/scaleFactor), (imgHeight/scaleFactor));
}

- (CGRect)getTextRect {
    CGSize constrainedRect = CGSizeMake(self.messageView.frame.size.width, MAXFLOAT);
    CGSize textSize = [self.messageView.text sizeWithFont:self.messageView.font constrainedToSize:constrainedRect lineBreakMode:UILineBreakModeWordWrap];
    return CGRectMake(self.messageView.frame.origin.x, self.messageView.frame.origin.y, textSize.width, textSize.height);
}

- (NSString *)imageInCachesDir {
    NSString *imageName = [[self.post objectForKey:@"id"]stringByAppendingString:@".png"];
    return [kCachesDirectory stringByAppendingPathComponent:imageName];
}

- (void)removeImageViewSpinner {
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[UIActivityIndicatorView class]]) {
            if (![view isEqual:aivy]) {
                [view removeFromSuperview];
            }
        }
    }
}

- (void)loadImageURLMethinks {
    if ([[NSFileManager defaultManager]fileExistsAtPath:[self imageInCachesDir]]) {
        [self.theImageView setImage:[UIImage imageWithContentsOfFile:[self imageInCachesDir]]];
        [self layoutViews];
        return;
    }
    
    if (![FHSTwitterEngine isConnectedToInternet]) {
        [self removeImageViewSpinner];
        UIImage *caution = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"Caution" ofType:@"png"]];
        [self.theImageView setImage:caution];
        self.theImageView.backgroundColor = [UIColor clearColor];
        self.theImageView.layer.borderWidth = 0;
        [self layoutViews];
        return;
    }
    
    self.isLoadingImage = YES;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    aiv.center = self.theImageView.center;
    [self.view addSubview:aiv];
    [self.view bringSubviewToFront:aiv];
    [aiv startAnimating];
    
    AppDelegate *ad = kAppDelegate;
    
    NSString *string = [NSString stringWithFormat:@"https://graph.facebook.com/%@/?&type=normal&access_token=%@", encodeForURL([self.post objectForKey:@"object_id"]),ad.facebook.accessToken];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:string]];
    
    [req setHTTPMethod:@"GET"];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        self.isLoadingComments = NO;
        
        if (![ad.facebook isPendingRequests]) {
            if (!self.isLoadingImage) {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }
        }
        
        if (error) {
            [self removeImageViewSpinner];
            UIImage *caution = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"Caution" ofType:@"png"]];
            [self.theImageView setImage:caution];
            self.theImageView.backgroundColor = [UIColor clearColor];
            self.theImageView.layer.borderWidth = 0;
            [self layoutViews];
        } else {
            id result = removeNull([NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);
            NSDictionary *resultDict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)result];
            NSArray *images = [resultDict objectForKey:@"images"];
            NSDictionary *imageContents = nil;
            if (images.count > 1) {
                imageContents = [NSDictionary dictionaryWithDictionary:(NSDictionary *)[images objectAtIndex:1]];
            } else {
                imageContents = [NSDictionary dictionaryWithDictionary:(NSDictionary *)[images objectAtIndex:0]];
            }
            
            [self getImageAtURL:[imageContents objectForKey:@"source"]];
        }
    }];
}

- (void)loadTheCommentsMethinks {
    
    BOOL hasActions = [[self.post objectForKey:@"actions_available"]isEqualToString:@"yes"];
    
    if (!hasActions) {
        return;
    }
    
    if (![FHSTwitterEngine isConnectedToInternet]) {
        [self.pull finishedLoading];
        return;
    }

    if ([(NSArray *)[self.post objectForKey:@"comments"]count] == 0) {
        [aivy startAnimating];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.isLoadingComments = YES;
    
    AppDelegate *ad = kAppDelegate;
    
    NSString *string = [NSString stringWithFormat:@"https://graph.facebook.com/%@/comments?&access_token=%@", encodeForURL([self.post objectForKey:@"id"]),ad.facebook.accessToken];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:string]];
    
    [req setHTTPMethod:@"GET"];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        self.isLoadingComments = NO;
        
        if (![ad.facebook isPendingRequests]) {
            if (!self.isLoadingImage) {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }
        }
        
        [self.pull finishedLoading];
        
        if (!error) {
            NSMutableArray *timeline = [ad.viewController timeline];
            
            id result = removeNull([NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);
            
            NSArray *comments = [(NSDictionary *)result objectForKey:@"data"];
            
            NSMutableArray *parsedComments = [[NSMutableArray alloc]init];
            
            for (NSDictionary *rawComment in comments) {
                NSMutableDictionary *comment = [[NSMutableDictionary alloc]init];
                
                NSString *postID = [rawComment objectForKey:@"id"];
                NSString *posterName = [[rawComment objectForKey:@"from"]objectForKey:@"name"];
                NSString *posterID = [[rawComment objectForKey:@"from"]objectForKey:@"id"];
                NSString *message = [rawComment objectForKey:@"message"];
                NSDate *created_time = [self getDateFromFacebookCreatedAt:[rawComment objectForKey:@"created_time"]];
                
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
            
            int index = [timeline indexOfObject:self.post];
            
            if (index < INT16_MAX) {
                [self.post setObject:parsedComments forKey:@"comments"];
                [ad.viewController.timeline replaceObjectAtIndex:index withObject:self.post];
                [ad cacheTimeline];
            }
            
            [self.commentsTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self layoutViews];
            [aivy stopAnimating];
        }
    }];
}

- (NSDate *)getDateFromFacebookCreatedAt:(NSString *)facebookDate {
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
    return [df dateFromString:facebookDate];
}

- (void)getImageAtURL:(NSString *)imageURLz {
    
    NSString *cachepath = [self imageInCachesDir];
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:cachepath]) {
        NSData *data = [NSData dataWithContentsOfFile:cachepath];
        [self.theImageView setImage:[UIImage imageWithData:data]];

        if (![[kAppDelegate facebook]isPendingRequests]) {
            if (!self.isLoadingComments) {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }
        }
        [self layoutViews];
    } else {
        self.isLoadingImage = YES;
        [self removeImageViewSpinner];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        aiv.center = self.theImageView.center;
        [self.view addSubview:aiv];
        [self.view bringSubviewToFront:aiv];
        [aiv startAnimating];
        
        NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURLz] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
        
        [NSURLConnection sendAsynchronousRequest:theRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            
            [self removeImageViewSpinner];
            
            if (error) {
                UIImage *caution = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"Caution" ofType:@"png"]];
                [self.theImageView setImage:caution];
                self.theImageView.backgroundColor = [UIColor clearColor];
                self.theImageView.layer.borderWidth = 0;
            } else {
                NSString *savepath = [self imageInCachesDir];
                [data writeToFile:savepath atomically:NO];
                UIImage *image = [[UIImage alloc]initWithData:data];
                [self.theImageView setImage:image];
            }

            self.isLoadingImage = NO;
            
            if (![[kAppDelegate facebook]isPendingRequests]) {
                if (!self.isLoadingComments) {
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
    NSString *cellText = [[[self.post objectForKey:@"comments"]objectAtIndex:indexPath.row]objectForKey:@"message"];
    UIFont *cellFont = [UIFont fontWithName:@"Helvetica" size:17.0];
    CGSize constraintSize = CGSizeMake(300.0f, MAXFLOAT);
    CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
    return labelSize.height+35;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.post objectForKey:@"comments"]count];
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
    
    cell.textLabel.text = [[[self.post objectForKey:@"comments"]objectAtIndex:indexPath.row]objectForKey:@"poster_name"];
    cell.detailTextLabel.text = [[[self.post objectForKey:@"comments"]objectAtIndex:indexPath.row]objectForKey:@"message"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showReply {
    CommentViewController *cvc = [[CommentViewController alloc]initWithPostID:[self.post objectForKey:@"id"]];
    [self presentModalViewController:cvc animated:YES];
}

- (void)close {
    [[kAppDelegate facebook]cancelAllRequests];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"imageOpen" object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"commentsNotif" object:nil];
    [self dismissModalViewControllerAnimated:YES];
}

- (id)initWithPost:(NSMutableDictionary *)posty {
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
            
            NSString *cachePath = [kCachesDirectory stringByAppendingPathComponent:[notif.object lastPathComponent]];
            
            NSData *imageDataD = [NSData dataWithContentsOfFile:cachePath];
            
            if (imageDataD.length == 0) {
                dispatch_sync(GCDMainThread, ^{
                    @autoreleasepool {
                        [kAppDelegate showHUDWithTitle:@"Loading Image..."];
                    }
                });
                imageDataD = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[notif object]] returningResponse:nil error:nil];
            }
            
            if (imageDataD.length == 0) {
                dispatch_sync(GCDMainThread, ^{
                    @autoreleasepool {
                        [kAppDelegate hideHUD];
                        [kAppDelegate showSelfHidingHudWithTitle:@"Error Loading Image"];
                    }
                });
            } else {
                [imageDataD writeToFile:cachePath atomically:YES];
                dispatch_sync(GCDMainThread, ^{
                    @autoreleasepool {
                        [kAppDelegate hideHUD];
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
    NSString *linkURL = [self.post objectForKey:@"link"];
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:linkURL]];
}

- (void)showImageDetailViewer {
    if (!self.isLoadingImage) {
        
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
    CGRect adjustedRect = CGRectMake(self.theImageView.frame.origin.x-5, self.theImageView.frame.origin.y-5, self.theImageView.frame.size.width+10, self.theImageView.frame.size.height+10);
    BOOL inImageView = CGRectContainsPoint(adjustedRect, touchPoint);
    if (inImageView) {
        for (UIView *view in self.theImageView.subviews) {
            if ([view isKindOfClass:[UIImageView class]]) {
                [view removeFromSuperview];
            }
        }
        
        BOOL isTooSmall = (self.theImageView.frame.size.height > self.theImageView.image.size.height) && (self.theImageView.frame.size.width > self.theImageView.image.size.width);
        
        if (isTooSmall) {
            return;
        }
        
        [self showImageDetailViewer];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
    CGRect adjustedRect = CGRectMake(self.theImageView.frame.origin.x-5, self.theImageView.frame.origin.y-5, self.theImageView.frame.size.width+10, self.theImageView.frame.size.height+10);
    if (!CGRectContainsPoint(adjustedRect, touchPoint)) {
        for (UIView *view in self.theImageView.subviews) {
            if ([view isKindOfClass:[UIImageView class]]) {
                [view removeFromSuperview];
            }
        }
    } else {
        BOOL shouldOverlay = YES;
        
        for (UIView *view in self.theImageView.subviews) {
            if ([view isKindOfClass:[UIImageView class]]) {
                shouldOverlay = NO;
            }
        }
        
        if (shouldOverlay) {
            if ((self.theImageView.frame.size.height > self.theImageView.image.size.height) && (self.theImageView.frame.size.width > self.theImageView.image.size.width)) {
                return;
            }
            
            UIImage *shadowNonStretchedImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"inner-shadow" ofType:@"png"]];
            UIImage *shadow = [shadowNonStretchedImage stretchableImageWithLeftCapWidth:0.0f topCapHeight:0.0f];
            UIImageView *overlayImageView = [[UIImageView alloc]initWithImage:shadow];
            overlayImageView.frame = self.theImageView.bounds;
            [self.theImageView addSubview:overlayImageView];
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if ((self.theImageView.frame.size.height > self.theImageView.image.size.height) && (self.theImageView.frame.size.width > self.theImageView.image.size.width)) {
        return;
    }
    
    if (CGRectContainsPoint(self.theImageView.frame, [[touches anyObject]locationInView:self.view])) {
        UIImage *shadowNonStretchedImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"inner-shadow" ofType:@"png"]];
        UIImage *shadow = [shadowNonStretchedImage stretchableImageWithLeftCapWidth:0.0f topCapHeight:0.0f];
        UIImageView *overlayImageView = [[UIImageView alloc]initWithImage:shadow];
        overlayImageView.frame = self.theImageView.bounds;
        [self.theImageView addSubview:overlayImageView];
    }
}

- (CGRect)rectInTextView:(UITextView *)textView stringRange:(CFRange)stringRange {
    UITextPosition *begin = [textView positionFromPosition:textView.beginningOfDocument offset:stringRange.location];
    UITextPosition *end = [textView positionFromPosition:begin offset:stringRange.length];
    UITextRange *textRange = [textView textRangeFromPosition:begin toPosition:end];
    return [textView firstRectForRange:textRange];
}

- (CGRect)getBGViewRect {
    
    float mvContentHeight = (self.messageView.frame.origin.y-49)+self.messageView.contentSize.height-8;
    float mvFrameHeight = (self.messageView.frame.origin.y-49)+self.messageView.frame.size.height;
    float imgViewInBGViewHeight = (self.theImageView.frame.origin.y-49)+self.theImageView.frame.size.height;
    float lnkBtnInBGViewHeight = (self.linkButton.frame.origin.y-49)+self.linkButton.frame.size.height;

    float height = 0;

    if (self.linkButton.hidden == NO) {
        if (lnkBtnInBGViewHeight > height) {
            height = lnkBtnInBGViewHeight;
        }
    }

    if (self.theImageView.hidden == NO) {
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
        self.messageView.frame = CGRectMake(self.messageView.frame.origin.x, self.messageView.frame.origin.y, self.messageView.frame.size.width, height-33);
    }
    
    height = height+5;
    
    return CGRectMake(5, 49, 310, height);
}

- (float)getTextHeight {
    return [self.messageView.text sizeWithFont:self.messageView.font constrainedToSize:CGSizeMake(self.messageView.frame.size.width-50, 999.0f) lineBreakMode:UILineBreakModeTailTruncation].height+10;
}

- (void)layoutViews {
    
    NSString *type = (NSString *)[self.post objectForKey:@"type"];
    
    if (([type isEqualToString:@"photo"] || [type isEqualToString:@"link"]) && [[NSFileManager defaultManager]fileExistsAtPath:[self imageInCachesDir]]) {
        [self adjustImageDimentions];
    }
    
    CGRect bgviewFrame = [self getBGViewRect];
    
    if (self.gradientView == nil) {
        self.gradientView = [[FHSGradientView alloc]init];
    }
    
    self.gradientView.frame = bgviewFrame;
    
    if (!self.gradientView.superview) {
        [self.view addSubview:self.gradientView];
        [self.view sendSubviewToBack:self.gradientView];
    }
    
    self.commentsTableView.frame = CGRectMake(0, (bgviewFrame.size.height+49), 320, (self.view.frame.size.height-bgviewFrame.size.height-49));
    
    if (self.messageView.frame.size.height < self.messageView.contentSize.height-8) {
        [self.messageView flashScrollIndicators];
    }
    
    if (self.commentsTableView.frame.size.height < self.commentsTableView.contentSize.height-8) {
        [self.commentsTableView flashScrollIndicators];
    }    
}
- (void)setTitleText {
    NSString *type = [self.post objectForKey:@"type"];
    NSString *timestamp = [[self.post objectForKey:@"poster_created_time"]timeElapsedSinceCurrentDate];
    self.navBar.topItem.title = [NSString stringWithFormat:@"%@ - %@ ago",[type stringByCapitalizingFirstLetter],timestamp];
    [self performSelector:@selector(setTitleText) withObject:nil afterDelay:5.0f];
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    [self loadTheCommentsMethinks];
}

@end
