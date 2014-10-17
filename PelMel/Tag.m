//
//  Tag.m
//  togayther
//
//  Created by Christophe Fondacci on 08/01/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import "Tag.h"

@implementation Tag

- (id)initWithCode:(NSString *)code label:(NSString *)label icon:(UIImage *)icon{
    self = [super init];
    if (self) {
        _code = code;
        _label = label;
        _icon = icon;
    }
    return self;
}
@end
