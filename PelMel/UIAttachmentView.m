//
//  UIAttachmentView.m
//  PelMel
//
//  Created by Christophe Fondacci on 20/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "UIAttachmentView.h"

@implementation UIAttachmentView {

    UIView *_attachedView;
    UIView *_attachmentView;
    
    CGPoint _offset;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)attachFromView:(UIView *)attachmentView toView:(UIView *)attachedView offset:(CGPoint)offset {
    
    // Saving info
    _attachedView = attachedView;
    _attachmentView = attachmentView;
    _offset = offset;
    
    // Adjusting connections
    CGPoint attachmentPointViewCenter = CGPointMake( CGRectGetMidX(_attachmentView.bounds), CGRectGetMidY(_attachmentView.bounds));
    attachmentPointViewCenter = [_attachmentView convertPoint:attachmentPointViewCenter toView:self];
    
    CGPoint attachedViewAttachmentPoint = CGPointMake( CGRectGetMidX(_attachedView.bounds) +offset.x, CGRectGetMidY(_attachedView.bounds)+offset.y);
    attachedViewAttachmentPoint =  [_attachedView convertPoint:attachedViewAttachmentPoint toView:self];
    
    // Adjusting bounds
//    self.bounds = CGRectMake(0, 0, abs(attachedViewAttachmentPoint.x-attachmentPointViewCenter.x), abs(attachedViewAttachmentPoint.y-attachmentPointViewCenter.y));
    
    
    UIBezierPath *connection = [UIBezierPath bezierPath];
    [connection moveToPoint:attachmentPointViewCenter];
    [connection addLineToPoint:attachedViewAttachmentPoint];

    connection.lineWidth=1;
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [connection CGPath];
    shapeLayer.strokeColor = [[UIColor blackColor] CGColor];
    shapeLayer.lineWidth = 1;
    shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    [self.layer addSublayer:shapeLayer];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
