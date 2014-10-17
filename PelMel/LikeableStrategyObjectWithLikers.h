//
//  LikeableStrategyObjectWithLikers.h
//  togayther
//
//  Created by Christophe Fondacci on 22/01/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Likeable.h"

/**
 * This strategy class implements the Likeable for objects presenting
 * likers. When like is tapped, current user will be added to the set
 * of elements liking the object.
 */
@interface LikeableStrategyObjectWithLikers : NSObject <Likeable>

@end
