//
//  UIWaitingView.m
//  PelMel
//
//  Created by Christophe Fondacci on 07/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "UIWaitingView.h"
#import <QuartzCore/QuartzCore.h>

#define OFFSET  0.02
@implementation UIWaitingView {
    BOOL animate;
    double angle,offset;
    int count;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        animate = NO;
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

- (void)animate {
    if(!animate) {
        CABasicAnimation* scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation.fromValue = [NSNumber numberWithFloat:.8];
        scaleAnimation.toValue = [NSNumber numberWithFloat:1];
        scaleAnimation.duration = .16;
        
        CABasicAnimation* alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        alphaAnimation.fromValue = [NSNumber numberWithFloat:0];
        alphaAnimation.toValue = [NSNumber numberWithFloat:1];
        alphaAnimation.duration = 0.33;
        
        CAAnimationGroup* group = [CAAnimationGroup animation];
        group.animations = [NSArray arrayWithObjects:alphaAnimation, scaleAnimation, nil];
        group.duration = 0.33;
        
        [self.layer addAnimation:group forKey:nil];
        count=0;
        NSLog(@"Anim Init");
        offset = OFFSET;
    }
    animate = YES;
//
//    [UIView animateWithDuration:0.002f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
//        self.outsideImageView.transform = CGAffineTransformMakeRotation(angle);
//        angle = angle+offset;
//        offset = OFFSET + (sin(angle*3))/60;
//        count++;
//    } completion:^(BOOL finished) {
//        if(animate) {
//
//            [self animate];
//        }
//    }];
}

- (void)stopAnimation {
    animate = NO;
    NSLog(@"Iterated %d times",count);
}
@end
