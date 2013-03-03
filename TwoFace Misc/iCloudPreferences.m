//
//  iCloudPreferences.m
//  TwoFace
//
//  Created by Nate Symer on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "iCloudPreferences.h"
#import "AppDelegate.h"


@implementation iCloudPreferences
- (id)initAuto {
    self = [super initWithNibName:@"iCloudPreferences" bundle:nil];
    return self;
}

- (IBAction)sync {
    dispatch_queue_t q = dispatch_queue_create("com.fhsjaagshs.TwoFace.asdfasdf", NULL);
    dispatch_sync(q, ^{
        [kAppDelegate synciCloud];
        sleep(3.0);
    });
}

- (IBAction)clearSync {
    [kAppDelegate resetiCloudSync];
}

- (IBAction)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
