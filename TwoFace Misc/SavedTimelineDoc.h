//
//  SavedTimelineDoc.h
//  TwoFace
//
//  Created by Nate Symer on 7/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SavedTimelineDoc : UIDocument

@property (strong, nonatomic) NSMutableDictionary *selectedLists;

- (void)saveToNSUD;

@end
