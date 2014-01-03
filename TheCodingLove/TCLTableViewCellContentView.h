//
//  TCLTableViewCellContentView.h
//  TheCodingLove
//
//  Created by Alberto De Bortoli on 01/01/2014.
//  Copyright (c) 2014 Alberto De Bortoli. All rights reserved.
//

#import <UIKit/UIKit.h>

static CGFloat kTCLTableViewCellContentViewImagePadding = 80.0f;

@interface TCLTableViewCellContentView : UIView

@property (nonatomic, weak) IBOutlet UIImageView *entryImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

- (void)setTitle:(NSString *)title image:(UIImage *)image;

@end
