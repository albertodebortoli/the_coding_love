//
//  TCLTableViewCell.h
//  TheCodingLove
//
//  Created by Alberto De Bortoli on 03/01/2014.
//  Copyright (c) 2014 Alberto De Bortoli. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TCLTableViewCellContentView.h"
#import "TCLEntry.h"

@interface TCLTableViewCell : UITableViewCell

@property (nonatomic, strong) TCLTableViewCellContentView *customContentView;

- (void)loadAnimatedGIF:(TCLEntry *)entry;

@end
