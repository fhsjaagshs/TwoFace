//
//  TwoFaceCell.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/8/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "TwoFaceCell.h"
#import "CCoreTextLabel.h"
#import "CCoreTextLabel_HTMLExtensions.h"
#import "ColorBandView.h"

@interface TwoFaceCell ()

@property (nonatomic, strong) ColorBandView *colorView;
@property (nonatomic, strong) CCoreTextLabel *ctl;

@end

@implementation TwoFaceCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.ctl = [[CCoreTextLabel alloc]init];
        [self.contentView addSubview:_ctl];
        self.colorView = [[ColorBandView alloc]initWithFrame:CGRectMake(0, 0, 15, self.bounds.size.height)];
        [self.contentView addSubview:_colorView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.frame = CGRectMake(20, self.textLabel.frame.origin.y, 280-5, self.textLabel.frame.size.height);
    self.detailTextLabel.frame = CGRectMake(20, self.detailTextLabel.frame.origin.y, 280-5, self.detailTextLabel.frame.size.height);
    _ctl.frame = self.detailTextLabel.frame;
    _ctl.lineBreakMode = UILineBreakModeWordWrap;
    _ctl.text = self.detailTextLabel.text;
    _ctl.textColor = self.detailTextLabel.textColor;
    _colorView.frame = CGRectMake(0, 0, 15, self.bounds.size.height);
    [_colorView drawWithIsFacebook:_isFacebook];
    [self.detailTextLabel setHidden:YES];
}

- (void)clear {
    [_colorView clear];
}

@end
