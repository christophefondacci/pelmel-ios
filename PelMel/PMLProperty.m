//
//  PMLProperty.m
//  PelMel
//
//  Created by Christophe Fondacci on 16/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLProperty.h"

@implementation PMLProperty

- (instancetype)initWithCode:(NSString *)code value:(NSString *)value defaultLabel:(NSString *)defaultLabel
{
    self = [super init];
    if (self) {
        self.propertyCode = code;
        self.propertyValue = value;
        self.defaultLabel = defaultLabel;
    }
    return self;
}
@end
