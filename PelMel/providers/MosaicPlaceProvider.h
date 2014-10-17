//
//  MosaicPlaceProvider.h
//  togayther
//
//  Created by Christophe Fondacci on 24/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../Place.h"
#import "../MosaicListViewController.h"

@interface MosaicPlaceProvider : NSObject <MosaicObjectProvider>

- (id) initWithPlace:(Place*)place;

@end
