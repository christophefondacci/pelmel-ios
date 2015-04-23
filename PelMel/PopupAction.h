//
//  PopupAction.h
//  PelMel
//
//  Created by Christophe Fondacci on 23/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALImage.h"


typedef enum {
    PMLActionTypeNoAction,
    PMLActionTypeEdit , // Generic edition
    PMLActionTypeLike,
    PMLActionTypeAddPhoto,
    PMLActionTypeCheckin,
    PMLActionTypeComment,
    PMLActionTypeConfirm,
    PMLActionTypeCancel,
    PMLActionTypeReport,
    PMLActionTypeReportForDeletion,
    PMLActionTypeEditPlace,
    PMLActionTypeEditAddress,
    PMLActionTypeEditEvent,
    PMLActionTypeAttend,
    PMLActionTypeAttendCancel,
    PMLActionTypeMyProfile,
    PMLActionTypePhoneCall,
    PMLActionTypeWebsite,
} PMLActionType;

/**
 * A popup action block is the execution block passed to the popup
 * action and which will be executed when the action is triggerred.
 */
typedef void (^PopupActionBlock)(void);


/**
 * A popup action defines an action that could be shown on the map around
 * a main annotation. It defines its location relative to the main annotation element
 * with angle and distance.
 */
@interface PopupAction : NSObject

@property (nonatomic,copy) NSNumber *angle;
@property (nonatomic,copy) NSNumber *distance;
@property (nonatomic) double xOffset;
@property (nonatomic) double yOffset;
@property (nonatomic,copy) NSNumber *size;
@property (nonatomic,retain) UIImage *icon;
@property (nonatomic,retain) CALImage *image;
@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSNumber *badgeValue;
@property (nonatomic,copy) UIColor *color;
@property (nonatomic,copy) PopupActionBlock actionCommand;
@property (nonatomic) BOOL showAttachment;
/**
 * Initializes a new popup action with all its properties (none is optional)
 */
- (instancetype) initWithAngle:(double)angle distance:(double)distance icon:(UIImage*)icon titleCode:(NSString*)titleCode size:(double)size command:(PopupActionBlock)actionCommand;
- (instancetype) initWithIcon:(UIImage*)icon titleCode:(NSString*)titleCode size:(double)size command:(PopupActionBlock)actionCommand;
@end
