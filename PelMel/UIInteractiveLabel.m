//
//  UIInteractiveLabel.m
//  togayther
//
//  Created by Christophe Fondacci on 08/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "UIInteractiveLabel.h"

@implementation UIInteractiveLabel

@synthesize inputView;
@synthesize inputAccessoryView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)isUserInteractionEnabled {
    return YES;
}
@end
