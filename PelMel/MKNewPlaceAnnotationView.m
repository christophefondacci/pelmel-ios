//
//  MKNewPlaceAnnotationView.m
//  PelMel
//
//  Created by Christophe Fondacci on 29/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "MKNewPlaceAnnotationView.h"

@implementation MKNewPlaceAnnotationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event
{
    if (!self.hidden && self.alpha > 0) {
        for (UIView *subview in self.subviews) {
            CGPoint subPoint = [subview convertPoint:point fromView:self];
            UIView *result = [subview hitTest:subPoint withEvent:event];
            if ([result isKindOfClass:[UIButton class]] || result.gestureRecognizers.count>0 ) {
                return result;
            } else if(result!=nil&& ([subview isKindOfClass:[UIButton class]] || subview.gestureRecognizers.count>0)) {
                return subview;
            }
        }
    }
    
    return nil;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event
{
    CGRect rect = self.bounds;
    BOOL isInside = CGRectContainsPoint(rect, point);
    if(!isInside)
    {
        for (UIView *view in self.subviews)
        {
            isInside = CGRectContainsPoint(view.frame, point);
            if(isInside)
                break;
        }
    }
    return isInside;
}


@end
