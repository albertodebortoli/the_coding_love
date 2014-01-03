//
//  TCLEntry.m
//  TheCodingLove
//
//  Created by Alberto De Bortoli on 01/01/2014.
//  Copyright (c) 2014 Alberto De Bortoli. All rights reserved.
//

#import "TCLEntry.h"

@implementation TCLEntry

- (BOOL)isConsistent
{
    if ([self.title length] == 0) {
        return NO;
    }
    
    if ([self.url length] == 0) {
        return NO;
    }
    
    if (!self.data) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isEqual:(id)object
{
    if ([object class] == [self class]) {
        if ([((TCLEntry *)object).url isEqualToString:self.url]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSUInteger)hash
{
    return [self.url hash];
}

@end
