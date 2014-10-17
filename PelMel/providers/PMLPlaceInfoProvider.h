//
//  PMLPlaceInfoProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 22/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLInfoProvider.h"
#import "Place.h"

@interface PMLPlaceInfoProvider : NSObject<PMLInfoProvider>

- (instancetype)initWith:(Place*)place;
@end
