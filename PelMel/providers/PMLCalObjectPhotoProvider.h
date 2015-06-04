//
//  PMLCalObjectPhotoProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 03/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CALObject.h"
#import "PMLPhotosCollectionViewController.h"
#import "DataService.h"

@interface PMLCalObjectPhotoProvider : NSObject<PMLPhotosProvider,PMLDataListener>

-(instancetype)initWithObject:(CALObject*)object ;


@end
