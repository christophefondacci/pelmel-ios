//
//  PMLModalTransitionAnimator.h
//  PelMel
//
//  Created by Christophe Fondacci on 25/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpringTransitioningDelegate.h"

@interface PMLModalTransitionAnimator : NSObject<UIViewControllerAnimatedTransitioning,TransitioningDelegateAnimator,UIDynamicAnimatorDelegate>

@property (nonatomic,weak) UIImageView *bgBlurred;

@end
