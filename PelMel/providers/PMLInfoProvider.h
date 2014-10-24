//
//  PMLInfoProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 22/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALObject.h"
#import "ThumbsPreviewView.h"
#import "Special.h"
#import "Activity.h"


@protocol PMLInfoProvider <NSObject>

// The element being represented
-(CALObject*) item;
// Title of the element
-(NSString*) title;
// Icon representing the type of item being displayed
-(UIImage*) titleIcon;
// The snippet image
-(CALImage*) snippetImage;
// Global theme color for element
-(UIColor*) color;
// Provider of thumb displayed in the main snippet section
-(NSObject<ThumbsPreviewProvider>*) thumbsProvider;
-(NSObject<ThumbsPreviewProvider>*) likesThumbsProvider;
-(NSObject<ThumbsPreviewProvider>*) checkinsThumbsProvider;
// Number of reviews
-(int)reviewsCount;
// Number of likes
-(int)likesCount;
// Number of checkins (if applicable)
-(int)checkinsCount;
// Description of elements
-(NSString*)descriptionText;
// Short text displayed with thumb
-(NSString*)thumbSubtitleText;
// Color of the short thumb subtitle text
-(UIColor*)thumbSubtitleColor;
-(NSArray*)addressComponents;

@optional
// When implemented, this method will be called and the component will replace
// The thumbs view
-(void)configureCustomViewIn:(UIView*)parentView;

//-(Special*)specialOfType:(NSString*)specialType;
-(NSArray*)topPlaces;
-(NSArray*)activities;

// Implement all or none
-(BOOL)hasSnippetRightSection;
-(UIImage*)snippetRightIcon;
-(NSString*)snippetRightTitleText;
-(NSString*)snippetRightSubtitleText;
-(UIColor*)snippetRightColor;

// Optional snippet right action
-(void)snippetRightActionTapped:(UIViewController*)controller;
@end