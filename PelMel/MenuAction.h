//
//  MenuAction.h
//  PelMel
//
//  Created by Christophe Fondacci on 12/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PMLMenuManagerController;
@class MenuAction;

typedef void(^MenuActionBlock)(PMLMenuManagerController *menuManagerController,MenuAction *menuAction);

/**
 * A menu action represents an action that could be displayed by the UIMenuManagerViewController
 */
@interface MenuAction : NSObject

/** The UIView representing this action when the menu is displayed*/
@property (nonatomic,strong) UIView *menuActionView;

/** The X position of this action, as a percentage of the total available width */
@property (nonatomic) float pctWidthPosition;

/** The Y position of this action, as a percentage of the total available height */
@property (nonatomic) float pctHeightPosition;

@property (nonatomic) float leftMargin;
@property (nonatomic) float topMargin;
@property (nonatomic) float rightMargin;
@property (nonatomic) float bottomMargin;
@property (nonatomic) CGFloat initialWidth;
@property (nonatomic) CGFloat initialHeight;

/** The action that is triggered by this instance */
@property (nonatomic,strong) MenuActionBlock menuAction;

- (instancetype)initWithIcon:(UIImage*)icon pctWidth:(float)pctWidth pctHeight:(float)pctHeight action:(MenuActionBlock)menuAction;
- (instancetype)initWithView:(UIView*)view pctWidth:(float)pctWidth pctHeight:(float)pctHeight action:(MenuActionBlock)menuAction;


@end
