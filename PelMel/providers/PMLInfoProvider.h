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
#import "Likeable.h"
#import "PopupAction.h"

@class PMLMenuManagerController;
typedef enum {
    ThumbPreviewModeNone,
    ThumbPreviewModeLikes,
    ThumbPreviewModeCheckins
} ThumbPreviewMode;

@protocol PMLInfoProvider <NSObject,Likeable>

// The element being represented
-(CALObject*) item;
// Title of the element
-(NSString*) title;
// Subtitle of the element
-(NSString*) subtitle;
-(UIImage*) subtitleIcon;
// Icon representing the type of item being displayed
-(UIImage*) titleIcon;
// The snippet image
-(CALImage*) snippetImage;
// Global theme color for element
-(UIColor*) color;
// Provider of thumb displayed in the main snippet section
-(NSObject<ThumbsPreviewProvider>*) thumbsProvider;
-(NSObject<ThumbsPreviewProvider>*) thumbsProviderFor:(ThumbPreviewMode)mode atIndex:(NSInteger)row;
// Implement to say how many rows of likes need to be displayed
-(NSInteger)thumbsRowCountForMode:(ThumbPreviewMode)mode;
// Number of reviews
-(NSInteger)reviewsCount;
// Number of likes
-(NSInteger)likesCount;
// Number of checkins (if applicable)
-(NSInteger)checkinsCount;
// Description of elements
-(NSString*)descriptionText;
// Short text displayed with thumb
-(NSString*)thumbSubtitleText;
// Color of the short thumb subtitle text
-(UIColor*)thumbSubtitleColor;
-(NSArray*)addressComponents;
// The label of the type of element being displayed
- (NSString*)itemTypeLabel;
- (NSString*)city;

@optional
// Whether or not the data could be edited, defaults to false if not implemented
- (PMLActionType)editActionType;
- (NSString*)commentsCounterTitle;
- (NSString*)checkinsCounterTitle;
- (NSString*)likesCounterTitle;
// When implemented, this method will be called and the component will replace
// The thumbs view
-(void)configureCustomViewIn:(UIView*)parentView forController:(UIViewController*)controller;
// Provides the list of events connected to the current element
-(NSArray*)events;
// Provides the introduction label for the events section, if not implemented or nil then no section header will be displayed
-(NSString*)eventsSectionTitle;
// List of top places
-(NSArray*)topPlaces;
// List of activities
-(NSArray*)activities;
// Action to implement to support action when the thumb of the snippet is tapped
-(void)thumbTapped:(PMLMenuManagerController*)menuController;

// Implement all or none
-(BOOL)hasSnippetRightSection;
-(UIImage*)snippetRightIcon;
-(NSString*)snippetRightTitleText;
-(NSString*)snippetRightSubtitleText;
-(UIColor*)snippetRightColor;

// Optional snippet right action
-(void)snippetRightActionTapped:(UIViewController*)controller;
@end