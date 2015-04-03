//
//  PMLHelpOverlay.h
//  PelMel
//
//  Created by Christophe Fondacci on 02/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLHelpBubble.h"

@interface PMLHelpOverlayView : UIView

@property (nonatomic,retain) NSMutableArray *helpBubbles;

-(void)addHelpBubble:(PMLHelpBubble*)helpBubble;

@end
