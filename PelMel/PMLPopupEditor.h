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

typedef void(^EditionAction)();

/**
 * This interface handles edition of an object from a popup dialog.
 * It basically stores a state of edition and stacks commit/cancel actions.
 */
@interface PMLPopupEditor : NSObject<UIActionSheetDelegate>

@property (nonatomic,weak) CALObject *editedObject;
//@property (nonatomic,weak) MapAnnotation *mapAnnotation;
@property (nonatomic,readonly) NSMutableArray *pendingConfirmActions;
@property (nonatomic,readonly) NSMutableArray *pendingCancelActions;
@property (nonatomic,weak) MapViewController *mapViewController;
@property (nonatomic) BOOL editing;

+ (instancetype)editorFor:(CALObject*)editedObject on:(MapViewController*)mapViewController;
+(void)purgeEditors;
-(void)cancel;
-(void)commit;
-(void)startEditionWith:(EditionAction)commitAction cancelledBy:(EditionAction)cancelAction mapEdition:(BOOL)mapEdition;

@end
