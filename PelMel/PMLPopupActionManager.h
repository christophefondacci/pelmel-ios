//
//  PopupActionManager.h
//  PelMel
//
//  Created by Christophe Fondacci on 23/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALObject.h"
#import "DataService.h"
#import "PopupAction.h"
#import "PMLPopupEditor.h"

@class PMLMapPopupViewController;
@class MapAnnotation;

/**
 * The popup action manager is a central place to compute which actions should be
 * proposed given different contexts.
 */
@interface PMLPopupActionManager : NSObject <PMLDataListener,UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic,retain) PMLMapPopupViewController *popupController;
@property (nonatomic,retain) PMLMenuManagerController *menuManagerController;
//@property (nonatomic,retain) PMLPopupEditor *currentEditor;

/**
 * Instantiates a new action manager using the specified popup controller.
 * The popup controller could be used by the action manager to 'manually' add
 * new actions asynchronously.
 */
//-(instancetype)initWith:(PMLMapPopupViewController*)popupController;

/**
 * Instantiates an action manager dedicated to the given object using the provided menu manager
 */ 
-(instancetype)initWithObject:(CALObject*)currentObject;

/**
 * Provides an array of all actions to display given the provided object context
 */
-(NSArray*)computeActionsFor:(CALObject*)object annotatedBy:(MapAnnotation*)annotation fromController:(PMLMapPopupViewController*)popupController;
-(PopupAction*)actionForType:(PMLActionType)type;
-(void)dismiss;
@end
