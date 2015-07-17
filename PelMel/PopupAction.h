//
//  PopupAction.h
//  PelMel
//
//  Created by Christophe Fondacci on 23/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALImage.h"
#import "CALObject.h"

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
    PMLActionTypeAddBanner,
    PMLActionTypeEditBanner,
    PMLActionTypeEditPlace,
    PMLActionTypeEditAddress,
    PMLActionTypeEditEvent,
    PMLActionTypeAddEvent,
    PMLActionTypeAttend,
    PMLActionTypeAttendCancel,
    PMLActionTypeMyProfile,
    PMLActionTypePhoneCall,
    PMLActionTypeWebsite,
    PMLActionTypeDirections,
    PMLActionTypePrivateNetworkRequest,
    PMLActionTypePrivateNetworkAccept,
    PMLActionTypePrivateNetworkCancel,
    PMLActionTypePrivateNetworkShow,
    PMLActionTypePrivateNetworkAddUsers,
    PMLActionTypePrivateNetworkRespond,
    PMLActionTypeGroupChat
} PMLActionType;

/**
 * A popup action block is the execution block passed to the popup
 * action and which will be executed when the action is triggerred.
 */
typedef void (^PopupActionBlock)(void);
typedef void (^PMLActionBlock)(CALObject *object);


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
@property (nonatomic,copy) PMLActionBlock actionCommand;
@property (nonatomic) BOOL showAttachment;
/**
 * Initializes a new popup action with all its properties (none is optional)
 */
- (instancetype) initWithAngle:(double)angle distance:(double)distance icon:(UIImage*)icon titleCode:(NSString*)titleCode size:(double)size command:(PMLActionBlock)actionCommand;
- (instancetype) initWithIcon:(UIImage*)icon titleCode:(NSString*)titleCode size:(double)size command:(PMLActionBlock)actionCommand;
- (instancetype)initWithCommand:(PMLActionBlock)actionCommand;
@end
