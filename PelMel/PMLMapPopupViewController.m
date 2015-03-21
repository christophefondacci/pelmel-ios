//
//  MapPopupViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 19/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLMapPopupViewController.h"
#import "UIPopBehavior.h"
#import "APLDecorationView.h"
#import "UIAttachmentView.h"
#import "UIMapOptionView.h"
#import "PMLPlaceAnnotationView.h"
#import "PMLPopupActionManager.h"
#import "PopupAction.h"
#import "UITouchBehavior.h"
#import "MKNumberBadgeView.h"
#import "PMLOpenActionBehavior.h"
#import "PMLDataManager.h"

#define kPMLMainRadius 100.0 // Radius of the main title box
#define kPMLDistance 20.0
#define kPMLBorderWidth 3.0

#define kPMLActionIconMargin 5.0

@interface PMLMapPopupViewController ()

@end

@implementation PMLMapPopupViewController {
    
    // External elements
    CALObject *_object;
    MKAnnotationView *_parentView;
    
    // Created elements
    UIImageView *objectMainView;
    UIButton *_mainButton;
    NSMutableArray *_popupViews;
    UIAttachmentView *_attachmentView;
    UIView *opacityView;
    
    // Action manager
    PMLPopupActionManager *_popupActionManager;
    NSMutableArray *_popupActions;
    NSMutableDictionary *_actionsViewMap;
    NSMutableDictionary *_attachmentsViewMap;
    BOOL _menuOpened;
    
    // Internal variables
    UIDynamicAnimator *_animator;
    UIDynamicAnimator *_actionsAnimator;
    UIPopBehavior *_popBehavior;
    BOOL _likeDisplayed;
    CGPoint _center;
    CALImage *_currentMainImage;
}

- (instancetype)initWithObject:(CALObject *)object inParentView:(MKAnnotationView *)view withController:(MapViewController *)controller
{
    self = [super init];
    if (self) {
        NSLog(@"INIT");
        // Storing variables
        _object = object;
        _parentView = view;
        _controller = controller;
        _likeDisplayed = NO;
        _popupViews = [[NSMutableArray alloc] init];
        _actionsViewMap = [[NSMutableDictionary alloc] init];
        _attachmentsViewMap = [[NSMutableDictionary alloc] init];
        _popupActions = [[NSMutableArray alloc] init];
        _popupActionManager = _controller.popupActionManager;
        
        // Initializing awesome stuff
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:view];
        _actionsAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:view];
        
        // Arranging photos arround
        CGRect centralRect = _parentView.bounds;
        _center = CGPointMake(CGRectGetMidX(centralRect)-_parentView.centerOffset.x,CGRectGetMidY(centralRect));
        
        // Pin annotation view is de-centered due to shadow
        if([_parentView isKindOfClass:[MKPinAnnotationView class]]) {
            _center.x -= 10;
        }
        
        // Building frame
        CGRect mainBox = CGRectMake(_center.x-kPMLMainRadius/2, centralRect.origin.y-kPMLDistance-kPMLMainRadius, kPMLMainRadius, kPMLMainRadius);
        _mainButton = [[UIButton alloc] initWithFrame:mainBox];
        
        // Zooming map on center of mainbox
//        CLLocationCoordinate2D coords = [controller.mapView convertPoint:_mainButton.center toCoordinateFromView:view];
//        [controller.mapView setCenterCoordinate:coords animated:YES];

        
        // Building main object view: the main image
        objectMainView = [[UIImageView alloc] initWithFrame:_mainButton.bounds];
        [_object addObserver:self forKeyPath:@"mainImage" options:NSKeyValueObservingOptionNew context:NULL];
        CALImage *calImage = [[TogaytherService imageService] imageOrPlaceholderFor:_object allowAdditions:YES];
        _currentMainImage = calImage;
        [[TogaytherService imageService] load:calImage to:objectMainView thumb:NO];

        objectMainView.layer.cornerRadius = kPMLMainRadius/2-2;
        objectMainView.layer.masksToBounds = YES;
        objectMainView.contentMode = UIViewContentModeScaleAspectFill;
        objectMainView.backgroundColor = [UIColor orangeColor];
        objectMainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        objectMainView.layer.borderWidth = kPMLBorderWidth;
        objectMainView.layer.borderColor = [[UIColor whiteColor] CGColor];
        
        _mainButton.layer.cornerRadius = kPMLMainRadius/2;
        _mainButton.layer.shadowOffset = CGSizeMake(1, 1);
        _mainButton.layer.shadowRadius = 4;
        _mainButton.layer.shadowOpacity = 0.7;
//        _mainButton.layer.shadowPath = [[UIBezierPath bezierPathWithRoundedRect:_mainButton.bounds cornerRadius:kPMLMainRadius/2] CGPath];
        [_mainButton addTarget:self action:@selector(imageTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        // Adding to parent view
        UIImageView *background = [[UIImageView alloc] initWithFrame:_mainButton.bounds];
        background.layer.cornerRadius = kPMLMainRadius/2;
        background.layer.masksToBounds=YES;
        background.image = [UIImage imageNamed:@"imgBlankAdd"];
        background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_mainButton addSubview:background];
        [_mainButton addSubview:objectMainView];
        [_parentView addSubview:_mainButton];
        
        _attachmentView = [[UIAttachmentView alloc] initWithFrame:CGRectUnion(mainBox, _parentView.bounds)];
        [_parentView insertSubview:_attachmentView atIndex:0];
        
        // Computing attachment offset
        CGPoint offset = CGPointMake(-_parentView.centerOffset.x, -_center.y);
        [_attachmentView attachFromView:_mainButton toView:_parentView offset:offset];
        
        // Getting actions
        [_popupActionManager dismiss];
        NSArray *popupActions = [_popupActionManager computeActionsFor:_object annotatedBy:(MapAnnotation*)view.annotation fromController:self];
        [self buildActions:popupActions];
        
        // Animating
        _menuOpened = NO;
        _popBehavior = [[UIPopBehavior alloc] initWithViews:@[_mainButton] pop:YES delay:NO completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @synchronized(self) {
                    if(objectMainView !=nil) {
                        [self openMenuActions:popupActions];
                    }
                }
            });
        }];
        _popBehavior.elasticity=0.3;
        [_animator addBehavior:_popBehavior];


    }
    return self;
}

        
-(void)buildActions:(NSArray*)popupActions {
    // Preparing array of views for animation
    NSMutableArray *views = [[NSMutableArray alloc] init];
    
    // Building all actions
    for(PopupAction *action in popupActions) {
        
        NSString *key = [self keyFor:action];
        
        // Only if not yet created (we should not recreate a pre-existing action)
        if([_actionsViewMap objectForKey:key] == nil) {
            // Appending action
            [_popupActions addObject:action];
            
            // Computing sticker position
            double actionDistance = action.distance.doubleValue;
            double actionSize = action.size.doubleValue;
            int x = _mainButton.center.x+(kPMLMainRadius/2 +actionDistance+actionSize/2)*cos([action.angle doubleValue])+action.xOffset;
            int y = _mainButton.center.y+(kPMLMainRadius/2 +actionDistance+actionSize/2)*sin([action.angle doubleValue])+action.yOffset;
            
            // Building frame for like image
            double size = [action.size doubleValue];
            CGRect imageFrame = CGRectMake(x-size/2, y-size/2, size, size);
            
            
            // Loading image
            UIView *view;
            if(action.icon && action.title) {
                UIButton *optionsButtonView = [[UIButton alloc] initWithFrame:imageFrame];
                
                optionsButtonView.layer.cornerRadius = size/2;
                optionsButtonView.layer.shadowOffset = CGSizeMake(5, 5);
                optionsButtonView.layer.shadowRadius = 5;
                optionsButtonView.layer.shadowOpacity = 0.5;
                optionsButtonView.tag = [_popupActions indexOfObject:action];
                
                [optionsButtonView addTarget:self action:@selector(actionTapped:) forControlEvents:UIControlEventTouchUpInside];
                
                
                NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:@"UIMapOptionView" owner:self options:nil];
                UIMapOptionView *optionsView = [nibViews objectAtIndex:0];
                
                
                //            optionsView.frame = optionsView.bounds;
                optionsView.layer.cornerRadius = size/2;
                optionsView.layer.backgroundColor = action.color.CGColor;
                optionsView.optionImage.image = action.icon;
                optionsView.optionText.text = action.title;
                optionsView.layer.borderColor= [[UIColor whiteColor] CGColor];
                optionsView.layer.borderWidth= kPMLBorderWidth;
                optionsView.frame = CGRectMake(0, 0, size, size);
                
                // Adjusting image position and size due to autolayout bug
                CGRect txtFrame = optionsView.optionText.frame;
                CGRect frame = optionsView.bounds;
                double height = frame.size.height - (txtFrame.origin.y + txtFrame.size.height)-kPMLActionIconMargin*2;
                optionsView.optionImage.frame = CGRectMake(CGRectGetMidX(frame)-height/2, txtFrame.origin.y + txtFrame.size.height+kPMLActionIconMargin, height, height);
                
                [optionsButtonView addSubview:optionsView];
                
                view = optionsButtonView;
                
            } else {
                UIButton *optionsButtonView = [[UIButton alloc] initWithFrame:imageFrame];
                
                optionsButtonView.layer.cornerRadius = size/2;
                optionsButtonView.layer.shadowOffset = CGSizeMake(5, 5);
                optionsButtonView.layer.shadowRadius = 5;
                optionsButtonView.layer.shadowOpacity = 0.5;
                optionsButtonView.tag = [_popupActions indexOfObject:action];
                optionsButtonView.clipsToBounds = NO;
                [optionsButtonView addTarget:self action:@selector(actionTapped:) forControlEvents:UIControlEventTouchUpInside];
                
                UIImageView *likeView = [[UIImageView alloc] initWithFrame:optionsButtonView.bounds];
                likeView.layer.cornerRadius = size/2;
                likeView.layer.masksToBounds= YES;
                likeView.contentMode = UIViewContentModeScaleAspectFill;
                likeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                likeView.layer.borderWidth=kPMLBorderWidth;
                likeView.backgroundColor = action.color;
                likeView.layer.borderColor = action.color.CGColor;
                likeView.tag = [_popupActions indexOfObject:action];
                //            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTapped:)];
                //
                //            [likeView addGestureRecognizer:tapRecognizer];
                //            likeView.userInteractionEnabled=YES;
                if(action.image) {
                    [[TogaytherService imageService] load:action.image to:likeView thumb:YES];
                } else if(action.icon) {
                    likeView.image = action.icon;
                    if(action.color) {
                        likeView.layer.borderColor = action.color.CGColor;
                    }
                }
                [optionsButtonView addSubview:likeView];
                view = optionsButtonView;
            }
            if(_menuOpened) {
                [_parentView addSubview:view];
            }
            
            // Tracking for grouped popped and global registering
            [views addObject:view];
            [_popupViews addObject:view];
            // Badge management
            [_actionsViewMap setObject:view forKey:key];
            if(action.badgeValue) {
                [self updateBadgeFor:action with:action.badgeValue.intValue];
            }
            
            //        NSLog(@"Action center x=%.2f y=%.2f",view.center.x,view.center.y);
            
            
            // Computing attachment size
            double attachmentSize = action.distance.doubleValue; // - kPMLMainRadius/2 - action.size.doubleValue/2;
            double attachmentDistance = kPMLMainRadius/2;
            double attachmentAngle = action.angle.doubleValue;
            UIImageView *attachmentView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"attachment"]];
            
            // Setting up position
            if(action.showAttachment) {
                attachmentView.frame = CGRectMake(_mainButton.center.x + attachmentDistance, _mainButton.center.y-attachmentView.bounds.size.height/2, attachmentSize, attachmentView.bounds.size.height);
                
                double xTranslate=_mainButton.center.x-attachmentView.center.x;
                double yTranslate=_mainButton.center.y-attachmentView.center.y;
                CGAffineTransform transform = CGAffineTransformMakeTranslation(xTranslate, yTranslate);
                transform = CGAffineTransformRotate(transform, attachmentAngle);
                transform = CGAffineTransformTranslate(transform,-xTranslate,-yTranslate);
                
                // Setting up center of rotation to main button
                attachmentView.transform=transform;
                [_parentView addSubview:attachmentView];
                [_attachmentsViewMap setObject:attachmentView forKey:key];
                // Animating
                attachmentView.alpha=0;
                
            }
        } else {
            UIView *actionView = [_actionsViewMap objectForKey:key];
            actionView.tag = [_popupActions indexOfObject:action];
        }
    }
}
-(NSString*)keyFor:(NSObject*)object {
    return [NSString stringWithFormat:@"%p",object];
}

-(void)openMenuActions:(NSArray*)animatedActions {
    if(!_menuOpened) {
        [_actionsAnimator removeAllBehaviors];
        _menuOpened = YES;
        
        NSMutableArray *popupViews = [[NSMutableArray alloc] init];
        // For every given action
        for(PopupAction *action in animatedActions) {
            
            UIView *popupView = [_actionsViewMap objectForKey:[self keyFor:action]];
            UIView *attachmentView = [_attachmentsViewMap objectForKey:[self keyFor:action]];
            
            // Adding popup views under main button (which will hide their initial or final state)
            [_parentView insertSubview:popupView belowSubview:_mainButton];

            // Initiating fade in apparition of attachments
            [UIView animateWithDuration:0.5 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                attachmentView.alpha=1;
            } completion:nil];

            // Preparing views table for grouped open behavior
            [popupViews addObject:popupView];
        }
        PMLOpenActionBehavior *openBehavior = [[PMLOpenActionBehavior alloc] initWithViews:popupViews forActions:animatedActions center:_mainButton.center radius:kPMLMainRadius open:YES];
        [_actionsAnimator addBehavior:openBehavior];
    }
}

-(void)refreshActions {
    // Querying popup actions again
    NSArray *newActions = [_popupActionManager computeActionsFor:_object annotatedBy:(MapAnnotation*)_parentView.annotation fromController:self];
    
    // Building a "to remove" and "to add" list
    NSMutableArray *toRemove = [[NSMutableArray alloc] init];
    NSMutableArray *toAdd = [[NSMutableArray alloc] init];
    NSMutableSet *newActionsKeys = [[NSMutableSet alloc] init];
    
    // Computing "to add"
    for(PopupAction *action in newActions) {
        // If action was not here already -> to add
        if([_actionsViewMap objectForKey:[self keyFor:action]]==nil) {
            [toAdd addObject:action];
        }
        // Hashing its key for to remove computation
        [newActionsKeys addObject:[self keyFor:action]];
    }
    // Computing "to remove"
    NSMutableArray *toRemoveViews = [[NSMutableArray alloc] init];
    for(PopupAction *action in _popupActions) {
        // If action is no longer here -> to remove
        NSString *key = [self keyFor:action];
        if(![newActionsKeys containsObject:key]) {
            [toRemove addObject:action];
            [toRemoveViews addObject:[_actionsViewMap objectForKey:key]];
        }
    }
    
    // Preparing animation
    PMLOpenActionBehavior *closeBehavior = [[PMLOpenActionBehavior alloc] initWithViews:toRemoveViews forActions:toRemove center:_mainButton.center radius:kPMLMainRadius open:NO];
    closeBehavior.completionCallback = ^{
        
        // Removing actions definitively
        [self cleanActions:toRemove];
        
        // Opening new actions
        [self buildActions:newActions];
        _menuOpened = NO;
        [self openMenuActions:toAdd];
    };
    
    // Animating
    [_actionsAnimator removeAllBehaviors];
    if(toRemoveViews.count>0) {
        [_actionsAnimator addBehavior:closeBehavior];
    } else {
        // If nothing to remove, we simply open new actions
        closeBehavior.completionCallback();
    }
}
-(void)updateBadgeFor:(PopupAction*)action with:(int)number {
    
    // Getting corresponding view
    UIView *actionView = [_actionsViewMap objectForKey:[NSString stringWithFormat:@"%p",action]];
    if(actionView) {
        MKNumberBadgeView *badgeView;
        // Locating any pre-existing badge view
        for(UIView *subview in actionView.subviews) {
            if([subview isKindOfClass:[MKNumberBadgeView class]]) {
                badgeView = (MKNumberBadgeView*)subview;
                break;
            }
        }
        // Creating if needed
        if(!badgeView) {
            badgeView = [[MKNumberBadgeView alloc] init];
            int size = [action.size intValue];
            badgeView.frame = CGRectMake(size-20, -5, 28, 28);
//            badgeView.font = [UIFont boldSystemFontOfSize:12];
            badgeView.shine=NO;
            badgeView.shadow=NO;
            badgeView.font = [UIFont fontWithName:PML_FONT_BADGES size:12];
            [actionView addSubview:badgeView];
        }
        // Updating content
        [badgeView setValue:number];
    }
}
-(void)dismiss {
//    NSLog(@"DISMISS");
    if(objectMainView != nil) {
        @synchronized(self) {
            [_animator removeAllBehaviors];
            [_actionsAnimator removeAllBehaviors];
            [_popupActionManager dismiss];
            [_mainButton removeFromSuperview];
            [_attachmentView removeFromSuperview];
            [self cleanActions:_popupActions];
            [_object removeObserver:self forKeyPath:@"mainImage" context:nil];
            objectMainView = nil;
        }
    } else {
        NSLog(@"WARN: NOTHING TO DISMISS");
    }
}
- (void)dealloc {
    [self dismiss];
}
-(void)cleanActions:(NSArray*)actions {
    for(PopupAction *action in [NSArray arrayWithArray:actions]) {
        
        // Getting elements
        NSString *key = [self keyFor:action];
        UIView *actionView = [_actionsViewMap objectForKey:key];
        UIView *attachmentView = [_attachmentsViewMap objectForKey:key];
        
        // UIView removal
        [actionView removeFromSuperview];
        [attachmentView removeFromSuperview];
        
        // Internal structures cleanup
        [_actionsViewMap removeObjectForKey:key];
        [_attachmentsViewMap removeObjectForKey:key];
        [_popupActions removeObject:action];
    }
}


-(void)imageTapped:(id)sender {
    // When no image, we offer to upload one
    if(_object.mainImage == nil) {
        if(_object.key!=nil) {
            [self.controller.parentMenuController.dataManager promptUserForPhotoUploadOn:_object];
        }
    } else {
        [[TogaytherService uiService] presentSnippetFor:_object opened:YES];
//        [_controller.parentMenuController openCurrentSnippet:YES];
    }
}
-(void)actionTapped:(UIButton*)sender {
    
    if(_popupActions.count>sender.tag) {
        [_animator removeAllBehaviors];
        UITouchBehavior *touchBehavior = [[UITouchBehavior alloc] initWithTarget:sender];
        [_animator addBehavior:touchBehavior];
        PopupAction *action = [_popupActions objectAtIndex:sender.tag];
        if(action.actionCommand != nil) {
            action.actionCommand();
        }
    }
}
#pragma mark - KVO observation callback
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"mainImage"]) {
        CALImage *image = ((CALObject*)object).mainImage;
        if(![image.key isEqualToString:_currentMainImage.key]) {
            [[TogaytherService imageService] load:((CALObject*)object).mainImage to:objectMainView thumb:NO];
        }
    }
}


@end
