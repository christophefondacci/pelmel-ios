//
//  UIMenuOpenBehaviour.m
//  PelMel
//
//  Created by Christophe Fondacci on 13/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "UIMenuOpenBehavior.h"
#import "MenuAction.h"

@implementation UIMenuOpenBehavior {
    int _boundary;
    BOOL _horizontal;
    BOOL _open;
    int _currentMainViewBoundary;
    
    UIGravityBehavior *_gravityBehavior;
    
}

- (instancetype)initWithViews:(NSArray *)views open:(BOOL)shouldOpenMenu boundary:(int)yBoundary {
    return [self initWithViews:views open:shouldOpenMenu boundary:yBoundary horizontal:NO];
}
- (instancetype)initWithViews:(NSArray *)views open:(BOOL)shouldOpenMenu boundary:(int)yBoundary horizontal:(BOOL)horizontal {
    self = [super init];
    if (self) {
        // Storing values we need
        _boundary = yBoundary;
        _horizontal = horizontal;
        _open = shouldOpenMenu;
        
        // Computing gravity direction and collision boundary
        CGFloat gravityDirectionY = (shouldOpenMenu) ? -1.0 : 1.0;
        CGFloat boundaryPointY = shouldOpenMenu ? yBoundary-1 : yBoundary+1;
        
        
        _gravityBehavior = [[UIGravityBehavior alloc] initWithItems:views];
        CGPoint fromPoint,toPoint;
        if(horizontal) {
            _gravityBehavior.gravityDirection = CGVectorMake(-gravityDirectionY,0.0);
            fromPoint=CGPointMake(boundaryPointY,0);
            toPoint=CGPointMake(boundaryPointY,4000);
        } else {
            _gravityBehavior.gravityDirection = CGVectorMake(0.0,gravityDirectionY);
            fromPoint=CGPointMake(0,boundaryPointY);
            toPoint=CGPointMake(4000,boundaryPointY);
        }
        [self addChildBehavior:_gravityBehavior];
        
        
        // We add specific collision for each item as we do not want them to collide between each other,
        // only with our boundary
        for(UIView *view in views) {
            UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[view]];
            [collisionBehavior addBoundaryWithIdentifier:@"menuBoundary"
                                               fromPoint:fromPoint
                                                 toPoint:toPoint];
            _currentMainViewBoundary = (_horizontal ? view.frame.origin.x + view.frame.size.width : view.frame.origin.y);
            [self addChildBehavior:collisionBehavior];
        }
        
//        UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[views]
//                                                                        mode:UIPushBehaviorModeInstantaneous];
//        pushBehavior.magnitude = pushMagnitude;
    }
    return self;
}
- (void)addPushedActions:(NSArray *)pushedViews inBounds:(CGRect)bounds {
    for(MenuAction *action in pushedViews) {
        
        UIView *view = action.menuActionView;
        CGRect frame = view.frame;
        if(!_horizontal) {
            // The view is pushed only is obstructing so we check that first
            if(_open && frame.origin.y+frame.size.height>_boundary) {
                
                int viewBoundary = _boundary - frame.size.height - action.bottomMargin;
                
                UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[view]];
                CGPoint fromPoint=CGPointMake(0,viewBoundary);
                CGPoint toPoint=CGPointMake(4000,viewBoundary);

                [collisionBehavior addBoundaryWithIdentifier:@"menuBoundary"
                                                   fromPoint:fromPoint
                                                     toPoint:toPoint];
                [self addChildBehavior:collisionBehavior];
                
                [_gravityBehavior addItem:view];

            } else if(!_open && action.pctHeightPosition == 1) { //frame.origin.y+frame.size.height>_currentMainViewBoundary-5) {
                
                UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[view]];
                CGPoint fromPoint=CGPointMake(0,bounds.size.height-action.bottomMargin);
                CGPoint toPoint=CGPointMake(4000,bounds.size.height-action.bottomMargin);
                
                [collisionBehavior addBoundaryWithIdentifier:@"menuBoundary"
                                                   fromPoint:fromPoint
                                                     toPoint:toPoint];
                [self addChildBehavior:collisionBehavior];
                
                [_gravityBehavior addItem:view];

            }
        }
    }
}
@end
