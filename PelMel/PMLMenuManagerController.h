//
//  UIMenuManagerController.h
//  PelMel
//
//  Created by Christophe Fondacci on 12/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MenuAction.h"
#import "DataService.h"
#import "PMLMainNavBarView.h"
#import "PMLPopupActionManager.h"

#define kPMLSnippetTopOffset 20
#define kSnippetHeight 110
#define kSnippetEditHeight 150

@class PMLDataManager;

/**
 * The delegate of a menu manager, generally attached to a corresponding UIViewController.
 * The UIViewController represents the view displayed in the container while this delegate
 * provides the menu actions that the manager needs to handle on top of it.
 */
@protocol PMLMenuManagerDelegate <NSObject>

/**
 * Initializes action for this menu manager
 */
-(void)initializeActionsFor:(PMLMenuManagerController*)menuManagerController belowView:(UIView*)bottomView;

/**
 * Indicates to the menu manager that loading is currently occuring
 */
-(void)loadingStart;
/** 
 * Indicates to the menu manager that loading should stop
 */
-(void)loadingEnd;

/**
 * Adds an action
 */
-(void)setupMenuAction:(MenuAction*)menuAction;

/**
 * Forces a layout of all menu actions
 */
-(void)layoutMenuActions;

/**
 * Removes an action
 */
-(void)removeMenuAction:(MenuAction*)menuAction;

/**
 * Provide the array of UIView of the current menu actions
 */
@property (nonatomic,readonly) NSArray *menuActions;

@end

/**
 * A delegate that can be plugged to the menu manager so that the presented snippet
 * could be informed of its presentation state change.
 */
@protocol PMLSnippetDelegate <NSObject>
-(PMLPopupActionManager*)actionManager;
@optional
-(void)menuManager:(PMLMenuManagerController*)menuManager snippetWillOpen:(BOOL)animated;
-(void)menuManagerSnippetDidOpen:(PMLMenuManagerController*)menuManager;
-(void)menuManager:(PMLMenuManagerController*)menuManager snippetMinimized:(BOOL)animated;
-(void)menuManager:(PMLMenuManagerController*)menuManager snippetDismissed:(BOOL)animated;
// Callback method called when snippet is panned
-(void)menuManager:(PMLMenuManagerController*)menuManager snippetPanned:(float)pctOpened;

@end

@class PMLMenuManagerController;

/**
 * A protocol that could be implemented by view controllers managed by UIMenuManagerController
 * so that they will get access to their parent manager and some container features.
 */
//@protocol UIMenuManaged <NSObject>
//
//@property (nonatomic,strong) UIMenuManagerController *parentMenuController;
//
//@end

@interface UIViewController (UIMenuManagerControllerItem)

/**
 * Points to the currently attached menu controller
 */
@property (nonatomic,strong) PMLMenuManagerController *parentMenuController;


@end

typedef void(^TextInputCallback)(NSString *text);

/**
 * The UIMenuManagerController is the container of view controllers and decorates
 * them with menu items and manages view apparitions and transitions
 */
@interface PMLMenuManagerController : UIViewController <UIGestureRecognizerDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic,strong) NSObject<PMLMenuManagerDelegate> *menuManagerDelegate;
@property (nonatomic,strong) NSObject<PMLSnippetDelegate> *snippetDelegate;
@property (nonatomic,strong) MapViewController *rootViewController;
@property (nonatomic,strong) UIViewController *menuViewController;
@property (nonatomic,strong) PMLDataManager *dataManager; // Gives access to the data manager from children
@property (nonatomic,retain) CALObject *contextObject; // Current context object
@property (nonatomic) BOOL snippetFullyOpened; // Whether the snippet is 100% open and hides other views
@property (nonatomic,strong) PMLMainNavBarView *mainNavBarView; // Nav bar access
@property (weak, nonatomic) IBOutlet UIView *topWarningView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topWarningViewTopContraint;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomContainerConstraint;

@property (weak, nonatomic) IBOutlet UIImageView *adContainerImage;
@property (weak, nonatomic) IBOutlet UILabel *topWarningLabel;
@property (weak, nonatomic) UIViewController *currentSnippetViewController;
@property (nonatomic,strong) UIView *bottomView;
//@property (nonatomic,strong) UILabel *topWarningLabel;
/**
 * Initializes this menu manager with the given root UIViewController
 * @param rootViewController the root UIViewController that will first be displayed 
 * @param menuManagerDelegate the delegate of menu actions
 */
-(id)initWithViewController:(MapViewController*)rootViewController with:(NSObject<PMLMenuManagerDelegate>*)menuManagerDelegate;

/**
 * Presents the provided UIViewController as a snippet (meaning we present only the top part at the very
 * bottom of the screen, letting the user to expand or dismiss it.
 */
-(void)presentControllerSnippet:(UIViewController*)viewController;
- (void)presentControllerSnippet:(UIViewController *)childViewController animated:(BOOL)animated;
- (void)presentControllerSnippet:(UIViewController *)childViewController animated:(BOOL)animated opened:(BOOL)opened ;
/**
 * Presents the given menu popping from the given point.
 * @param viewController the view controller to present
 * @param origin the point where the menu comes up from
 * @param pctHeight the height of the menu expressed in percentage of the screen height
 */
-(void)presentControllerMenu:(UIViewController*)viewController from:(CGPoint)origin withHeightPct:(CGFloat)pctHeight;
/**
 * Dismisses any menu currently presented and does nothing if no menu is shown
 */
-(void)dismissControllerMenu:(BOOL)animated;

/**
 * Opens the snippet which is currently being presented. Does nothing if no snippet is active
 */
-(void)openCurrentSnippet:(BOOL)animated;
-(void)minimizeCurrentSnippet:(BOOL)animated;

-(void) dragSnippet:(CGPoint)location velocity:(CGPoint)velocity state:(UIGestureRecognizerState)state;
/**
 * Dismiss any currently displayed snippet
 * @return true if snippet has been dismissed or FALSE if there was something else to dismiss before
 *          (like a user input dialog)
 */
-(BOOL)dismissControllerSnippet;
-(void)dismissSearch;
//- (void)installNavigationFor:(UIViewController*)controller;
//- (void)uninstallNavigation;
/**
 * Displays the given warning message
 * @param message the message to display
 * @param color the color of the background (alpha should be 0.8)
 * @param animated whether or not an activity indicator should be displayed next to the text
 * @param durationSeconds the duration of the message appearance (0 means eternal)
 */
-(void)setWarningMessage:(NSString*)message color:(UIColor*)color animated:(BOOL)animated duration:(NSTimeInterval)durationSeconds;
/**
 * Clears any warning message currently shown, has no effect when no warning message is displayed
 */
-(void)clearWarningMessage;
-(void)presentModal:(UIViewController*)controller;
@end
