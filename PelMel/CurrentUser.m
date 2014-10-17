//
//  User.m
//  nativeTest
//
//  Created by Christophe Fondacci on 27/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "CurrentUser.h"
#import "Description.h"

@implementation CurrentUser

@synthesize login = _login;
@synthesize password = _password;
@synthesize token = _token;

- (CurrentUser *)initWithLogin:(NSString *)login password:(NSString *)password token:(NSString *)token {
    if( self = [super init]) {
        _login = login;
        _password = password;
        _token = token;
        _isImperial = YES;
    }
    return self;
}


@end
