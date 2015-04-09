//
//  PMLHelpBubble.m
//  PelMel
//
//  Created by Christophe Fondacci on 02/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLHelpBubble.h"

@implementation PMLHelpBubble

- (instancetype)initWithRect:(CGRect)bubbleRect cornerRadius:(CGFloat)radius helpText:(NSString*)helpText textPosition:(PMLTextPosition)textPosition whenSnippetOpened:(BOOL)opened{
    self = [super init];
    if (self) {
        self.bubbleFrame = bubbleRect;
        self.cornerRadius = radius;
        self.helpText = helpText;
        self.textPosition = textPosition;
        self.whenSnippetOpened=opened;
    }
    return self;
}
@end
