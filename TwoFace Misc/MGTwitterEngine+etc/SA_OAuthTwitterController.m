//
//  SA_OAuthTwitterController.m
//
//  Created by Ben Gottlieb on 24 July 2009.
//  Copyright 2009 Stand Alone, Inc.
//
//  Some code and concepts taken from examples provided by 
//  Matt Gemmell, Chris Kimpton, and Isaiah Carew
//  See ReadMe for further attributions, copyrights and license info.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "SA_OAuthTwitterEngine.h"
#import "SA_OAuthTwitterController.h"

@interface SA_OAuthTwitterController ()
@property (weak, weak, nonatomic, readonly) UIToolbar *pinCopyPromptBar;
@property (nonatomic, readwrite) UIInterfaceOrientation orientation;

- (id)initWithEngine:(SA_OAuthTwitterEngine *)engine andOrientation:(UIInterfaceOrientation)theOrientation;
- (NSString *)locateAuthPinInWebView:(UIWebView *)webView;

- (void)showPinCopyPrompt;
- (void)removePinCopyPrompt;
- (void)gotPin:(NSString *)pin;
@end


@interface DummyClassForProvidingSetDataDetectorTypesMethod
- (void)setDataDetectorTypes:(int)types;
- (void)setDetectsPhoneNumbers:(BOOL)detects;
@end


@interface NSString (TwitterOAuth)
- (BOOL)oauthtwitter_isNumeric;
@end

@implementation NSString (TwitterOAuth)

- (BOOL)oauthtwitter_isNumeric {
	const char *raw = (const char *)[self UTF8String];
	
	for (int i = 0; i < strlen(raw); i++) {
		if (raw[i] < '0' || raw[i] > '9') return NO;
	}
	return YES;
}
@end


@implementation SA_OAuthTwitterController
@synthesize engine = _engine, _delegate, navigationBar = _navBar, orientation = _orientation;


- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter]removeObserver: self];
	_webView.delegate = nil;
	[_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@""]]];
	
	self.view = nil;
}

+ (SA_OAuthTwitterController *)controllerToEnterCredentialsWithTwitterEngine:(SA_OAuthTwitterEngine *)engine delegate:(id <SA_OAuthTwitterControllerDelegate>) delegate forOrientation: (UIInterfaceOrientation)theOrientation {
	if (![self credentialEntryRequiredWithTwitterEngine: engine]) {
        return nil;
    }
	
	SA_OAuthTwitterController *controller = [[SA_OAuthTwitterController alloc] initWithEngine:engine andOrientation:theOrientation];
	
	controller._delegate = delegate;
	return controller;
}

+ (SA_OAuthTwitterController *)controllerToEnterCredentialsWithTwitterEngine:(SA_OAuthTwitterEngine *)engine delegate:(id <SA_OAuthTwitterControllerDelegate>) delegate {
	return [SA_OAuthTwitterController controllerToEnterCredentialsWithTwitterEngine:engine delegate:delegate forOrientation: UIInterfaceOrientationPortrait];
}


+ (BOOL)credentialEntryRequiredWithTwitterEngine:(SA_OAuthTwitterEngine *)engine {
	return ![engine isAuthorized];
}

- (id)initWithEngine:(SA_OAuthTwitterEngine *)engine andOrientation:(UIInterfaceOrientation)theOrientation {
	if (self = [super init]) {
		self.engine = engine;
		self.orientation = theOrientation;
		_firstLoad = YES;
		
		if (UIInterfaceOrientationIsLandscape(self.orientation)) {
			_webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 32, 480, 288)];
        } else {
			_webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 44, 320, 416)];
		}
        
		_webView.hidden = YES;
		_webView.delegate = self;
		_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _webView.dataDetectorTypes = UIDataDetectorTypeNone;

		[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(pasteboardChanged:) name:UIPasteboardChangedNotification object:nil];
	}
	return self;
}

- (void)denied {
	if ([_delegate respondsToSelector:@selector(OAuthTwitterControllerFailed:)]) {
        [_delegate OAuthTwitterControllerFailed:self];
    }
	[self performSelector:@selector(dismissModalViewControllerAnimated:) withObject:(id)kCFBooleanTrue afterDelay:1.0];
}

- (void)gotPin:(NSString *)pin {
	_engine.pin = pin;
	[_engine requestAccessToken];
	
	if ([_delegate respondsToSelector:@selector(OAuthTwitterController:authenticatedWithUsername:)]) {
        [_delegate OAuthTwitterController:self authenticatedWithUsername:_engine.username];
    }
    
	[self performSelector:@selector(dismissModalViewControllerAnimated:) withObject:(id)kCFBooleanTrue afterDelay:1.0];
}

- (void)cancel:(id)sender {
	if ([_delegate respondsToSelector:@selector(OAuthTwitterControllerCanceled:)]) {
        [_delegate OAuthTwitterControllerCanceled:self];
    }
	[self performSelector:@selector(dismissModalViewControllerAnimated:) withObject:(id)kCFBooleanTrue afterDelay:0.0];
}

- (void)loadView {
	[super loadView];
    
	if (UIInterfaceOrientationIsLandscape(self.orientation)) {
		self.view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 480, 288)];
		_navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, 480, 32)];
	} else {
		self.view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 460)];	
		_navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
	}
    
    self.view.backgroundColor = [UIColor grayColor];
    
	_navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.view addSubview:_webView];
	[self.view addSubview:_navBar];
	
	_blockerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 200, 60)];
	_blockerView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
	_blockerView.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
	_blockerView.clipsToBounds = YES;
    _blockerView.layer.cornerRadius = 10;
	
	UILabel	*label = [[UILabel alloc]initWithFrame:CGRectMake(0, 5, _blockerView.bounds.size.width, 15)];
	label.text = @"Please Wait...";
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor whiteColor];
	label.textAlignment = UITextAlignmentCenter;
	label.font = [UIFont boldSystemFontOfSize:15];
	[_blockerView addSubview:label];
	
	UIActivityIndicatorView	*spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	
	spinner.center = CGPointMake(_blockerView.bounds.size.width/2, (_blockerView.bounds.size.height/2)+10);
	[_blockerView addSubview:spinner];
	[self.view addSubview:_blockerView];
	[spinner startAnimating];
	
	UINavigationItem *navItem = [[UINavigationItem alloc]initWithTitle:@"Twitter Login"];
	navItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
	[_navBar pushNavigationItem:navItem animated:NO];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_engine requestRequestTokenSync];
        NSURLRequest *request = _engine.authorizeURLRequest;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [_webView loadRequest:request];
        });
    });
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	self.orientation = self.interfaceOrientation;
	_blockerView.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
}

- (void)pasteboardChanged:(NSNotification *)note {
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	
	if ([note.userInfo objectForKey:UIPasteboardChangedTypesAddedKey] == nil) {
        return; // no meaningful change
    }
	
	NSString *copied = pb.string;
	
	if (copied.length != 7 || !copied.oauthtwitter_isNumeric) {
        return;
    }
	
	[self gotPin:copied];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    _webView.userInteractionEnabled = YES;
	_loading = NO;
    NSString *authPin = [self locateAuthPinInWebView:webView];

    if (authPin.length) {
        [self gotPin:authPin];
        return;
    }
    
    NSString *formCount = [_webView stringByEvaluatingJavaScriptFromString:@"document.forms.length"];
		
    if ([formCount isEqualToString:@"0"]) {
        [self showPinCopyPrompt];
    }
	
	[UIView beginAnimations: nil context: nil];
	_blockerView.hidden = YES;
	[UIView commitAnimations];
	
	if ([_webView isLoading]) {
		_webView.hidden = YES;
	} else {
		_webView.hidden = NO;
	}
}

- (void)showPinCopyPrompt {
	if (self.pinCopyPromptBar.superview) {
        return;
    }
    
	self.pinCopyPromptBar.center = CGPointMake(self.pinCopyPromptBar.bounds.size.width/2, self.pinCopyPromptBar.bounds.size.height/2);
	[self.view insertSubview:self.pinCopyPromptBar belowSubview:self.navigationBar];
	
	[UIView beginAnimations:nil context:nil];
	self.pinCopyPromptBar.center = CGPointMake(self.pinCopyPromptBar.bounds.size.width/2, self.navigationBar.bounds.size.height+self.pinCopyPromptBar.bounds.size.height/2);
	[UIView commitAnimations];
}

- (void)removePinCopyPrompt {
    if (_pinCopyPromptBar.superview) {
        [_pinCopyPromptBar removeFromSuperview];
    }
}

/*********************************************************************************************************
 I am fully aware that this code is chock full 'o flunk. That said:
 
 - first we check, using standard DOM-diving, for the pin, looking at both the old and new tags for it.
 - if not found, we try a regex for it. This did not work for me (though it did work in test web pages).
 - if STILL not found, we iterate the entire HTML and look for an all-numeric 'word', 7 characters in length

Ugly. I apologize for its inelegance. Bleah.
*********************************************************************************************************/

- (NSString *)locateAuthPinInWebView:(UIWebView *)webView {
    // New version of the Twitter PIN image
    // Run this first to cut down on the amount of Javascript ran
	NSString *js = @"var d = document.getElementById('oauth-pin'); if (d == null) d = document.getElementById('oauth_pin'); " \
    "if (d) { var d2 = d.getElementsByTagName('code'); if (d2.length > 0) d2[0].innerHTML; }";
	NSString *pin = [[webView stringByEvaluatingJavaScriptFromString:js]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (pin.length == 7) {
		return pin;
	} else {
		// Older version of Twitter PIN Image
        // used as a fallback
        js = @"var d = document.getElementById('oauth-pin'); if (d == null) d = document.getElementById('oauth_pin'); if (d) d = d.innerHTML; d;";
		pin = [[webView stringByEvaluatingJavaScriptFromString:js]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if (pin.length == 7) {
			return pin;
		}
	}
	
	return nil;
}

- (UIView *)pinCopyPromptBar {
	if (_pinCopyPromptBar == nil){
		CGRect bounds = self.view.bounds;
		
		_pinCopyPromptBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 44, bounds.size.width, 44)];
		_pinCopyPromptBar.barStyle = UIBarStyleBlackTranslucent;
		_pinCopyPromptBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        _pinCopyPromptBar.items = [NSArray arrayWithObjects:
                                   [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                   [[UIBarButtonItem alloc]initWithTitle:@"Select and Copy the PIN" style: UIBarButtonItemStylePlain target:nil action: nil],
                                   [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                   nil];
        
	}
	return _pinCopyPromptBar;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
    if (![self.engine getRequestToken]) {
        [_engine requestRequestTokenSync];
    }
	_loading = YES;
    _webView.userInteractionEnabled = NO;
	[UIView beginAnimations:nil context:nil];
	[_blockerView setHidden:NO];
    [_webView setHidden:YES];
	[UIView commitAnimations];
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    BOOL isNotCancelLink = !strstr([[NSString stringWithFormat:@"%@",request.URL]UTF8String], "denied=");
    
	NSData *data = [request HTTPBody];
	char *raw = data ? (char *)[data bytes] : "";
    
    if (!isNotCancelLink) {
        [self dismissModalViewControllerAnimated:YES];
        return NO;
    }
	
	if (raw && (strstr(raw, "cancel=") || strstr(raw, "deny="))) {
		[self denied];
		return NO;
	}
	return YES;
}

@end
