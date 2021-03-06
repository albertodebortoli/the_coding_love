//
//  TCLTableViewCellContentView.m
//  TheCodingLove
//
//  Created by Alberto De Bortoli on 01/01/2014.
//  Copyright (c) 2014 Alberto De Bortoli. All rights reserved.
//

#import "TCLTableViewCellContentView.h"

const CGFloat kTCLTableViewCellContentViewImagePadding = 80.0f;

@implementation TCLTableViewCellContentView

- (void)setTitle:(NSString *)title image:(UIImage *)image
{
    self.titleLabel.text = title;

    self.entryImageView.image = image;
    CGRect frame = self.frame;
    CGFloat x = (320.0 * image.size.height) / image.size.width;
    frame.size.height = x + kTCLTableViewCellContentViewImagePadding;
    self.frame = frame;
}

- (void)setImage:(UIImage *)image
{
    self.entryImageView.image = image;    
}

@end
