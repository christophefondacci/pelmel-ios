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
#import "TogaytherService.h"

@implementation PMLCountersView {
    UIDynamicAnimator *_animator;

    PMLHelpBubble *_checkinHelpBubble;
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
            imageView.image = [UIImage imageNamed:imageName];
            labelView.textColor = UIColorFromRGB(0xc3c3c4);
            if([_datasource counterActionAtIndex:i]!=PMLActionTypeNoAction) {
                UIView *containerView  = [self containerViewAtIndex:i];
                containerView.backgroundColor = [self colorForViewAtIndex:i];
                containerView.layer.borderWidth=1;
                containerView.layer.borderColor = [[UIColor colorWithWhite:1 alpha:0.3] CGColor];
                containerView.layer.cornerRadius = 5;
                containerView.layer.masksToBounds = YES;
                if([_datasource counterActionAtIndex:i]==PMLActionTypeCheckin) {
                    
                    if(_checkinHelpBubble == nil) {
                        [self layoutIfNeeded];
                        CGRect checkinRect = [self convertRect:_checkinsContainerView.frame toView:[[TogaytherService uiService] menuManagerController].view];
                        _checkinHelpBubble = [[PMLHelpBubble alloc ] initWithRect:checkinRect cornerRadius:checkinRect.size.width/2 helpText:NSLocalizedString(@"hint.checkin",@"hint.checkin") textPosition:PMLTextPositionTop whenSnippetOpened:NO];
                        
                        [[TogaytherService helpService] registerBubbleHint:_checkinHelpBubble forNotification:PML_HELP_CHECKIN];
                        [[TogaytherService helpService] registerBubbleHint:_checkinHelpBubble forNotification:PML_HELP_CHECKIN_CLOSE];
                    }
                    
                    if(![[[TogaytherService uiService] menuManagerController] snippetFullyOpened]) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:PML_HELP_CHECKIN object:self];
                    }
                }
            } else {
                UIView *containerView  = [self containerViewAtIndex:i];
                containerView.backgroundColor = [UIColor clearColor];
                containerView.layer.borderWidth=0;
                containerView.layer.borderColor=[[UIColor clearColor] CGColor];
            }

        } else {
            imageView.image = nil;
            UIView *containerView  = [self containerViewAtIndex:i];
            containerView.backgroundColor = [UIColor clearColor];
            containerView.layer.borderWidth=0;
            containerView.layer.borderColor=[[UIColor clearColor] CGColor];
        }
        
        UILabel *actionLabel = [self actionLabelAtIndex:i];
        actionLabel.text = [_datasource counterActionLabelAtIndex:i];
//        actionLabel.textColor = UIColorFromRGB(0x555555);
        
    }
}

- (UIColor*)colorForViewAtIndex:(NSInteger)i {
    if([_datasource isCounterSelectedAtIndex:i]) {
        return [UIColor colorWithWhite:1 alpha:0.25];
    } else {
        return [UIColor colorWithWhite:1 alpha:0.05];
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
-(UILabel*)actionLabelAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return self.likeActionLabel;
        case kPMLCounterIndexCheckin:
            return self.checkinActionLabel;
        case kPMLCounterIndexComment:
            return self.commentsActionLabel;
    }
    return nil;
}
- (UIView*)containerViewAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return self.likeIconContainerView;
        case kPMLCounterIndexCheckin:
            return self.checkinIconContainerView;
        case kPMLCounterIndexComment:
            return self.commentsIconContainerView;
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
                return @"ovvIconCheckinWhite";
            case PMLActionTypeAttend:
            case PMLActionTypeAttendCancel:
                return @"snpIconEvent";
            case PMLActionTypeComment:
                return @"ovvIconCommentWhite";
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

        // Getting view for user feedback interaction
        UIView *animatedView = [self containerViewAtIndex:index];
        UIColor *color = animatedView.backgroundColor;
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            animatedView.backgroundColor = [color colorWithAlphaComponent:0.3];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                animatedView.backgroundColor = [self colorForViewAtIndex:index];
            } completion:NULL];
        }];
        
        // Executing command
        [[TogaytherService actionManager] execute:type onObject:_datasource.counterObject];
    }
}
@end
