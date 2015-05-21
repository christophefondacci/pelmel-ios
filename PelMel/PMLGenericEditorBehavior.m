//
//  PMLGenericEditorBehavior.m
//  PelMel
//
//  Created by Christophe Fondacci on 18/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLGenericEditorBehavior.h"

@implementation PMLGenericEditorBehavior

- (BOOL)editor:(PMLEditor *)popupEditor shouldValidate:(CALObject *)object {
    return YES;
}

- (void)editor:(PMLEditor *)popupEditor submitEditedObject:(CALObject *)object {
    return;
}
@end
