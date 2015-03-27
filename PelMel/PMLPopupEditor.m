//
//  PMLPopupEditor.m
//  PelMel
//
//  Created by Christophe Fondacci on 28/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLPopupEditor.h"
#import "MapViewController.h"
#import "PMLMapPopupViewController.h"
#import "TogaytherService.h"

#define kPMLActionSheetCancel 0
#define kPMLActionSheetSubmit 1

// A static map of all current editors
static NSMutableDictionary *_editorsKeyMap;
static PMLPopupEditor *_newObjectEditor;

@implementation PMLPopupEditor {
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
+ (instancetype)editorFor:(CALObject *)editedObject on:(MapViewController *)mapViewController {
    PMLPopupEditor *editor = nil;
    if(editedObject.key != nil) {
        editor = [_editorsKeyMap objectForKey:editedObject.key];
    } else {
        editor = _newObjectEditor;
    }
    if(editor == nil ) {
        editor = [[PMLPopupEditor alloc] init];
        if(editedObject.key != nil) {
            [_editorsKeyMap setObject:editor forKey:editedObject.key];
        } else {
            _newObjectEditor = editor;
        }
    }
    editor.editedObject = editedObject;
//    editor.mapAnnotation = annotation;
    editor.mapViewController = mapViewController;

    return editor;
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
    if([self.editedObject isKindOfClass:[Place class]]) {
        Place *p = (Place*)self.editedObject;
        NSString *errorMsg;
        if([[p.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
            errorMsg = @"validation.noname";
        } else if(p.lat == 0 && p.lng == 0) {
            errorMsg = @"validation.nolocation";
        }
        if(errorMsg != nil) {
            [[TogaytherService uiService] alertWithTitle:@"validation.errorTitle" text:errorMsg];
            return;
        }
    }
    
    // Confirm action that prompts user for confirmation
    NSString *title = NSLocalizedString(@"action.edit.confirm.title",@"Submit changes title");
    NSString *msg = NSLocalizedString(@"action.edit.confirm.message",@"Submit changes msg");
    NSString *submit = NSLocalizedString(@"action.edit.confirm.submit",@"Submit button title");
    NSString *cancel= NSLocalizedString(@"cancel","cancel");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:cancel otherButtonTitles:submit, nil];
    [alertView show];
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
        [self.mapViewController reselectPlace:(Place*)self.editedObject];
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

#pragma mark - UIAlertViewDelegate
- (void)alertViewCancel:(UIAlertView *)alertView {
    // Doing nothing for now, should we cancel?
    // -> user can now return to commit / confirm
}
//-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
//    switch(buttonIndex) {
//        case kPMLActionSheetCancel:
//            // Doing nothing for now, should we cancel?
//            // -> user can now return to commit / confirm
//            break;
//        case kPMLActionSheetSubmit:
//            [self submitEdition];
//            break;
//    }
//}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch(buttonIndex) {
        case kPMLActionSheetCancel:
            // Doing nothing for now, should we cancel?
            // -> user can now return to commit / confirm
            break;
        case kPMLActionSheetSubmit:
            [self submitEdition];
            break;
    }
}
- (void)submitEdition {
    [_dataService updatePlace:(Place*)self.editedObject callback:^(Place *place) {
        // Applying any commit action
        for(EditionAction action in self.pendingConfirmActions) {
            action();
        }
        [self endEdition];
    }];
}
@end
