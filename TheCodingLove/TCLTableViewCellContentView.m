//
//  TCLTableViewCellContentView.m
//  TheCodingLove
//
//  Created by Alberto De Bortoli on 01/01/2014.
//  Copyright (c) 2014 Alberto De Bortoli. All rights reserved.
//

#import "TCLTableViewCellContentView.h"

@implementation TCLTableViewCellContentView

- (void)setTitle:(NSString *)title image:(UIImage *)image author:(NSString *)author
{
    self.titleLabel.text = title;

    self.entryImageView.image = image;
    CGRect frame = self.frame;
    CGFloat x = (320.0 * image.size.height) / image.size.width;
    frame.size.height = x + kTCLTableViewCellContentViewImagePadding;
    self.frame = frame;
    NSLog(@"[tcl content view cell] image height %f", x);

    self.authorLabel.text = author;
}

@end
