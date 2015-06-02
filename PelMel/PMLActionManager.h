//
//  PMLActionManager.h
//  PelMel
//
//  Created by Christophe Fondacci on 28/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALObject.h"
#import "PopupAction.h"
#import "UIService.h"
#import "UserService.h"
#import "DataService.h"
#import "PMLItemSelectionTableViewController.h"

/**
 * The action manager provides a single entry point for generic UI actions. Actions are retrieved by specifying 
 * their PMLActionType and can be executed against any CAL object.
 */
@interface PMLActionManager : NSObject <UIActionSheetDelegate,UIAlertViewDelegate,UITextFieldDelegate,PMLItemSelectionDelegate>

@property (nonatomic,weak) UIService *uiService;
@property (nonatomic,weak) UserService *userService;
@property (nonatomic,weak) DataService *dataService;


-(PopupAction*)actionForType:(PMLActionType)type;
-(void)execute:(PMLActionType)actionType onObject:(CALObject*)object;

@end
