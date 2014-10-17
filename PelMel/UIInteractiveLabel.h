//
//  UIInteractiveLabel.h
//  togayther
//
//  Created by Christophe Fondacci on 08/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIInteractiveLabel : UILabel 
@property (readwrite) UIView *inputView;
@property (readwrite) UIView *inputAccessoryView;

- (BOOL) isUserInteractionEnabled;

- (BOOL)canBecomeFirstResponder;

@end
