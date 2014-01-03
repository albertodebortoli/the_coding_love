//
//  TCLTableViewCell.m
//  TheCodingLove
//
//  Created by Alberto De Bortoli on 03/01/2014.
//  Copyright (c) 2014 Alberto De Bortoli. All rights reserved.
//

#import "TCLTableViewCell.h"

#import "UIImage+animatedGIF.h"

@implementation TCLTableViewCell

- (void)setCustomContentView:(TCLTableViewCellContentView *)customContentView
{
    _customContentView = customContentView;
    [self.contentView addSubview:customContentView];
}

- (void)loadAnimatedGIF:(TCLEntry *)entry
{
    UIImage *img = [UIImage animatedImageWithAnimatedGIFData:entry.data];
    [self.customContentView setImage:img];
}

@end
