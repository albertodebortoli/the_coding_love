//
//  TCLEntry.h
//  TheCodingLove
//
//  Created by Alberto De Bortoli on 01/01/2014.
//  Copyright (c) 2014 Alberto De Bortoli. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCLEntry : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) CGSize size;

- (BOOL)isConsistent;

@end
