//
//  PMLEventPlaceTabsTitleView.h
//  PelMel
//
//  Created by Christophe Fondacci on 08/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol PMLEventPlaceTabsDelegate
/**
 * Indicates the event tab has been tapped.
 * @return YES if the tab should be changed, NO to cancel the action
 */
-(BOOL)eventsTabTapped;
/**
 * Indicates the place tab has been tapped.
 * @return YES if the tab should be changed, NO to cancel the action
 */
-(BOOL)placesTabTapped;
@end
typedef enum {
    PMLTabEvents,
    PMLTabPlaces
}PMLTab;
@interface PMLEventPlaceTabsTitleView : UIView
@property (weak, nonatomic) IBOutlet UIButton *eventsTabButton;
@property (weak, nonatomic) IBOutlet UIButton *placesTabButton;
@property (weak, nonatomic) id<PMLEventPlaceTabsDelegate> delegate;

-(void)setActiveTab:(PMLTab)activeTab;
@end
