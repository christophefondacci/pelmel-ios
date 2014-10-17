//
//  MenuAction.m
//  PelMel
//
//  Created by Christophe Fondacci on 12/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "MenuAction.h"

@implementation MenuAction

- (instancetype)initWithIcon:(UIImage *)icon pctWidth:(float)pctWidth pctHeight:(float)pctHeight action:(MenuActionBlock)menuAction {
    return [self initWithView:[[UIImageView alloc] initWithImage:icon] pctWidth:pctWidth pctHeight:pctHeight action:menuAction];
}
- (instancetype)initWithView:(UIView *)view pctWidth:(float)pctWidth pctHeight:(float)pctHeight action:(MenuActionBlock)menuAction
{
    self = [super init];
    if (self) {
        self.menuActionView = view;
        self.pctWidthPosition = pctWidth;
        self.pctHeightPosition = pctHeight;
        self.menuAction = menuAction;
        self.initialHeight = view.bounds.size.height;
        self.initialWidth  = view.bounds.size.width;
    }
    return self;
}

@end
