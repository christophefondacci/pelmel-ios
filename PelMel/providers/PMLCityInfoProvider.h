//
//  PMLCityInfoProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 28/09/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLInfoProvider.h"
#import "City.h"

@interface PMLCityInfoProvider : NSObject<PMLInfoProvider>

-(instancetype)initWithCity:(City*)city;
@end
