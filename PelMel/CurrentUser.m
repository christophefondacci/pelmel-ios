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


- (CurrentUser *)initWithLogin:(NSString *)login password:(NSString *)password token:(NSString *)token {
    if( self = [super init]) {
        _login = login;
        _password = password;
        [self setToken:token];
        _isImperial = YES;
    }
    return self;
}

- (void)setToken:(NSString *)token {
    _token = token;
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:PML_PROP_USER_LAST_TOKEN];
}
@end
