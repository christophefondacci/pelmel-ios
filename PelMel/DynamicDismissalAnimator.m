//
//  DynamicDismissalAnimator.m
//  SpringAndBlurDemo
//
//  Created by Sergio Campamá on 1/18/14.
//  Copyright (c) 2014 Sergio Campamá. All rights reserved.
//

#import "DynamicDismissalAnimator.h"

@interface DynamicDismissalAnimator ()

@property (nonatomic) TransitioningDirection transitioningDirection;
@property (nonatomic, strong) UIDynamicAnimator *animator;

@end

@implementation DynamicDismissalAnimator

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
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:transitionContext.containerView];
    
    UIDynamicItemBehavior *itemBehaviour = [[UIDynamicItemBehavior alloc] initWithItems:@[fromVC.view]];
    [itemBehaviour addAngularVelocity:M_PI/2.0f forItem:fromVC.view];
    [self.animator addBehavior:itemBehaviour];
    
    UIGravityBehavior *gravityBehaviour = [[UIGravityBehavior alloc] initWithItems:@[fromVC.view]];
    

    gravityBehaviour.gravityDirection = [self vectorForCurrentOrientation];
    
    
    gravityBehaviour.action = ^{
        if (!CGRectIntersectsRect(fromVC.view.frame, transitionContext.containerView.frame)) {
            [self.animator removeAllBehaviors];
            [transitionContext completeTransition:YES];
            [UIView animateWithDuration:0.25 animations:^{
                _bgBlurred.alpha=0;
            } completion:^(BOOL finished) {
                [_bgBlurred removeFromSuperview];
                _bgBlurred = nil;
                if([toVC respondsToSelector:@selector(viewWillAppear:)]) {
                    [toVC viewWillAppear:YES];
                }
                if([toVC respondsToSelector:@selector(viewDidAppear:)]) {
                    [toVC viewDidAppear:YES];
                }
            }];
        }
    };
    
    [self.animator addBehavior:gravityBehaviour];
    

}

- (CGVector)vectorForCurrentOrientation
{
    CGVector vector;
    switch([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:
            vector = CGVectorMake(0.0, 3.0f);
            break;
        case UIDeviceOrientationLandscapeLeft:
            vector = CGVectorMake(-3.0, 0.0f);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            vector = CGVectorMake(0.0, -3.0f);
            break;
        case UIDeviceOrientationLandscapeRight:
            vector = CGVectorMake(3.0f, 0.0f);
            break;
        default:
            vector = CGVectorMake(0.0, 3.0f);
            break;
    }
    return vector;
}


@end
