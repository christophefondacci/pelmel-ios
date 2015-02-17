//
//  UIMenuManagerMainDelegate.h
//  PelMel
//
//  Created by Christophe Fondacci on 12/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLMenuManagerController.h"

@interface UIMenuManagerMainDelegate : NSObject<PMLMenuManagerDelegate,PMLDataListener>

@property (nonatomic,strong) MenuAction *pelmelLogo;

@end
