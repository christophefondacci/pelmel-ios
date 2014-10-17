//
//  MKCustomMapView.m
//  PelMel
//
//  Created by Christophe Fondacci on 21/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "MKCustomMapView.h"
#import "PMLPlaceAnnotationView.h"

@implementation MKCustomMapView

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

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if([view isKindOfClass:[PMLPlaceAnnotationView class]]) {
        return nil;
    } else {
        return view;
    }
}
@end
