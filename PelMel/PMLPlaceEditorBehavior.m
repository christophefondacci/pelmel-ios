//
//  PMLPlaceEditorBehavior.m
//  PelMel
//
//  Created by Christophe Fondacci on 18/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLPlaceEditorBehavior.h"
#import "Place.h"
#import "TogaytherService.h"

#define kPMLActionSheetCancel 0
#define kPMLActionSheetSubmit 1

@interface PMLPlaceEditorBehavior()
@property (nonatomic,retain) Place *submittedPlace;
@property (nonatomic,retain) PMLEditor *currentEditor;
@end

@implementation PMLPlaceEditorBehavior

-(BOOL)editor:(PMLEditor *)popupEditor shouldValidate:(CALObject *)object {
    Place *p = (Place*)object;
    NSString *errorMsg;
    if([[p.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        errorMsg = @"validation.noname";
    } else if(p.lat == 0 && p.lng == 0) {
        errorMsg = @"validation.nolocation";
    }
    if(errorMsg != nil) {
        [[TogaytherService uiService] alertWithTitle:@"validation.errorTitle" text:errorMsg];
        return NO;
    } else {
        return YES;
    }

}
- (void)editor:(PMLEditor *)popupEditor submitEditedObject:(CALObject *)object {
    // Confirm action that prompts user for confirmation
    NSString *title = NSLocalizedString(@"action.edit.confirm.title",@"Submit changes title");
    NSString *msg = NSLocalizedString(@"action.edit.confirm.message",@"Submit changes msg");
    NSString *submit = NSLocalizedString(@"action.edit.confirm.submit",@"Submit button title");
    NSString *cancel= NSLocalizedString(@"cancel","cancel");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:cancel otherButtonTitles:submit, nil];
    self.submittedPlace = (Place*)object;
    self.currentEditor = popupEditor;
    [alertView show];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch(buttonIndex) {
        case kPMLActionSheetCancel:
            // Doing nothing for now, should we cancel?
            // -> user can now return to commit / confirm
            break;
        case kPMLActionSheetSubmit:
            [[TogaytherService dataService] updatePlace:self.submittedPlace callback:^(Place *place) {
                [self.currentEditor applyCommitActions];
                self.submittedPlace = nil;
            }];
            break;
    }
}
@end
