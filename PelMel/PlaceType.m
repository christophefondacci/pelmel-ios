//
//  PlaceType.m
//  nativeTest
//
//  Created by Christophe Fondacci on 26/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "PlaceType.h"


@implementation PlaceType

@synthesize code = _code;
@synthesize icon = _icon;

- (PlaceType *)initWithCode:(NSString *)code {
    if(self = [super init]) {
        _code = code;
        _visible = YES;
    }
    return self;
}

@end
