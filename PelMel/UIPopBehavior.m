//
//  UIPopBehavior.m
//  DynamicsTest
//
//  Created by Christophe Fondacci on 13/07/14.
//  Copyright (c) 2014 Pelmel. All rights reserved.
//

#import "UIPopBehavior.h"
#import "DynamicObject.h"

@implementation UIPopBehavior {
    int animationIndex;
    NSMutableArray *objects;
    UIGravityBehavior *gravity;
    
    NSMutableArray *dynamicItemBehaviors;
    BOOL _pop;
    BOOL _delayed;
    BOOL _delayWaiting;
    int _objectCount;
    
    // Completion
    PopCompletionBlock _completionBlock;
}

- (instancetype)initWithViews:(NSArray*)views pop:(BOOL)pop delay:(BOOL)delayed {
    return [self initWithViews:views pop:pop delay:delayed completion:nil];
}
- (instancetype)initWithViews:(NSArray*)views pop:(BOOL)pop delay:(BOOL)delayed completion:(PopCompletionBlock)completionBlock
{
    self = [super init];
    if (self) {
        _pop = pop;
        _delayed = delayed;
        objects = [[NSMutableArray alloc] init];
        dynamicItemBehaviors = [[NSMutableArray alloc] init];
        _elasticity = 0.7;
        _gravityStrength = 3;
        _objectCount = 0;
        _completionBlock = completionBlock;
        
        
        // Initializing gravity
        gravity = [[UIGravityBehavior alloc] initWithItems:@[]];
        gravity.gravityDirection = CGVectorMake(0, -_gravityStrength);
        [self addChildBehavior:gravity];
        
        // Adding items
        animationIndex = 0;
        [self addViews:views];

    }
    return self;
}


- (void)addViews:(NSArray *)views {
    for(UIView *view in views) {
        // Dynamic object binds its Y to width/height
        DynamicObject *o = [[DynamicObject alloc] initWithView:view withIndex:_objectCount reverse:_pop];
        [objects addObject:o];
        
        // Collision for the dynamic object at 0
        UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[o]];
        collision.collisionDelegate=self;
        [collision addBoundaryWithIdentifier:@"zero" fromPoint:CGPointMake(0, 0) toPoint:CGPointMake(60000, 0)];
        [self addChildBehavior:collision];
        
        // Elasticity
        UIDynamicItemBehavior *dynamic = [[UIDynamicItemBehavior alloc] initWithItems:@[o]];
        dynamic.elasticity=_elasticity;
        [self addChildBehavior:dynamic];
        [dynamicItemBehaviors addObject:dynamic];
        
        // If poping we start invisible so we make the view 1x1 pixels to avoid showing full size briefly
        if(_pop) {
            view.bounds = CGRectMake(0, 0, 1, 1);
        }
        
        // Adding item if no-delay requested or if we are waiting for objects to animate
        if(!_delayed || animationIndex == objects.count-1) {
            [gravity addItem:o];
        }
        // Next
        _objectCount++;
    }
}
- (void)willMoveToAnimator:(UIDynamicAnimator *)dynamicAnimator {
    if(dynamicAnimator == nil) {
        for(DynamicObject *object in objects) {
            [object reset];
        }
        [objects removeAllObjects];
    }
}

- (void)setElasticity:(double)elasticity {
    _elasticity = elasticity;
    for(UIDynamicItemBehavior *dib in dynamicItemBehaviors) {
        dib.elasticity = elasticity;
    }
}

- (void)setGravityStrength:(double)gravityStrength {
    _gravityStrength = gravityStrength;
    gravity.gravityDirection = CGVectorMake(0, -_gravityStrength);
}
# pragma mark - UICollisionBehaviorDelegate
- (void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier atPoint:(CGPoint)p {
    
    // Getting next item that should collide
    NSObject *currentItem = nil;
    if(animationIndex < objects.count ) {
        currentItem = [objects objectAtIndex:animationIndex];
    }
    
    // If we have it
    if(_delayed && item == currentItem) {
        
        // Incrementing our animation index
        animationIndex++;
        
        // If we still have more, we add gravity attraction to this next (else it will be pending)
        if(animationIndex < objects.count) {
            DynamicObject *newObject = [objects objectAtIndex:animationIndex];
            [gravity addItem:newObject];
        }
    }
    

}
- (void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier {
    // Calling back
    if(_completionBlock) {
        _completionBlock();
    }
}
@end
