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

@implementation PMLPopupEditor {
    NSMutableArray *_confirmActions;
    NSMutableArray *_cancelActions;
 
    // Services
    DataService *_dataService;
    
    BOOL _mapEdition;
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
+ (instancetype)editorFor:(CALObject *)editedObject annotatedBy:(MapAnnotation *)annotation on:(MapViewController *)mapViewController {
    PMLPopupEditor *editor = [[PMLPopupEditor alloc] init];
    editor.editedObject = editedObject;
    editor.mapAnnotation = annotation;
    editor.mapViewController = mapViewController;
    return editor;
}

- (NSArray *)pendingConfirmActions {
    return _confirmActions;
}
- (NSArray *)pendingCancelActions {
    return _cancelActions;
}
- (void)cancel {
    if(self.editing) {
        // Applying cancel actions
        for(EditionAction action in [self.pendingCancelActions reverseObjectEnumerator]) {
            action();
        }
        [self endEdition];
    } else if(_editedObject.key == nil) {
        [_mapViewController setEditedObject:nil];
    }
}
-(void)commit {
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
//    [self.mapViewController selectCALObject:self.editedObject];
    [self.mapViewController reselectPlace:(Place*)self.editedObject];
    
    // Cleanup and setting new state
    self.editing = NO;
    [_cancelActions removeAllObjects];
    [_confirmActions removeAllObjects];

//    if(!_mapEdition) {
//        [self.mapViewController.popupController refreshActions];
//    }
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
