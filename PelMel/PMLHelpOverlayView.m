//
//  PMLHelpOverlay.m
//  PelMel
//
//  Created by Christophe Fondacci on 02/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLHelpOverlayView.h"
#import "Arrow.h"

#define kPMLLabelWidth 200
#define kPMLLabelHeight 100
#define kPMLLabelSpacing 40

@implementation PMLHelpOverlayView {
    CAShapeLayer *_shapeLayer;
    UIBezierPath *_path;
    NSMutableArray *_labelViews;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _labelViews = [[NSMutableArray alloc] init];
//        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.frame = self.bounds;
        _shapeLayer.fillColor = [[UIColor blackColor] CGColor];
        _shapeLayer.fillRule = kCAFillRuleEvenOdd;
        _shapeLayer.opacity = 0.7;
        
        _path = [UIBezierPath bezierPathWithRect:self.bounds];
        _path.usesEvenOddFillRule=YES;
        _shapeLayer.path = _path.CGPath;
        [self.layer addSublayer:_shapeLayer];
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissOverlay:)];
        [self addGestureRecognizer:tapRecognizer];
        self.userInteractionEnabled=YES;
    }
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)layoutSubviews {
    [super layoutSubviews];
    
}


- (void)addHelpBubble:(PMLHelpBubble *)helpBubble {
    CGRect bubbleRect = CGRectInset(helpBubble.bubbleFrame, -10, -10);
//    bubbleRect = CGRectOffset(bubbleRect, -5, -5);
    
    [_path appendPath:[UIBezierPath bezierPathWithRoundedRect:bubbleRect cornerRadius:helpBubble.cornerRadius]];
    _shapeLayer.path = _path.CGPath;
    
    
    
    // Adding a transparent view for label relative positioning
    UIView *dummyView = [[UIView alloc] initWithFrame:bubbleRect];
    [self addSubview:dummyView];
    
    // Setting up label
    UILabel *label = [[UILabel alloc] init];
    label.text = helpBubble.helpText;
    label.font = [UIFont fontWithName:PML_FONT_HINTS size:14];
    label.textColor = [UIColor whiteColor];
    label.numberOfLines=0;
    
    
    
    // Setting frame and alignment
    CGRect frame;
    NSTextAlignment alignement;
    switch(helpBubble.textPosition) {
        case PMLTextPositionLeft: {
            frame =CGRectMake(MAX(bubbleRect.origin.x-kPMLLabelWidth-kPMLLabelSpacing,0), CGRectGetMidY(bubbleRect)-kPMLLabelHeight/2, kPMLLabelWidth, kPMLLabelHeight);
            alignement=NSTextAlignmentRight;
            
            // Creating and positioning arrow
            UIImageView *arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"help-arrow-right"]];
            CGRect arrowFrame = arrow.bounds;
            arrow.frame = CGRectMake(CGRectGetMinX(bubbleRect)-CGRectGetWidth(arrowFrame), CGRectGetMaxY(bubbleRect)-CGRectGetHeight(arrowFrame)/2, CGRectGetWidth(arrowFrame), CGRectGetHeight(arrowFrame));
            [self addSubview:arrow];
            break;
        }
        case PMLTextPositionTop: {
            frame = CGRectMake(CGRectGetMidX(bubbleRect)-kPMLLabelWidth/2, MAX(bubbleRect.origin.y-kPMLLabelHeight-kPMLLabelSpacing,0), kPMLLabelWidth, kPMLLabelHeight);
            alignement=NSTextAlignmentCenter;
            
            // Creating and positioning arrow
            UIImageView *arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"help-arrow-down"]];
            CGRect arrowFrame = arrow.bounds;
            arrow.frame = CGRectMake(CGRectGetMidX(bubbleRect)-CGRectGetWidth(arrowFrame)/2, CGRectGetMinY(bubbleRect)-CGRectGetHeight(arrowFrame), CGRectGetWidth(arrowFrame), CGRectGetHeight(arrowFrame));
            [self addSubview:arrow];
            break;
        }
        case PMLTextPositionBottom: {
            frame = CGRectMake(CGRectGetMidX(bubbleRect)-kPMLLabelWidth/2, MIN(bubbleRect.origin.y+bubbleRect.size.height+kPMLLabelSpacing,self.bounds.size.height), kPMLLabelWidth, kPMLLabelHeight);
            alignement=NSTextAlignmentCenter;
            // Creating and positioning arrow
            UIImageView *arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"help-arrow-up"]];
            CGRect arrowFrame = arrow.bounds;
            arrow.frame = CGRectMake(CGRectGetMidX(bubbleRect)-CGRectGetWidth(arrowFrame)/2, CGRectGetMaxY(bubbleRect), CGRectGetWidth(arrowFrame), CGRectGetHeight(arrowFrame));
            [self addSubview:arrow];
            break;
        }
        case PMLTextPositionRight:
            frame =CGRectMake(MIN(bubbleRect.origin.x+bubbleRect.size.width+kPMLLabelSpacing,self.bounds.size.width), CGRectGetMidY(bubbleRect)-kPMLLabelHeight/2, kPMLLabelWidth, kPMLLabelHeight);
            alignement=NSTextAlignmentLeft;
            // Creating and positioning arrow
            UIImageView *arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"help-arrow-left"]];
            CGRect arrowFrame = arrow.bounds;
            arrow.frame = CGRectMake(CGRectGetMaxX(bubbleRect), CGRectGetMaxY(bubbleRect)-CGRectGetHeight(arrowFrame)/2, CGRectGetWidth(arrowFrame), CGRectGetHeight(arrowFrame));
            [self addSubview:arrow];
            break;
    }
    label.frame = frame;
    label.textAlignment = alignement;
    [self addSubview:label];
//
//    NSDictionary *dic = @{ @"label":label};
//    NSArray *constraint_V = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[label(100)]"
//                                                                    options:0
//                                                                    metrics:nil
//                                                                      views:dic];
//    NSArray *constraint_H = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[label(200)]"
//                                                                    options:0
//                                                                    metrics:nil
//                                                                      views:dic];
//    
//    
//    NSLayoutConstraint *alignCenters = [NSLayoutConstraint constraintWithItem:label
//                                 attribute:NSLayoutAttributeCenterY
//                                 relatedBy:NSLayoutRelationEqual
//                                    toItem:dummyView
//                                 attribute:NSLayoutAttributeCenterY
//                                multiplier:1.f constant:0.f];
//    
////    NSArray *constraint_POS_V = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-30-[redView]"
////                                                                        options:0
////                                                                        metrics:nil
////                                                                          views:viewsDictionary];
//    dic = @{ @"bubble":dummyView, @"label":label};
//    NSArray *constraint_POS_H = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[label]-20-[bubble]"
//                                                                        options:0
//                                                                        metrics:nil
//                                                                          views:dic];
//    
//    [label addConstraints:constraint_V];
//    [label addConstraints:constraint_H];
//    [self addConstraint:alignCenters];
//    [self addConstraints:constraint_POS_H];
    
}
- (void)dismissOverlay:(UIGestureRecognizer*)recognizer {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha=0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
@end
