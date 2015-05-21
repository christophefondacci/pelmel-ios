//
//  PMLPopupEditor.m
//  PelMel
//
//  Created by Christophe Fondacci on 28/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLEditor.h"
#import "MapViewController.h"
#import "PMLMapPopupViewController.h"
#import "TogaytherService.h"
#import "PMLPlaceEditorBehavior.h"
#import "PMLBannerEditorBehavior.h"
#import "PMLGenericEditorBehavior.h"
#import <MBProgressHUD.h>

#define kPMLActionSheetCancel 0
#define kPMLActionSheetSubmit 1

// A static map of all current editors
static NSMutableDictionary *_editorsKeyMap;
static PMLEditor *_newObjectEditor;

@interface PMLEditor ()
@property (nonatomic,retain) NSObject<PMLEditorBehavior> *editorBehavior;
@end

@implementation PMLEditor {
    NSMutableArray *_confirmActions;
    NSMutableArray *_cancelActions;

 
    // Services
    DataService *_dataService;
    
    BOOL _mapEdition;
}

+ (void)initialize {
    _editorsKeyMap = [[NSMutableDictionary alloc] init];
}
+(void)purgeEditors {
    _editorsKeyMap = [[NSMutableDictionary alloc] init];
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _confirmActions = [[NSMutableArray alloc] init];
        _cancelActions = [[NSMutableArray alloc] init];
        _dataService = TogaytherService.dataService;
    }
    return self;

}
+ (instancetype)editorFor:(CALObject *)editedObject {
    return [self editorFor:editedObject on:[[[TogaytherService uiService] menuManagerController] rootViewController]];
}

+ (instancetype)editorFor:(CALObject *)editedObject on:(MapViewController *)mapViewController {
    PMLEditor *editor = nil;
    
    // Retrieving any previous editor registered for this object
    if(editedObject.key != nil) {
        editor = [_editorsKeyMap objectForKey:editedObject.key];
    } else {
        editor = _newObjectEditor;
    }
    
    // If not found we create a new one
    if(editor == nil ) {
        editor = [[PMLEditor alloc] init];
        // And register it so that future calls for same object will return this same editor
        if(editedObject.key != nil) {
            [_editorsKeyMap setObject:editor forKey:editedObject.key];
        } else {
            _newObjectEditor = editor;
        }
    }
    
    // Setting up edited object and behavior
    editor.editedObject = editedObject;
    editor.editorBehavior = [self editorBehaviorFor:editedObject];
    
    // Storing map view controller
    if(mapViewController != nil) {
        editor.mapViewController = mapViewController;
    } else if(editor.mapViewController==nil) {
        editor.mapViewController = [[[TogaytherService uiService] menuManagerController] rootViewController];
    }

    return editor;
}

+(NSObject<PMLEditorBehavior>*)editorBehaviorFor:(CALObject*)object {
    if([object isKindOfClass:[Place class]]) {
        return [[PMLPlaceEditorBehavior alloc] init];
    } else if([object isKindOfClass:[PMLBanner class]]) {
        return [[PMLBannerEditorBehavior alloc] init];
    } else {
        return [[PMLGenericEditorBehavior alloc] init];
    }
}
- (NSMutableArray *)pendingConfirmActions {
    return _confirmActions;
}
- (NSMutableArray *)pendingCancelActions {
    return _cancelActions;
}
- (void)cancel {
    if(self.editing) {
        // Applying cancel actions
        for(EditionAction action in [self.pendingCancelActions reverseObjectEnumerator]) {
            action();
        }
        [self endEdition];
    }
    if(_editedObject.key == nil) {
        [_mapViewController setEditedObject:nil];
        [_mapViewController.parentMenuController dismissControllerSnippet];
    }

}
-(void)commit {
    if([self.editorBehavior editor:self shouldValidate:self.editedObject]) {
        [self.editorBehavior editor:self submitEditedObject:self.editedObject];
    }
}

-(void)endEdition {
    // Removing edited object from map view controller
    self.mapViewController.editedObject = nil;

    // Cleanup and setting new state
    self.editing = NO;
    [_cancelActions removeAllObjects];
    [_confirmActions removeAllObjects];
    self.editedObject.editing = NO;
    // Purging editor
    if(self.editedObject.key != nil) {
        [_editorsKeyMap removeObjectForKey:self.editedObject.key];
        
        // TODO: Improve code by avoid Place cast (=> convert to commit action)
        if([self.editedObject isKindOfClass:[Place class]]) {
            [self.mapViewController reselectPlace:(Place*)self.editedObject];
        }
    }
    _newObjectEditor = nil;
}

- (void)startEditionWith:(EditionAction)commitAction cancelledBy:(EditionAction)cancelAction mapEdition:(BOOL)mapEdition{
    self.editing = YES;
    if(commitAction != nil) {
        [_confirmActions addObject:commitAction];
    }
    if(cancelAction != nil) {
        [_cancelActions addObject:cancelAction];
    }
    // Setting map edited object to current
    _mapEdition = mapEdition;
    if(mapEdition) {
        self.mapViewController.editedObject = self.editedObject;
    } else {
        [self.mapViewController.popupController refreshActions];
    }
}


-(void)applyCommitActions {
    // Applying any commit action
    for(EditionAction action in self.pendingConfirmActions) {
        action();
    }
    [self endEdition];
}
-(void)applyCancelActions {
    // Applying any commit action
    for(EditionAction action in self.pendingCancelActions) {
        action();
    }
    [self endEdition];
}
@end
