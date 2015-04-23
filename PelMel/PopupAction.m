//
//  PopupAction.m
//  PelMel
//
//  Created by Christophe Fondacci on 23/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PopupAction.h"

@implementation PopupAction

- (instancetype)initWithAngle:(double)angle distance:(double)distance icon:(UIImage *)icon titleCode:(NSString *)titleCode size:(double)size command:(PopupActionBlock)actionCommand
{
    self = [super init];
    if (self) {
        _angle = [NSNumber numberWithDouble:angle];
        _distance = [NSNumber numberWithDouble:distance];
        _icon = icon;
        if(titleCode) {
            _title = NSLocalizedString(titleCode, @"Dynamic code of the label to use as title");
        }
        _size = [NSNumber numberWithDouble:size];
        _actionCommand = actionCommand;
        _showAttachment=YES;
        
    }
    return self;
}

- (instancetype)initWithIcon:(UIImage *)icon titleCode:(NSString *)titleCode size:(double)size command:(PopupActionBlock)actionCommand {
    self = [super init];
    if (self) {
        _icon = icon;
        if(titleCode) {
            _title = NSLocalizedString(titleCode, @"Dynamic code of the label to use as title");
        }
        _size = [NSNumber numberWithDouble:size];
        _actionCommand = actionCommand;
        _showAttachment=YES;
    }
    return self;
    
}

@end
