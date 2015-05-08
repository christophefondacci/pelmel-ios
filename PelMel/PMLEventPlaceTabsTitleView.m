//
//  PMLEventPlaceTabsTitleView.m
//  PelMel
//
//  Created by Christophe Fondacci on 08/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLEventPlaceTabsTitleView.h"

@implementation PMLEventPlaceTabsTitleView

- (void)awakeFromNib {
//    UIImage *bgTabImage = [UIImage imageNamed:@"bgTab"];
//    bgTabImage = [bgTabImage stretchableImageWithLeftCapWidth:10 topCapHeight:10];
//    [self.eventsTabButton setImage:bgTabImage forState:UIControlStateNormal];
//    [self.placesTabButton setImage:bgTabImage forState:UIControlStateNormal];
    [self.eventsTabButton addTarget:self action:@selector(eventsTabTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.placesTabButton addTarget:self action:@selector(placesTabTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.eventsTabButton setTitle:NSLocalizedString(@"tabs.events", @"Upcoming Events") forState:UIControlStateNormal];
    [self.placesTabButton setTitle:NSLocalizedString(@"tabs.places", @"Top Hangouts") forState:UIControlStateNormal];
}

-(void)eventsTabTapped:(UIButton*)sender {
    if(self.delegate != nil) {
        BOOL shouldContinue = [self.delegate eventsTabTapped];
        if(shouldContinue) {
            [self setActiveTab:PMLTabEvents];
        }
    }
}
-(void)placesTabTapped:(UIButton*)sender {
    if(self.delegate != nil) {
        BOOL shouldContinue = [self.delegate placesTabTapped];
        if(shouldContinue) {
            [self setActiveTab:PMLTabPlaces];
        }
    }
}

- (void)setActiveTab:(PMLTab)activeTab {
    NSString *eventTabImg;
    NSString *placeTabImg;
    switch(activeTab) {
        case PMLTabEvents:
            eventTabImg = @"bgTab";
            placeTabImg = @"bgTabDisabled";
            break;
        case PMLTabPlaces:
            eventTabImg = @"bgTabDisabled";
            placeTabImg = @"bgTab";
            break;
    }
    UIImage *eventImage =[UIImage imageNamed:eventTabImg];// stretchableImageWithLeftCapWidth:10 topCapHeight:10];
    UIImage *placeImage =[UIImage imageNamed:placeTabImg];// stretchableImageWithLeftCapWidth:10 topCapHeight:10];
    [self.eventsTabButton setBackgroundImage:eventImage forState:UIControlStateNormal];
    [self.placesTabButton setBackgroundImage:placeImage forState:UIControlStateNormal];
}
@end
