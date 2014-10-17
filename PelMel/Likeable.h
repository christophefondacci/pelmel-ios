//
//  Likeable.h
//  togayther
//
//  Created by Christophe Fondacci on 22/01/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALObject.h"
#import "DataService.h"

@protocol Likeable <NSObject>

-(void)likeTapped:(CALObject*)likedObject callback:(LikeCompletionBlock)callback;

@end
