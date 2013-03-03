//
//  SyncingViewControllerViewController.m
//  TwoFace
//
//  Created by Nate Symer on 7/23/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "SyncingViewControllerViewController.h"

@implementation SyncingViewControllerViewController

@synthesize loginButton, resetSyncButton, syncButton, lastSyncedLabel;


- (void)saveLastSyncedDate {
    NSDate *currentDate = [NSDate date];
    [[NSUserDefaults standardUserDefaults]setObject:currentDate forKey:@"lastSyncedDateKey"];
}

- (void)setLastSyncedDateTwo {
    [self saveLastSyncedDate];
    NSDate *date = [[NSUserDefaults standardUserDefaults]objectForKey:@"lastSyncedDateKey"];
    
    NSString *displayString = nil;
    if (!date) {
        displayString = @"Never Synced";
    } else {
        
        NSString *dateS = [date stringDaysAgo];
        
        if ([dateS isEqualToString:@"Today"]) {
            dateS = [NSDate stringForDisplayFromDate:date prefixed:YES];
        }
        
        displayString = [NSString stringWithFormat:@"Last synced %@",dateS];
    }
    [lastSyncedLabel setText:displayString];
}

- (void)setLastSyncedDate {
    NSDate *date = [[NSUserDefaults standardUserDefaults]objectForKey:@"lastSyncedDateKey"];
    
    NSString *displayString = nil;
    if (!date) {
        displayString = @"Never Synced";
    } else {
        displayString = [@"Last synced " stringByAppendingString:[NSDate stringForDisplayFromDate:date prefixed:YES]];
    }
    [lastSyncedLabel setText:displayString];
}

- (IBAction)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)sync {
    [kAppDelegate dropboxSync];
}

- (IBAction)resetSync {
    [kAppDelegate resetDropboxSync];
}

- (IBAction)loginToDropbox {
    if (![[DBSession sharedSession]isLinked]) {
		[[DBSession sharedSession]linkFromController:self];
    } else {
        [[DBSession sharedSession]unlinkAll];
        [loginButton setTitle:@"Link"];
        [syncButton setEnabled:NO];
        [resetSyncButton setEnabled:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (![[DBSession sharedSession]isLinked]) {
		[loginButton setTitle:@"Link"];
        [resetSyncButton setEnabled:NO];
        [syncButton setEnabled:NO];
    } else {
        [loginButton setTitle:@"Unlink"];
        [resetSyncButton setEnabled:YES];
        [syncButton setEnabled:YES];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setLastSyncedDate];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setLastSyncedDateTwo) name:@"lastSynced" object:nil];
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
