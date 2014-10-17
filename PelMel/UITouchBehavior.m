//
//  UITouchBehaviour.m
//  PelMel
//
//  Created by Christophe Fondacci on 27/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "UITouchBehavior.h"
#import "APLPositionToBoundsMapping.h"

@implementation UITouchBehavior

- (instancetype)initWithTarget:(UIView *)view
{
    self = [super init];
    if (self) {
        // APLPositionToBoundsMapping maps the center of an id<ResizableDynamicItem>
        // (UIDynamicItem with mutable bounds) to its bounds.  As dynamics modifies
        // the center.x, the changes are forwarded to the bounds.size.width.
        // Similarly, as dynamics modifies the center.y, the changes are forwarded
        // to bounds.size.height.
        APLPositionToBoundsMapping *buttonBoundsDynamicItem = [[APLPositionToBoundsMapping alloc] initWithTarget:view];
        
        // Create an attachment between the buttonBoundsDynamicItem and the initial
        // value of the button's bounds.
        UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:buttonBoundsDynamicItem attachedToAnchor:buttonBoundsDynamicItem.center];
        [attachmentBehavior setFrequency:2.0];
        [attachmentBehavior setDamping:0.3];
        [self addChildBehavior:attachmentBehavior];
        
        UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[buttonBoundsDynamicItem] mode:UIPushBehaviorModeInstantaneous];
        pushBehavior.angle = M_PI_4;
        pushBehavior.magnitude = 1.0;
        [self addChildBehavior:pushBehavior];
        
        [pushBehavior setActive:TRUE];
    }
    return self;
}
@end
