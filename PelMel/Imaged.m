//
//  Imaged.m
//  nativeTest
//
//  Created by Christophe Fondacci on 01/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "Imaged.h"

@implementation Imaged

- (id)init {
    if(self = [super init] ) {
        _otherImages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (CALImage*)imageAtIndex:(NSInteger) index {
    if(index==0) {
        return _mainImage;
    } else {
        return [_otherImages objectAtIndex:index-1];
    }
}
@end
