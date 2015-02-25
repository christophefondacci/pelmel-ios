//
//  OptionsAnimator.m
//  Bencina Chile
//
//  Created by Sergio Campamá on 1/18/14.
//  Copyright (c) 2014 Kaipi. All rights reserved.
//

#import "PresentingSpringAnimator.h"

@interface PresentingSpringAnimator ()

@property (nonatomic) TransitioningDirection transitioningDirection;

@end

@implementation PresentingSpringAnimator

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
    return 0.6f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGRect fromVCFrame = [transitionContext initialFrameForViewController:fromVC];
    CGRect finalFrame = CGRectMake(10, 40, CGRectGetWidth(fromVCFrame) - 20, CGRectGetHeight(fromVCFrame) - 40);
    CGRect initialFrame = [self initialFrameFromFinalFrame:finalFrame inTransitionContext:transitionContext];
    
    toVC.view.frame = initialFrame;
    [[transitionContext containerView] addSubview:toVC.view];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0.0f
         usingSpringWithDamping:0.9f
          initialSpringVelocity:0.7f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         toVC.view.frame = finalFrame;
                     }
                     completion:^(BOOL finished) {
                         [transitionContext completeTransition:YES];
                     }];
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        _bgBlurred.alpha=1;
    } completion:nil];
}

- (CGRect)initialFrameFromFinalFrame:(CGRect)finalFrame inTransitionContext:(id<UIViewControllerContextTransitioning>)transitionContext
{
    CGRect initialFrame;
    
    switch (self.transitioningDirection) {
        case TransitioningDirectionUp:
            initialFrame = CGRectOffset(finalFrame, 0, -CGRectGetHeight(transitionContext.containerView.frame));
            break;
        case TransitioningDirectionLeft:
            initialFrame = CGRectOffset(finalFrame, -CGRectGetWidth(transitionContext.containerView.frame), 0);
            break;
        case TransitioningDirectionDown:
            initialFrame = CGRectOffset(finalFrame, 0, CGRectGetHeight(transitionContext.containerView.frame));
            break;
        case TransitioningDirectionRight:
            initialFrame = CGRectOffset(finalFrame, CGRectGetWidth(transitionContext.containerView.frame), 0);
            break;
    }
    
    return initialFrame;
}

@end
