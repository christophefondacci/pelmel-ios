//
//  PMLDynamicActionObject.h
//  PelMel
//
//  Created by Christophe Fondacci on 18/08/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PopupAction.h"

@interface PMLDynamicActionObject : NSObject<UIDynamicItem>

/**
 * This dynamic action object will map its y coordinates (0->100) to distance on its popup action
 * axis. An Y of 0 will set the corresponding view at the center while a value of 100 will put it
 * at its target location
 * @param action the PopupAction containing all settings
 * @param view the UIView to position
 * @param popCenter the center of all popups
 * @param centralRadius radius of the central main popup control
 */
-(instancetype)initWithAction:(PopupAction*)action inView:(UIView*)view popCenter:(CGPoint)center centralRadius:(CGFloat)centralRadius reverse:(BOOL)reverse;

@end
