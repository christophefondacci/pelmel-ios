//
//  PMLThreadMessageProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 16/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLMessageTableViewController.h"

@interface PMLThreadMessageProvider : NSObject<PMLMessageProvider>
@property (nonatomic) NSInteger numberOfResults;
@end
