//
//  PMLCountersView.m
//  PelMel
//
//  Created by Christophe Fondacci on 03/03/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLCountersView.h"
#import "UITouchBehavior.h"
#import "UIImage+IPImageUtils.h"
#import "PMLPopupActionManager.h"

@implementation PMLCountersView {
    UIDynamicAnimator *_animator;
}

- (void)awakeFromNib {
    _animator = [[UIDynamicAnimator alloc] init];
    
    // Wrapping actions
    self.likeContainerView.tag = 0;
    [self.likeContainerView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTapped:)]];
    self.checkinsContainerView.tag = 1;
    [self.checkinsContainerView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTapped:)]];
    self.commentsContainerView.tag = 2;
    [self.commentsContainerView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTapped:)]];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)reloadData {
    // Setting up labels & images
    for(NSInteger i = 0 ; i < 3 ; i++) {
        
        // Getting image & label view
        UIImageView *imageView = [self imageViewAtIndex:i];
        UILabel *labelView = [self labelViewAtIndex:i];
        
        // Getting image name from datasource
        NSString *imageName = [self counterImageNameAtIndex:i];
        NSString *label = [_datasource counterLabelAtIndex:i];
        
        // If selected we mask image & label with our selection color
        labelView.text = label;
        if(imageName != nil) {
            if([_datasource isCounterSelectedAtIndex:i]) {
                imageView.image = [UIImage ipMaskedImageNamed:imageName color:UIColorFromRGB(0xef6c00)];
                labelView.textColor =UIColorFromRGB(0xef6c00);
                
                if([_datasource counterActionAtIndex:i]!=PMLActionTypeNoAction) {
                    imageView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
                    imageView.layer.cornerRadius = 5;
                    imageView.layer.masksToBounds = YES;
                }
            } else {
                imageView.image = [UIImage imageNamed:imageName];
                labelView.textColor = UIColorFromRGB(0xc3c3c4);
            }
        } else {
            imageView.image = nil;
        }
        
    }
}

-(UILabel*)labelViewAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return self.likeTitleLabel;
        case kPMLCounterIndexCheckin:
            return self.checkinTitleLabel;
        case kPMLCounterIndexComment:
            return self.commentsTitleLabel;
    }
    return nil;
}
- (UIImageView*)imageViewAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return self.likeIcon;
        case kPMLCounterIndexCheckin:
            return self.checkinIcon;
        case kPMLCounterIndexComment:
            return self.commentsIcon;
    }
    return nil;
}
-(NSString *)counterImageNameAtIndex:(NSInteger)index {
    if([_datasource respondsToSelector:@selector(counterImageNameAtIndex:)]) {
        return [_datasource counterImageNameAtIndex:index];
    } else {
        PMLActionType action = [_datasource counterActionAtIndex:index];
        switch(action) {
            case PMLActionTypeCheckin:
            case PMLActionTypeAttend:
                return @"ovvIconCheckin";
            case PMLActionTypeComment:
                return @"ovvIconComment";
            case PMLActionTypeLike:
                return @"snpIconLikeWhite";
            default:
                return nil;
        }
    }
}
- (void)actionTapped:(UIGestureRecognizer*)recognizer {
    NSInteger index = recognizer.view.tag;
    PMLActionType type = [_datasource counterActionAtIndex:index];
    if(type != PMLActionTypeNoAction) {
        // Getting action
        PopupAction *action = [_datasource.actionManager actionForType:type];
        
        // Getting view for user feedback interaction
        UIView *animatedView = [self imageViewAtIndex:index];
        
        // Building animation
        UITouchBehavior *touch = [[UITouchBehavior alloc] initWithTarget:animatedView];
        [touch setMagnitude:0.5];
        [_animator removeAllBehaviors];
        [_animator addBehavior:touch];
        
        // Executing command
        action.actionCommand();
    }
}
@end
