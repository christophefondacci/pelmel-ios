//
//  CityDetailProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 17/08/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewController.h"


@interface CityDetailProvider : NSObject<DetailProvider>

-(instancetype)initWithCity:(City*)city;
@end
