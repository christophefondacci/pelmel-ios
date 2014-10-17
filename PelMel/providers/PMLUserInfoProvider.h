//
//  PMLUserInfoProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 22/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "PMLInfoProvider.h"

@interface PMLUserInfoProvider : NSObject<PMLInfoProvider>

- (instancetype)initWithUser:(User*)user;

@end
