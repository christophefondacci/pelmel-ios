//
//  DismissalAnimator.m
//  Bencina Chile
//
//  Created by Sergio Campamá on 1/18/14.
//  Copyright (c) 2014 Kaipi. All rights reserved.
//

#import "LinearDismissalAnimator.h"

@interface LinearDismissalAnimator ()

@property (nonatomic) TransitioningDirection transitioningDirection;

@end

@implementation LinearDismissalAnimator

- (id)initWithTransitioningDirection:(TransitioningDirection)transitioningDirection
{
    self = [super init];
    if (self) {
        self.transitioningDirection = transitioningDirection;
    }
    return self;
}


- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 1.0f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGRect initialFrame = [transitionContext initialFrameForViewController:fromVC];
    
    CGRect finalFrame = [self finalFrameFromInitialFrame:initialFrame inTransitionContext:transitionContext];
    
    UIViewAnimationOptions opts = UIViewAnimationOptionCurveLinear;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:opts animations:^{
        fromVC.view.frame = finalFrame;
        _bgBlurred.alpha=0;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        [_bgBlurred removeFromSuperview];
        _bgBlurred = nil;
        [toVC viewWillAppear:YES];
        [toVC viewDidAppear:YES];
    }];
}

- (CGRect)finalFrameFromInitialFrame:(CGRect)initialFrame inTransitionContext:(id<UIViewControllerContextTransitioning>)transitionContext
{
    CGRect finalFrame;
    switch (self.transitioningDirection) {
        case TransitioningDirectionUp:
            finalFrame = CGRectOffset(initialFrame, 0, -CGRectGetHeight(transitionContext.containerView.frame));
            break;
        case TransitioningDirectionLeft:
            finalFrame = CGRectOffset(initialFrame, -CGRectGetWidth(transitionContext.containerView.frame), 0);
            break;
        case TransitioningDirectionDown:
            finalFrame = CGRectOffset(initialFrame, 0, CGRectGetHeight(transitionContext.containerView.frame));
            break;
        case TransitioningDirectionRight:
            finalFrame = CGRectOffset(initialFrame, CGRectGetWidth(transitionContext.containerView.frame), 0);
            break;
    }
    return finalFrame;
}

@end
