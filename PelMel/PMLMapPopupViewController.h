//
//  MapPopupViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 19/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TogaytherService.h"
#import "PopupAction.h"

/**
 * This is the controller for map interactions using a popup
 */
@interface PMLMapPopupViewController : NSObject <PMLDataListener, PMLImagePickerCallback>

@property (nonatomic,retain,readonly) MapViewController *controller;

/**
 * Initializes the controller for the given object in the parent view.
 * For now the parent view is expected to be a MKAnnotationView but since we only
 * need UIView features we keep it generic
 * 
 * @param object the parent object from which content will be used
 * @param view the view in which the subviews will be created
 */
-(instancetype)initWithObject:(CALObject*)object inParentView:(MKAnnotationView*)view withController:(MapViewController*)controller;

/**
 * Dismisses everything from the parent view, removes all views, etc.
 */
-(void)dismiss;

/**
 * Builds the given actions as popup satellites
 */
-(void)buildActions:(NSArray*)popupActions;

/**
 * Refreshes the popup actions by requerying the popup action manager,
 * dismissing the actions no longer used and adding the new ones, animated
 */
-(void)refreshActions;

/**
 * Updates the badge of a popup action with the given number
 * @param action the PopupAction to display badge on
 * @param label the number to put in the badge
 */
-(void)updateBadgeFor:(PopupAction*)action with:(int)number;
@end
