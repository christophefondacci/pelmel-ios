//
//  ClaimPurchaseProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 11/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLPurchaseTableViewController.h"
#import "Place.h"

@interface PMLClaimPurchaseProvider : NSObject<PMLPurchaseProvider>

@property (nonatomic,retain) Place *place;

-(instancetype)initWithPlace:(Place*)place;
@end
