//
//  PMLDynamicActionObject.m
//  PelMel
//
//  Created by Christophe Fondacci on 18/08/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLDynamicActionObject.h"

@implementation PMLDynamicActionObject {
    PopupAction *_popupAction;
    UIView *_view;
    CGPoint _center;
    CGFloat _radius;
    
    
    CGFloat x, y;
    int _index;
    CGAffineTransform _transform;
    CGPoint _initialViewCenter;
    
    BOOL _reverse;
}

- (instancetype)initWithAction:(PopupAction *)action inView:(UIView *)view popCenter:(CGPoint)center centralRadius:(CGFloat)centralRadius reverse:(BOOL)reverse
{
    self = [super init];
    if (self) {
        _popupAction = action;
        _view = view;
        _center = center;
        _radius = centralRadius;
        _initialViewCenter = view.center;
        _reverse = reverse;
        x= 100;
        y= 100;
    }
    return self;
}

- (CGRect)bounds {
    return CGRectMake(0, 0, 10, 10);
}
- (CGPoint)center {
    return CGPointMake(x, y);
}
- (void)setCenter:(CGPoint)center {
    x = center.x;
    y = center.y;

    double val = _reverse ? 100.0-y : y;
    // Adding 5 to compensate bounds width of 10
    CGFloat viewX = _center.x + (val/100.0*(_radius/2+_popupAction.distance.doubleValue+_popupAction.size.doubleValue/2))*cos(_popupAction.angle.doubleValue);
    CGFloat viewY = _center.y + (val/100.0*(_radius/2+_popupAction.distance.doubleValue+_popupAction.size.doubleValue/2))*sin(_popupAction.angle.doubleValue);
    _view.center = CGPointMake(viewX, viewY);
}
- (CGAffineTransform)transform {
    return _view.transform;
}
- (void)setTransform:(CGAffineTransform)transform {
    //    _view.transform = transform;
}
- (void)reset {
    _view.center = _initialViewCenter;
}
@end