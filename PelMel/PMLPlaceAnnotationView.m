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
#import "TogaytherService.h"


@implementation PMLPlaceAnnotationView {
    UIImageView *_imageView;
    MKNumberBadgeView *_badgeView;
    UIDynamicAnimator *_animator;
    
    NSMutableArray *_actionViews;
    BOOL _showLabel;
    
    CALObject *_observedObject;
    UIImage *_image;
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

- (void)setImage:(UIImage *)image {
    _image = image;
    [self refreshImage:image updateLabel:YES];
}

-(void)refreshImage:(UIImage*)image updateLabel:(BOOL)updateLabel{
    if(_sizeRatio != nil && !isnan(_sizeRatio.floatValue) && image !=nil) {
        _imageView.image = image;
        _imageView.layer.opacity=1;
        
        CGSize size = image.size;
        float sizeRatio = _sizeRatio.floatValue;
        CGSize scaledSize = CGSizeMake(size.width*sizeRatio, size.height*sizeRatio);
        
        _imageView.frame = CGRectMake(0, 0, scaledSize.width, scaledSize.height);
        self.bounds = CGRectMake(0, 0, scaledSize.width, scaledSize.height);
        super.centerOffset = CGPointMake((float)self.imageCenterOffset.x*sizeRatio, self.imageCenterOffset.y*sizeRatio);

        // Badge management
        [self updateBadge];

        // Title on top of marker
        MapAnnotation *annotation = (MapAnnotation*) self.annotation;
        
        // Registering observers
        [self registerObservers:annotation.object];
        
        if([annotation.object isKindOfClass:[Place class]]) {
            [_titleLabel removeFromSuperview];
            _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(-30, -20, 60+scaledSize.width, 20)];
            _titleLabel.textAlignment = NSTextAlignmentCenter;
            _titleLabel.font = [UIFont fontWithName:@"Avenir-MediumOblique" size:11];
            _titleLabel.textColor = UIColorFromRGB(0xe86900);
            _titleLabel.text = ((Place*)annotation.object).title;
//            if(updateLabel){
                _titleLabel.hidden=NO;
                _titleLabel.alpha=0;
                self.showLabel = NO;
//            }
            [_imageView addSubview:_titleLabel];
        }
    } else {
        [super setImage:image];
    }
}
- (void)dealloc {
    [self clearObservers];
}
-(void)clearObservers {
    if(_observedObject != nil) {
        [_observedObject removeObserver:self forKeyPath:@"inUserCount" context:NULL];
        [_observedObject removeObserver:self forKeyPath:@"likeCount" context:NULL];
    }
    _observedObject = nil;
}
-(void)registerObservers:(CALObject*)object {
    [self clearObservers];
    _observedObject = object;
    [_observedObject addObserver:self forKeyPath:@"inUserCount" options:NSKeyValueObservingOptionNew context:NULL];
    [_observedObject addObserver:self forKeyPath:@"likeCount" options:NSKeyValueObservingOptionNew context:NULL];
}
-(void) updateBadge {
    MapAnnotation *annotation = (MapAnnotation*) self.annotation;
    CALObject *object = annotation.object;
    
    NSInteger badgeVal = 0;
    if([object isKindOfClass:[Place class]]) {
        badgeVal+=((Place*)object).inUserCount;
    }
    [_badgeView removeFromSuperview];
    if(badgeVal>0) {
        _imageView.clipsToBounds=NO;
        _badgeView.hidden=NO;
        
        // Computing position
        CGSize size = _imageView.image.size;
        float sizeRatio = _sizeRatio.floatValue;
        CGSize scaledSize = CGSizeMake(size.width*sizeRatio, size.height*sizeRatio);
        
        // Positioning
        _badgeView.frame = CGRectMake(10, 0, scaledSize.width+10, 20);
        _badgeView.font = [UIFont fontWithName:PML_FONT_BADGES size:10];
        _badgeView.value = badgeVal;
        [_imageView addSubview: _badgeView]; //Add NKNumberBadgeView as a subview on UIButton
    }
    [_imageView layoutSubviews];
}
- (void)setCenterOffset:(CGPoint)centerOffset {
    // Doing nothing
}

- (void)updateData {
    [self updateSizeRatio];
    [self refreshImage:_image updateLabel:NO];
    [self updateBadge];
}
-(void)setShowLabel:(BOOL)showLabel {
    float alpha = showLabel ? 1 : 0;
    _showLabel = showLabel;
    [UIView animateWithDuration:0.5 animations:^{
        _titleLabel.alpha=alpha;
    }];
}
- (BOOL)showLabel {
    return _showLabel;
}
- (void)updateSizeRatio {
    // Size computation
    double ratio = 0;
    int maxLikes =[[[TogaytherService dataService] modelHolder] maxLikes];
    CALObject *object = ((MapAnnotation*)self.annotation).object;
    if( maxLikes > 0) {
        long count = object.likeCount;
        if([object isKindOfClass:[Place class]]) {
            count += ((Place*)object).inUserCount;
        }
        if(count>maxLikes) {
            [[[TogaytherService dataService] modelHolder] setMaxLikes:count];
        }
        ratio = ((double)count) / (double)maxLikes;
    }
    if([object isKindOfClass:[City class] ]) {
        ratio = 2;
    }
    self.sizeRatio = @(MIN(ratio*0.3+0.7,1));
}
#pragma mark - KVO Observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateData];
    });

}
@end
