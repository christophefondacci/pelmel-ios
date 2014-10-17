//
//  Description.m
//  nativeTest
//
//  Created by Christophe Fondacci on 07/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "Description.h"

@implementation Description

- (id)initWithDescription:(NSString *)description language:(NSString *)language {
    if(self = [super init]) {
        _descriptionText = description;
        _languageCode = language;
    }
    return self;
}
- (id)initWithKey:(NSString *)key description:(NSString *)description language:(NSString *)language {
    if(self = [super init]) {
        _key = key;
        _descriptionText = description;
        _languageCode = language;
    }
    return self;
}
@end
