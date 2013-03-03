//
//  TwitterOrFBCell.h
//  TwoFace
//
//  Created by Nate Symer on 7/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TwitterOrFBCell : UITableViewCell 

@property (strong, nonatomic) UILabel *label;

- (void)setFacebook:(BOOL)isFacebook;

@end
