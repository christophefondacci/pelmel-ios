//
//  PMLEventInfoProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 24/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLInfoProvider.h"
#import "Event.h"

@interface PMLEventInfoProvider : NSObject<PMLInfoProvider,PMLCountersDatasource>

-(instancetype)initWithEvent:(Event*)event;

@end
