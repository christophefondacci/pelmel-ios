//
//  PMLModalTransitionAnimator.m
//  PelMel
//
//  Created by Christophe Fondacci on 25/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLModalTransitionAnimator.h"
#import "SpringTransitioningDelegate.h"
#import "UIMenuOpenBehavior.h"
#import "TogaytherService.h"

@implementation PMLModalTransitionAnimator  {
    id<UIViewControllerContextTransitioning> _currentTransitionContext;
    TransitioningDirection _direction;
    UIDynamicAnimator *_animator;
}

- (instancetype)initWithTransitioningDirection:(TransitioningDirection)transitioningDirection
{
    self = [super init];
    if (self) {
        _direction = transitioningDirection;
    }
    return self;
}
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    _currentTransitionContext = transitionContext;
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGRect fromVCFrame = [transitionContext initialFrameForViewController:fromVC];
    CGRect finalFrame = CGRectMake(10, 20, CGRectGetWidth(fromVCFrame)-20, CGRectGetHeight(fromVCFrame) - 20);

    // Starting at the bottom of screen
    CGRect initialFrame = CGRectOffset(finalFrame, 0, CGRectGetHeight(transitionContext.containerView.frame));
    toVC.view.frame = initialFrame;
    fromVC.view.frame = fromVCFrame;
//    [[transitionContext containerView] addSubview:fromVC.view];
    [[transitionContext containerView] addSubview:toVC.view];
    
    // Open behavior to the final Y location
    _animator = [[UIDynamicAnimator alloc] init];
    UIMenuOpenBehavior *openBehavior = [[UIMenuOpenBehavior alloc] initWithViews:@[toVC.view] open:YES boundary:finalFrame.origin.y];
    _animator.delegate = self;
    
    [openBehavior setIntensity:6.0];
    [_animator addBehavior:openBehavior];

    // Animating

//    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
//        fromVC.view.frame = CGRectMake(10, 15, CGRectGetWidth(fromVCFrame)-20, CGRectGetHeight(fromVCFrame)- 30);
//    } completion:^(BOOL finished) {
//        _bgBlurred.image = [[TogaytherService uiService] blurWithImageEffects:fromVC.view];
//        _bgBlurred.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            _bgBlurred.alpha=1;
        } ];
//    }];
    
}
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.5;
}

#pragma mark - UIDynamicAnimatorDelegate
- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    [_currentTransitionContext completeTransition:YES];
}
@end
