//
//  City.h
//  togayther
//
//  Created by Christophe Fondacci on 16/01/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import "CALObject.h"

@interface City : CALObject

@property (strong) NSString* name;
@property (strong) NSString* localization;
@property (nonatomic) int placesCount;

@end
