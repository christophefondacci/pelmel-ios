//
//  MosaicUserProvider.m
//  togayther
//
//  Created by Christophe Fondacci on 24/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "MosaicUserProvider.h"


@implementation MosaicUserProvider {
    User *_user;
}

- (id)initWithUser:(User *)user
{
    self = [super init];
    if (self) {
        _user = user;
    }
    return self;
}

- (NSString *)getLabel {
    return _user.pseudo;
}
- (CALObject *)getObject {
    return _user;
}
- (CALImage *)getImage {
    return _user.mainImage;
}
- (BOOL)isOnline {
    return _user.isOnline;
}
@end
