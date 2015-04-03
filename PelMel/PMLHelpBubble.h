//
//  PMLHelpBubble.h
//  PelMel
//
//  Created by Christophe Fondacci on 02/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    PMLTextPositionTop,
    PMLTextPositionLeft,
    PMLTextPositionRight,
    PMLTextPositionBottom
} PMLTextPosition;

@interface PMLHelpBubble : NSObject

@property (nonatomic) CGRect bubbleFrame;
@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic,copy) NSString *helpText;
@property (nonatomic) PMLTextPosition textPosition;

- (instancetype)initWithRect:(CGRect)bubbleFrame cornerRadius:(CGFloat)cornerRadius helpText:(NSString*)helpText textPosition:(PMLTextPosition)textPosition;
@end
