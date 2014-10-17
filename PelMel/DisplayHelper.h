//
//  DisplayHelper.h
//  PelMel
//
//  Created by Christophe Fondacci on 27/01/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALObject.h"

@interface DisplayHelper : NSObject

/**
 * Provides the name of the given CAL Object
 */
+(NSString*)getName:(CALObject*)object;

@end
