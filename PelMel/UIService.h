//
//  UIService.h
//  PelMel
//
//  Created by Christophe Fondacci on 30/01/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALObject.h"
#import "SWRevealViewController.h"
#import "MapViewController.h"
#import "PMLInfoProvider.h"


@interface UIService : NSObject <UISplitViewControllerDelegate>

@property (nonatomic) SWRevealViewController *revealViewController;
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
-(UIProgressView*)addProgressTo:(UINavigationController*)controller;
-(void)setProgressView:(UIProgressView*)progressView;
-(void)reportProgress:(float)progress;
-(void)progressDone;

/**
 * Creates a snippet for the given element, presents it, and optionally opens it
 */
-(void)presentSnippetFor:(CALObject*)object opened:(BOOL)opened;

/**
 * Simple alert dialog with localized messages, only one OK button
 */
-(void)alertWithTitle:(NSString*)titleKey text:(NSString*)textKey;
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
@end
