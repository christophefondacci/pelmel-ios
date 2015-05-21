//
//  PMLPopupEditor.h
//  PelMel
//
//  Created by Christophe Fondacci on 28/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALObject.h"

@class MapAnnotation;
@class MapViewController;
@class PMLEditor;

typedef void(^EditionAction)();

@protocol PMLEditorBehavior
/**
 * Informs whether the given object is valid and can be submitted to the server. The implementation
 * is in charge of notifying the user about what is incorrect.
 *
 * @param popupEditor the current editor for this object
 * @param object the object to validate
 * @return YES when valid or NO where update process should stop
 */
-(BOOL)editor:(PMLEditor*)popupEditor shouldValidate:(CALObject*)object;
/**
 * This method submits the modified object to the server.
 * @param popupEditor the current editor for this object
 * @param object the object that should be submitted to the server
 */
-(void)editor:(PMLEditor*)popupEditor submitEditedObject:(CALObject*)object;
@end
/**
 * This interface handles edition of an object from a popup dialog.
 * It basically stores a state of edition and stacks commit/cancel actions.
 */
@interface PMLEditor : NSObject

@property (nonatomic,weak) CALObject *editedObject;
//@property (nonatomic,weak) MapAnnotation *mapAnnotation;
@property (nonatomic,readonly) NSMutableArray *pendingConfirmActions;
@property (nonatomic,readonly) NSMutableArray *pendingCancelActions;
@property (nonatomic,weak) MapViewController *mapViewController;
@property (nonatomic) BOOL editing;

+ (instancetype)editorFor:(CALObject*)editedObject on:(MapViewController*)mapViewController;
+ (instancetype)editorFor:(CALObject *)editedObject;
+(void)purgeEditors;
-(void)cancel;
-(void)commit;
-(void)applyCommitActions;
-(void)applyCancelActions;
-(void)startEditionWith:(EditionAction)commitAction cancelledBy:(EditionAction)cancelAction mapEdition:(BOOL)mapEdition;

@end
