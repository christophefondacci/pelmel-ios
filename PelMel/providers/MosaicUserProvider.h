//
//  MosaicUserProvider.h
//  togayther
//
//  Created by Christophe Fondacci on 24/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../MosaicListViewController.h"
#import "User.h"

@interface MosaicUserProvider : NSObject <MosaicObjectProvider>

-(id)initWithUser:(User*)user;

@end
