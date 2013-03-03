//
//  Prefs.h
//  Node
//
//  Created by Nathaniel Symer on 6/3/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Prefs : UIViewController {
    IBOutlet UIButton *twitterSigninButton;
    IBOutlet UIButton *facebookSigninButton;
    IBOutlet UILabel *facebookNameLabel;
    IBOutlet UILabel *twitterNameLabel;
    BOOL isAlreadyGettingName;
}

@property (nonatomic, strong) IBOutlet UIButton *twitterSigninButton;
@property (nonatomic, strong) IBOutlet UIButton *facebookSigninButton;

@property (nonatomic, strong) IBOutlet UILabel *facebookNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *twitterNameLabel;

- (void)setFacebookNameLabelText;
- (void)setTwitterNameLabelText;


@end
