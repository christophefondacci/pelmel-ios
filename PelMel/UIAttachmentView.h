//
//  UIAttachmentView.h
//  PelMel
//
//  Created by Christophe Fondacci on 20/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAttachmentView : UIView

- (void) attachFromView:(UIView*)attachedView toView:(UIView*)attachmentView offset:(CGPoint)offset;

@end
