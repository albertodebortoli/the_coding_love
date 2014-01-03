//
//  TCLTableViewCellContentView.h
//  TheCodingLove
//
//  Created by Alberto De Bortoli on 01/01/2014.
//  Copyright (c) 2014 Alberto De Bortoli. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const CGFloat kTCLTableViewCellContentViewImagePadding;

@interface TCLTableViewCellContentView : UIView

@property (nonatomic, weak) IBOutlet UIImageView *entryImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

- (void)setTitle:(NSString *)title image:(UIImage *)image;
- (void)setImage:(UIImage *)image;

@end
