//
//  PMLInfoProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 22/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALObject.h"
#import "Special.h"
#import "Activity.h"
#import "Likeable.h"
#import "PopupAction.h"
#import "PMLThumbsPreviewProvider.h"
#import "PMLCountersView.h"
#import "Event.h"

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
-(NSObject<PMLThumbsPreviewProvider>*) thumbsProvider;
-(NSObject<PMLThumbsPreviewProvider>*) thumbsProviderFor:(ThumbPreviewMode)mode atIndex:(NSInteger)row;
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
- (id<PMLCountersDatasource>)countersDatasource:(PMLPopupActionManager*)actionManager;
- (BOOL)canAddPhoto;   
@optional
- (CALObject*)mapObjectForLocalization;
// If a localization object is provided, the title for the localization section, nil or unimplemented will hide section title
- (NSString*)localizationSectionTitle;
// Whether or not the data could be edited, defaults to false if not implemented
- (PMLActionType)editActionType;
- (PMLActionType)likeActionType; // Default is Like
- (PMLActionType)checkinActionType; // Default is Checkin
- (PMLActionType)commentActionType; // Default is Comment
- (PMLActionType)reportActionType; // Default is no report, if returning something, the report button will be displayed
- (NSString*)reportText;
// The subtitle to display
- (NSString*)actionSubtitleFor:(PMLActionType)actionType;
- (NSString*)subtitleIntro; // Text displayed on top of the subtitle text (top right corner)
- (NSArray*)properties; // List of properties



- (NSString*)commentsCounterTitle;
- (NSString*)checkinsCounterTitle;
- (NSString*)likesCounterTitle;
// When implemented, this method will be called and the component will replace
// The thumbs view
-(void)configureCustomViewIn:(UIView*)parentView forController:(UIViewController*)controller;
// Provides the list of events connected to the current element
-(NSArray*)events;
// Provides the image for the event listing
-(CALImage*)imageForEvent:(Event*)event;
-(NSString*)titleForEvent:(Event*)event;
-(BOOL)canAddEvent; // Implement and return YES to integrate Add Event button, or return NO / no implem to hide
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