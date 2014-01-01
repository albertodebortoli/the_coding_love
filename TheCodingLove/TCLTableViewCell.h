//
//  TCLTableViewCell.h
//  TheCodingLove
//
//  Created by Alberto De Bortoli on 01/01/2014.
//  Copyright (c) 2014 Alberto De Bortoli. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCLTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *entryImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *authorLabel;

@end
