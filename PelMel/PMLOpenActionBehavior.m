//
//  PMLOpenActionBehavior.m
//  PelMel
//
//  Created by Christophe Fondacci on 18/08/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLOpenActionBehavior.h"
#import "PopupAction.h"
#import "PMLDynamicActionObject.h"

@implementation PMLOpenActionBehavior {
    CGPoint _center;
    CGFloat _radius;
    
    UICollisionBehavior *_collisionBehavior;
    UIPushBehavior *_pushBehavior;
    UIGravityBehavior *_gravityBehavior;
    double _gravityStrength;
    
    BOOL _open;
    BOOL _callbackCalled;
}


- (instancetype)initWithViews:(NSArray *)views forActions:(NSArray *)actions center:(CGPoint)center radius:(CGFloat)radius open:(BOOL)open
{
    self = [super init];
    if (self) {
        _center = center;
        _radius = radius;
        _open = open;
        _gravityStrength = 3;
        _collisionBehavior = [[UICollisionBehavior alloc] init];
        _collisionBehavior.collisionMode = UICollisionBehaviorModeBoundaries;
        _collisionBehavior.collisionDelegate = self;
        [_collisionBehavior addBoundaryWithIdentifier:@"ground" fromPoint:CGPointMake(0, 105) toPoint:CGPointMake(1000, 105)];
        
        // Initializing gravity
        _gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[]];
        _gravityBehavior.gravityDirection = CGVectorMake(0, _gravityStrength);
        [self addChildBehavior:_gravityBehavior];
        
//        _pushBehavior = [[UIPushBehavior alloc] initWithItems:@[] mode:UIPushBehaviorModeInstantaneous];
//        _pushBehavior.magnitude=0.02;
//        _pushBehavior.angle=M_PI_2;
//        _pushBehavior.active=YES;
        [self addChildBehavior:_collisionBehavior];
//        [self addChildBehavior:_pushBehavior];
        [self addViews:views forActions:actions];
    }
    return self;
}

- (void)addViews:(NSArray *)views forActions:(NSArray *)actions {
    assert(views.count == actions.count);
    
    NSEnumerator *viewsEnum = views.objectEnumerator;
    NSEnumerator *actionsEnum=actions.objectEnumerator;
    UIView *view;
    PopupAction *action;


    while((view = viewsEnum.nextObject) != nil) {
        action = actionsEnum.nextObject;
        
        PMLDynamicActionObject *actionObj = [[PMLDynamicActionObject alloc] initWithAction:action inView:view popCenter:_center centralRadius:_radius reverse:!_open];
        actionObj.center = CGPointMake(100, 0);

        [_collisionBehavior addItem:actionObj];
        [_gravityBehavior addItem:actionObj];
        
        UIDynamicItemBehavior *itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[actionObj]];
        itemBehavior.elasticity=0.3;
        [self addChildBehavior:itemBehavior];
        
//        [_pushBehavior addItem:actionObj];
        
        
        
//        [view setCenter:_center];
//        UIAttachmentBehavior *attachment = [[UIAttachmentBehavior alloc] initWithItem:view attachedToAnchor:_center];
//        attachment.length = _radius + action.size.doubleValue/2 + action.distance.doubleValue;
//        [self addChildBehavior:attachment];
//        
//        UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[view] mode:UIPushBehaviorModeInstantaneous];
//        pushBehavior.angle = action.angle.doubleValue;
//        pushBehavior.magnitude = 0.00001;
//        [self addChildBehavior:pushBehavior];

//        [pushBehavior setActive:TRUE];
    }

}

-(void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier {
    if(self.completionCallback && !_callbackCalled) {
        self.completionCallback();
        _callbackCalled = YES;
    }
}

//- (void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier atPoint:(CGPoint)p {
//
//
//}
//-(void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier {
//    UIDynamicItemBehavior *itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[item]];
//    itemBehavior.resistance=100;
//    [self addChildBehavior:itemBehavior];
//}
@end
