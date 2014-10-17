//
//  DynamicObject.m
//  DynamicsTest
//
//  Created by Christophe Fondacci on 12/07/14.
//  Copyright (c) 2014 Pelmel. All rights reserved.
//

#import "DynamicObject.h"

@implementation DynamicObject {
    UIView *_view;
    double x, y;
    int _index;
    CGAffineTransform _transform;
    CGRect bounds;
    
    BOOL _reverse;
}

- (instancetype)initWithView:(UIView *)view withIndex:(int)index reverse:(BOOL)reverse
{
    self = [super init];
    if (self) {
        _view = view;
        bounds = _view.bounds;
        x = 100.0*index;
        y = 100.0;
        _index = index;
        _reverse = reverse;
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
    double factor =(_reverse ? (100-y) : y)/100.0;
    // Adding 5 to compensate bounds width of 10 
    _view.bounds = CGRectMake(0,0, factor*bounds.size.width+5, factor*bounds.size.height+5);
}
- (CGAffineTransform)transform {
    return _transform; //_view.transform;
}
- (void)setTransform:(CGAffineTransform)transform {
//    _view.transform = transform;
}
- (void)reset {
    _view.bounds = bounds;
}
@end
