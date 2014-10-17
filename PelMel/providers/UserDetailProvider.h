//
//  UserDetailProvider.h
//  togayther
//
//  Created by Christophe Fondacci on 19/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../DetailViewController.h"

@interface UserDetailProvider : NSObject <DetailProvider>

-(id) initWithUser:(User*)user;

@end
