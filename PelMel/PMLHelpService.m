//
//  HelpService.m
//  PelMel
//
//  Created by Christophe Fondacci on 02/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLHelpService.h"
#import "TogaytherService.h"
#import "PMLHelpOverlayView.h"

@implementation PMLHelpService {
    SettingsService *_settingsService;
    UIService *_uiService;
    NSMutableDictionary *_bubblesNotificationMap;
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _settingsService = [TogaytherService settingsService];
        _uiService = [TogaytherService uiService];
        _bubblesNotificationMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}
- (void)registerBubbleHint:(PMLHelpBubble *)bubble forNotification:(NSString *)notificationName {
    NSMutableSet *bubbles = [_bubblesNotificationMap objectForKey:notificationName];
//    if(bubbles == nil) {
        bubbles = [[NSMutableSet alloc] init];
        [_bubblesNotificationMap setObject:bubbles forKey:notificationName];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(helpNotification:) name:notificationName object:nil];
//    }
    [bubbles addObject:bubble];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification callback
- (void)helpNotification:(NSNotification*)notification {
    // Retrieving any registered help bubble
    NSMutableSet *bubbles = [_bubblesNotificationMap objectForKey:notification.name];
    if(bubbles != nil && bubbles.count>0) {
        // Checking that we have not yet shown this help
        if(![_settingsService settingValueAsBoolFor:notification.name] && (_currentOverlayView == nil || _currentOverlayView.superview == nil)) {
            
            // Building overlay view
            _currentOverlayView = [[PMLHelpOverlayView alloc] initWithFrame:_uiService.menuManagerController.view.frame];
            
            // Appending bubbles
            for(PMLHelpBubble *bubble in bubbles) {
                [_currentOverlayView addHelpBubble:bubble];
            }
            
            _currentOverlayView.alpha=0;
            // Adding to the view hierarchy
            [_uiService.menuManagerController.view addSubview:_currentOverlayView];
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                _currentOverlayView.alpha=1;
            } completion:NULL];
            // Showing is not showing any longer
            [_settingsService storeSettingBoolValue:YES forName:notification.name];
        }

    }
}
@end
