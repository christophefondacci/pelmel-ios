//
//  OptionsAnimator.h
//  Bencina Chile
//
//  Created by Sergio Campamá on 1/18/14.
//  Copyright (c) 2014 Kaipi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpringTransitioningDelegate.h"

@interface PresentingSpringAnimator : NSObject <UIViewControllerAnimatedTransitioning, TransitioningDelegateAnimator>

@property (nonatomic,weak) UIImageView *bgBlurred;

@end
