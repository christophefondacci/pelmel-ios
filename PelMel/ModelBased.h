//
//  ModelBased.h
//  nativeTest
//
//  Created by Christophe Fondacci on 25/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ModelHolder.h"

@protocol ModelBased <NSObject>


- (ModelHolder *)getModelHolder;
- (void) setModelHolder:(ModelHolder *)modelHolder;

@end
