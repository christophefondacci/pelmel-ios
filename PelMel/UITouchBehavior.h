//
//  UITouchBehaviour.h
//  PelMel
//
//  Created by Christophe Fondacci on 27/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * The touch behavior creates a reaction to touch event by animating the target view 
 * like a spring
 */
@interface UITouchBehavior : UIDynamicBehavior

- (instancetype)initWithTarget:(UIView *)view;

@end
