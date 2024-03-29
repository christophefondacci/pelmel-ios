//
//  UIService.h
//  PelMel
//
//  Created by Christophe Fondacci on 30/01/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALObject.h"
#import "MapViewController.h"
#import "PMLInfoProvider.h"
#import "PMLEventTableViewCell.h"
#import "UIIntroViewController.h"
#import <EAIntroView.h>

@interface UIService : NSObject <UISplitViewControllerDelegate,EAIntroDelegate>

@property (nonatomic) UIBarButtonItem *popoverBarButtonItem;
@property (nonatomic) UIPopoverController *popoverController;
@property (strong,nonatomic) MapViewController *splitMapController;
@property (strong,nonatomic) UINavigationController *splitMainNavController;

@property (strong,nonatomic) PMLMenuManagerController *menuManagerController;

/**
 * Provides the color from the given place type
 */
- (UIColor *) colorForObject:(NSObject*)object;

/**
 * Provides the map view controller currently connected to this split view (for iPad)
 */
-(MapViewController*)mapControllerFromSplitView:(UISplitViewController*)splitViewController;

/**
 * Instantiates the controller identified by the given ID from storyboard
 */
-(UIViewController*)instantiateViewController:(NSString*)controllerId;
/**
 * Presents the filter selection view controller, handling iPad screens
 * @param controller the current view controller requesting to show filters
 */
-(void)showFiltersViewControllerFor:(UIViewController*)controller;

/**
 * Informs about whether or not the device should have iPAD behaviour
 */
-(BOOL)isIpad:(UIViewController*)controller;

/**
 * Sets the current object to orient the tab bar compass
 */
//-(void)setCompassObject:(CALObject*)obj;
/**
 * Displays the waiting overlay on top of the specified controller
 *
 * @param currentController the controller on which the wait should be displayed
 */
//-(void)showWaitingOverlay:(UIViewController*)currentController;
/**
 * Hides any waiting overlay
 */
//-(void)hideWaitingOverlay;

/**
 * UIService initialization method, must be called from AppDelegate
 */
-(void)start:(UIWindow*)window;

/**
 * A helper method which loads the UIView in the given nib
 */
-(UIView*)loadView:(NSString*)nibName;

/**
 * Builds the appropriate provider for the given CAL object
 */
-(NSObject<PMLInfoProvider>*)infoProviderFor:(CALObject*)object;
/**
 * Provides the map marker icon for the given element
 * @param object the CAL object to get a marker for
 * @param enabled whether we want the enabled marker or the disabled one
 * @return the corresponding UIImage, mapMarkerCenterOffsetFor should be used to get the offset of this marker
 */
-(UIImage*)mapMarkerFor:(CALObject*)object enabled:(BOOL)enabled;
/**
 * Provides the map marker center offset for the given element
 */
-(CGPoint)mapMarkerCenterOffsetFor:(CALObject*)object;

/**
 * Provides a string indicating how long ago this date was 
 */
-(NSString*)delayStringFrom:(NSDate *)date;

/**
 * Adds a global progress bar on this controller and registers it as the current
 * progress view to report progress to
 */
-(UIView*)addProgressTo:(UINavigationController*)controller;
-(void)setProgressView:(UIView*)progressView;
-(void)reportProgress:(float)progress;
-(void)progressDone;

/**
 * Creates a snippet for the given element, presents it, and optionally opens it
 */
-(void)presentSnippetFor:(CALObject*)object opened:(BOOL)opened;
-(void)presentSnippetFor:(CALObject *)object opened:(BOOL)opened root:(BOOL)root;
-(void)presentSnippet:(UIViewController *)controller opened:(BOOL)opened root:(BOOL)root;
/**
 * Presents the controller in the current context (most of the cases will be in an opened snippet
 * unless the navigation is done at the root navigation level).
 */
-(void)presentController:(UIViewController*)controller;
/**
 * Simple alert dialog with localized messages, only one OK button
 */
-(void)alertWithTitle:(NSString*)titleKey text:(NSString*)textKey;
-(void)alertWithTitle:(NSString*)titleKey text:(NSString*)textKey textObjectName:(NSString*)text;
- (void)alertError;
/**
 * Takes a snapshot of the given view and return it as a UIImage for processing.
 * Generally used for blurring.
 * @param view the UIView to blur
 * @return the snapshot image as a UIImage
 */
- (UIImage *)takeSnapshotOfView:(UIView *)view;
/**
 * Blurs the given view and returns the result as a UIImage
 * @param view the UIView to blur
 * @return an UIImage of the same view after applying a blur filter on it
 */
- (UIImage *)blurWithImageEffects:(UIView *)view;

/**
 * A generic method handling variations of a localized string based on a number.
 * This method only handles localized templates accepting one single integer argument.
 * The template will be suffixed by ".singular" if singular and optionally by ".zero" for
 * a 0 version.
 *
 * @param translateKey the translation key of the template to use for the translation
 * @param count the count that will be injected in the template
 */
-(NSString*)localizedString:(NSString*)translateKey forCount:(NSInteger)count;
-(NSString*)nameForEvent:(Event*)event;

/**
 * Extracts the property matching the specified code. Will return nil if this property is not defined
 * or if the info provider does not support properties.
 * @param infoProvider the current info provider
 * @param propertyCode the code of the property to extract
 * @return the PMLProperty matching the given code, or nil if none or properties not supported
 */
-(PMLProperty*)propertyFrom:(id<PMLInfoProvider>)infoProvider forCode:(NSString*)propertyCode;

/**
 * Factorization of setup of the event cell
 * @param cell the PMLEventTableViewCell to configure
 * @param event the event containing the information to fill in the cell
 * @param infoProvider the PMLInfoProvider implementation to use
 */
-(void)configureRowOvEvents:(PMLEventTableViewCell*)cell forEvent:(Event*)event usingInfoProvider:(id<PMLInfoProvider>)infoProvider ;
/**
 * Factorization of the setup of the place cell
 * @param cell the PMLEventTableViewCell to configure
 * @param place the Place object containing information to fill in the cell
 */
-(void)configureRowPlace:(PMLEventTableViewCell*)cell place:(Place*)place;
/**
 * This method will sort objects for display, making sure that the objects with the more content are displayed 
 * first.
 * @param objects the array of objects to sort
 * @return the sorted array containing same elements in a different order
 */
-(NSArray*)sortObjectsForDisplay:(NSArray*)objects;
/**
 * Sort objects with images first, then others preserving original ordering
 * @param objects the source array to sort
 * @return an array of CAL objects sorted with image first, then others, preserving initial ordering within each category
 */
-(NSArray*)sortObjectsWithImageFirst:(NSArray*)objects;

/**
 * Starts the menu manager. Should only be called once, from the login screen or from the app delegate
 */
-(void)startMenuManager;

/**
 * Makes sure that the menu manager view controller is visible
 */
-(void)popNavigationToMenuManager;

/**
 * Toggles a transparent, superposed, navigation bar with white text and tint
 * @param controller the controller to set the navbar on
 */
- (void)toggleTransparentNavBar:(UIViewController*)controller;
/**
 * Builds and return the intro controller with login features
 */
-(UIIntroViewController*)buildIntroViewController:(BOOL)startAtLogin autoLogin:(BOOL)autoLogin modal:(BOOL)modal;
@end