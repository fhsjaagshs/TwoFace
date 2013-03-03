//
//  SavedTimelineDoc.m
//  TwoFace
//
//  Created by Nate Symer on 7/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SavedTimelineDoc.h"
#import "AppDelegate.h"

@implementation SavedTimelineDoc

@synthesize selectedLists;

// Called whenever the application reads data from the file system
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    
    NSMutableDictionary *fbSelected = kSelectedFriendsDictionary;
    NSMutableArray *twitterSelected = usernamesListArray;
    NSMutableArray *twitterSelectedManual = addedUsernamesListArray;
    
    self.selectedLists = [[NSMutableDictionary alloc]init];
    
    [self.selectedLists setObject:fbSelected forKey:kSelectedFriendsDictionaryKey];
    [self.selectedLists setObject:twitterSelected forKey:usernamesListKey];
    [self.selectedLists setObject:twitterSelectedManual forKey:addedUsernamesListKey];
    
    return YES;    
}


//
// Returns the data that UIDocument will write
//

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {
    
    NSMutableDictionary *fbSelected = kSelectedFriendsDictionary;
    NSMutableArray *twitterSelected = usernamesListArray;
    NSMutableArray *twitterSelectedManual = addedUsernamesListArray;
    
    self.selectedLists = [[NSMutableDictionary alloc]init];
    
    [self.selectedLists setObject:fbSelected forKey:kSelectedFriendsDictionaryKey];
    [self.selectedLists setObject:twitterSelected forKey:usernamesListKey];
    [self.selectedLists setObject:twitterSelectedManual forKey:addedUsernamesListKey];
    
    
    
    return nil;
}

- (void)saveToNSUD {
    
}

@end
