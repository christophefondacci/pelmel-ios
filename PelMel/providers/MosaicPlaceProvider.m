//
//  MosaicPlaceProvider.m
//  togayther
//
//  Created by Christophe Fondacci on 24/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "MosaicPlaceProvider.h"

@implementation MosaicPlaceProvider {
    Place *_place;
}

- (id)initWithPlace:(Place *)place
{
    self = [super init];
    if (self) {
        _place = place;
    }
    return self;
}

- (NSString *)getLabel {
    return _place.title;
}

- (CALObject *)getObject {
    return _place;
}
- (CALImage *)getImage {
    return _place.mainImage;
}
-(BOOL)isOnline {
    return NO;
}
@end
