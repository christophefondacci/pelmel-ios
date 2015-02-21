//
//  DynamicDismissalAnimator.h
//  SpringAndBlurDemo
//
//  Created by Sergio Campamá on 1/18/14.
//  Copyright (c) 2014 Sergio Campamá. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpringTransitioningDelegate.h"

@interface DynamicDismissalAnimator : NSObject <UIViewControllerAnimatedTransitioning, TransitioningDelegateAnimator>

@property (nonatomic,weak) UIImageView *bgBlurred;

@end
