//
//  PlaceTypesThumbPreviewProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 03/09/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbsPreviewView.h"
#import "PlaceType.h"
#import "ThumbTableViewController.h"
@class Place;
@interface PMLPlaceTypesThumbProvider : NSObject<ThumbsPreviewProvider>

-(instancetype)initWithPlace:(Place*)place;
@end
