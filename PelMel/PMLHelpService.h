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

/**
 * Registers the given help bubble for the provided notification. Whenever this notification is 
 * posted to the NSNotificationCenter, this bubble will be displayed.
 */
-(void)registerBubbleHint:(PMLHelpBubble*)bubble forNotification:(NSString*)notificationName;
/**
 * Resets all hints so that each of them will be displayed again
 */
-(void)resetHints;
@end
