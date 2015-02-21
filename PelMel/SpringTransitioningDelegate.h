//
//  TransitioningDelegate.h
//  Bencina Chile
//
//  Created by Sergio Campamá on 1/18/14.
//  Copyright (c) 2014 Kaipi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TransitioningDirection) {
    TransitioningDirectionUp = 0,
    TransitioningDirectionLeft = 1,
    TransitioningDirectionDown = 2,
    TransitioningDirectionRight = 3
};

#define kTransitionDirectionCount 4

@class SpringTransitioningDelegate;

@protocol TransitioningDelegateAnimator <NSObject>

- (id)initWithTransitioningDirection:(TransitioningDirection)transitioningDirection;

@end

@interface SpringTransitioningDelegate : NSObject <UIViewControllerTransitioningDelegate>

@property (nonatomic, weak) UIViewController *delegate;
@property (nonatomic, retain) UIPercentDrivenInteractiveTransition *interactiveTransition;
@property TransitioningDirection transitioningDirection;
@property BOOL interactive;

- (id)initWithDelegate:(UIViewController *)delegate;
- (void)presentViewController:(UIViewController *)modalViewController;

@end
