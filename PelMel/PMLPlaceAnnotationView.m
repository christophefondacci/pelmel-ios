//
//  MKPlaceAnnotationView.m
//  PelMel
//
//  Created by Christophe Fondacci on 21/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLPlaceAnnotationView.h"
#import "UIAttachmentView.h"
#import "MapAnnotation.h"
#import "MKNumberBadgeView.h"
#import "UIPopBehavior.h"

@implementation PMLPlaceAnnotationView {
    UIImageView *_imageView;
    MKNumberBadgeView *_badgeView;
    UIDynamicAnimator *_animator;
    
    NSMutableArray *_actionViews;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _imageView = [[UIImageView alloc] init];
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
        _badgeView = [[MKNumberBadgeView alloc] init];
        _badgeView.shadow = NO;
        _badgeView.shine=NO;
        _actionViews = [[NSMutableArray alloc] init];
        [self addSubview:_imageView];
    }
    return self;
}



- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event
{

    if (!self.hidden && self.alpha > 0) {
        for (UIView *subview in self.subviews) {
//            if([subview isKindOfClass:[UIButton class]] || [subview isKindOfClass:[UIImageView class]]) {
                CGPoint subPoint = [subview convertPoint:point fromView:self];
                UIView *result = [subview hitTest:subPoint withEvent:event];
                if ([result isKindOfClass:[UIButton class]] || result.gestureRecognizers.count>0 ) {

                    return result;
                } else
                if(result!=nil && ([subview isKindOfClass:[UIButton class]] || subview.gestureRecognizers.count>0)) {
                    return subview;
                }
//            }
        }
    }
    
    return nil;
}

//- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event
//{
//    CGRect rect = self.bounds;
//    BOOL isInside = CGRectContainsPoint(rect, point);
//    if(!isInside)
//    {
//        for (UIView *view in self.subviews)
//        {
//            isInside = CGRectContainsPoint(view.frame, point);
//            if(isInside)
//                break;
//        }
//    }
//    return isInside;
//}


- (void)setImage:(UIImage *)image {
    if(_sizeRatio != nil && !isnan(_sizeRatio.floatValue) && image !=nil) {
        _imageView.image = image;
        _imageView.layer.opacity=1;
        
        CGSize size = image.size;
        float sizeRatio = _sizeRatio.floatValue;
        CGSize scaledSize = CGSizeMake(size.width*sizeRatio, size.height*sizeRatio);
        
        _imageView.frame = CGRectMake(0, 0, scaledSize.width, scaledSize.height);
        self.bounds = CGRectMake(0, 0, scaledSize.width, scaledSize.height);
        // Debug borders
//        self.layer.borderColor = [[UIColor redColor] CGColor];
//        self.layer.borderWidth = 1;
        super.centerOffset = CGPointMake((float)self.imageCenterOffset.x*sizeRatio, self.imageCenterOffset.y*sizeRatio);

        MapAnnotation *annotation = (MapAnnotation*) self.annotation;
        CALObject *object = annotation.object;
        NSInteger badgeVal = object.likeCount;
        if([object isKindOfClass:[Place class]]) {
            badgeVal+=((Place*)object).inUserCount;
        }

        if(badgeVal>0) {
            _imageView.clipsToBounds=NO;
            _badgeView.hidden=NO;
            _badgeView.frame = CGRectMake(10, 0, scaledSize.width+10, 20);
            _badgeView.font = [UIFont fontWithName:PML_FONT_BADGES size:10];
            _badgeView.value = badgeVal;
            [_imageView addSubview: _badgeView]; //Add NKNumberBadgeView as a subview on UIButton

        } else {
            [_badgeView removeFromSuperview];
        }
    } else {
        [super setImage:image];
    }
}

- (void)setCenterOffset:(CGPoint)centerOffset {
    // Doing nothing
}

@end
