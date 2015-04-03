//
//  HelpService.h
//  PelMel
//
//  Created by Christophe Fondacci on 02/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PMLHelpBubble.h"
#import "PMLHelpOverlayView.h"
@interface PMLHelpService : NSObject

@property (nonatomic,retain) PMLHelpOverlayView *currentOverlayView;

-(void)registerBubbleHint:(PMLHelpBubble*)bubble forNotification:(NSString*)notificationName;

@end
