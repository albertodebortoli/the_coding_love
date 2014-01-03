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

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

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
