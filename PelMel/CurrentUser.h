//
//  User.h
//  nativeTest
//
//  Created by Christophe Fondacci on 27/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@interface CurrentUser : User

@property (strong) NSString *login;
@property (strong) NSString *password;
@property (strong) NSString *token;
@property (nonatomic,assign) BOOL isImperial;

/**
 * Convenience initializer
 */
- (CurrentUser*)initWithLogin:(NSString*)login password:(NSString*)password token:(NSString*)token;


@end
