//
//  UIMenuManagerController.m
//  PelMel
//
//  Created by Christophe Fondacci on 12/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLMenuManagerController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIPopBehavior.h"
#import <objc/runtime.h>
#import "UIMenuOpenBehavior.h"
#import "CurrentUser.h"
#import "Imaged.h"
#import "ModelHolder.h"
#import "TogaytherService.h"
#import "PMLDataManager.h"
#import "UITextInputView.h"
#import "UITouchBehavior.h"
#import "PMLSubNavigationController.h"
#import "PMLMainNavBarView.h"
#import "PMLSnippetViewController.h"
#import "FiltersViewController.h"
#import "MainMenuTableViewController.h"

#define kSnippetHeight 100

@interface PMLMenuManagerController ()

@end

static void *MyParentMenuControllerKey;
@implementation UIViewController (UIMenuManagerControllerItem)

-(PMLMenuManagerController *)parentMenuController {
    PMLMenuManagerController *parentController = objc_getAssociatedObject(self, &MyParentMenuControllerKey);
    // If we have it defined, we return it
    if(parentController!= nil) {
        return parentController;
    } else {
        // Otherwise, we pass the call to our parent navigation controller
        if(self.subNavigationController != nil) {
            return self.subNavigationController.parentMenuController;
        } else if(self.navigationController != nil) {
            return self.navigationController.parentMenuController;
        } 
    }
    return nil;
}
-(void)setParentMenuController:(PMLMenuManagerController *)parentMenuController {
    objc_setAssociatedObject(self, &MyParentMenuControllerKey, parentMenuController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
@implementation PMLMenuManagerController {
    
    // Services
    UIService *_uiService;
    DataService *_dataService;
    
    // Our main animator
    UIDynamicAnimator *_animator;
    UIDynamicAnimator *_menuAnimator;
    
    // Bottom view for cover view
    UIView *_bottomView;
    
    // Menu view for left slide interaction
    UIView *_menuView;
    
    // Gesture recognizer
    UIAttachmentBehavior *_panAttachmentBehaviour;
    
    // Input management
    UITextInputView *_inputView;
    TextInputCallback _currentInputCallback;
    
    // Keyboard state (for adjusting snippet
    CGSize _kbSize;
    BOOL _keyboardShown;

    UIProgressView *_progressView;
    
    // State
    BOOL _initialized;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        // Initializing data manager
        self.dataManager = [[PMLDataManager alloc] initWith:self];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        // Initializing data manager
        self.dataManager = [[PMLDataManager alloc] initWith:self];
    }
    return self;
}
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initializing data manager
        self.dataManager = [[PMLDataManager alloc] initWith:self];
    }
    return self;
}

- (instancetype)initWithViewController:(UIViewController *)rootViewController with:(NSObject<PMLMenuManagerDelegate> *)menuManagerDelegate
{
    self = [super init];
    if (self) {
        self.menuManagerDelegate = menuManagerDelegate;
        self.rootViewController = rootViewController;
        // Initializing data manager
        self.dataManager = [[PMLDataManager alloc] initWith:self];
        
    }
    return self;
}
- (void)setRootViewController:(UIViewController *)rootViewController {
    _rootViewController = rootViewController;
    // Assigning ourselves to the navigation hierarchy
    rootViewController.parentMenuController = self;
    
    // Adding root as child
    [self addChildViewController:self.rootViewController];
}
- (void)viewDidLoad
{
    [super viewDidLoad];

    
    // Initializing navigation
    _uiService = [TogaytherService uiService];
    _dataService = [TogaytherService dataService];
    [TogaytherService applyCommonLookAndFeel:self];
    
    // Configuring main nav bar
    [self configureNavBar];

    
    // Do any additional setup after loading the view.
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    _menuAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    [self.view insertSubview:self.rootViewController.view belowSubview:_topWarningView];
    [self.rootViewController didMoveToParentViewController:self];
    
    [self registerForKeyboardNotifications];
    
    
    // Progress (saving it to register it when view appears just in case other views had taken control)
    _progressView = [_uiService addProgressTo:self.navigationController];
    
    // Initializing bottom view
    CGRect myFrame = self.view.frame;
    CGRect bottomFrame = CGRectMake(myFrame.origin.x, myFrame.origin.y + myFrame.size.height, myFrame.size.width, myFrame.size.height);
    
    // Initializing the bottom view and adding to our controller view
    _bottomView = [[UIView alloc] initWithFrame:bottomFrame];
    [self.view addSubview:_bottomView];
    
    // Warning label@
//    [self configureWarningLabel];

}

- (void)configureNavBar {
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"PMLMainNavBarView" owner:self options:nil];
    _mainNavBarView = [views objectAtIndex:0];
    self.navigationItem.titleView = _mainNavBarView;
    //    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mnuIconReveal"] style:UIBarButtonItemStylePlain target:self action:@selector(revealLeftMenu:)];
    CGRect navFrame = self.navigationController.navigationBar.bounds;
    _mainNavBarView.frame = navFrame;
    _mainNavBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_mainNavBarView.searchTextField addTarget:self action:@selector(searchFocused:) forControlEvents:UIControlEventEditingDidBegin];
    [_mainNavBarView.cancelButton addTarget:self action:@selector(searchCancelled:) forControlEvents:UIControlEventTouchUpInside];
    _mainNavBarView.searchTextField.delegate = self;
    _mainNavBarView.searchTextField.placeholder = NSLocalizedString(@"search.placeholder", @"Search a place or a city");
    [_mainNavBarView.searchTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    _mainNavBarView.cancelButton.transform = CGAffineTransformMakeRotation(-M_PI);
    
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    // Binding filter action
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(filtersTapped:)];
    [_mainNavBarView.filtersView addGestureRecognizer:tapRecognizer];
    
    // Binding reveal menu
    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(revealLeftMenu:)];
    [_mainNavBarView.appIconView addGestureRecognizer:tapRecognizer];
    _mainNavBarView.appIconView.userInteractionEnabled=YES;
    
    // Adding the badge view for messages
    MKNumberBadgeView *badgeView = [[MKNumberBadgeView alloc] init];
    badgeView.frame = CGRectMake(_mainNavBarView.appIconView.frame.size.width-20, -10, 30, 20);
    badgeView.font = [UIFont fontWithName:PML_FONT_BADGES size:10];
    badgeView.shadow = NO;
    badgeView.shine=NO;
    [_mainNavBarView.appIconView addSubview:badgeView];
    
    // Registering it
    [[TogaytherService getMessageService] setMessageCountBadgeView:badgeView];
}

- (void)viewDidAppear:(BOOL)animated {
    if(!_initialized) {
        CGRect myFrame = self.view.frame;
        CGRect bottomFrame = CGRectMake(myFrame.origin.x, myFrame.origin.y + myFrame.size.height, myFrame.size.width, myFrame.size.height);
        _bottomView.frame = bottomFrame;
        // Initializing actions
        [self.menuManagerDelegate initializeActionsFor:self belowView:_bottomView];
        [[TogaytherService userService] authenticateWithLastLogin:nil];
        _initialized = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [TogaytherService applyCommonLookAndFeel:self];
    [_uiService setProgressView:_progressView];
//    [self dismissControllerMenu];
}

-(void)refresh {
    [_dataManager refresh];
}

-(void)searchText {
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)presentControllerSnippet:(UIViewController *)childViewController {
    CGRect myFrame = self.view.bounds;
    // Detaching current controller
    if(_currentSnippetViewController) {
        [_currentSnippetViewController willMoveToParentViewController:nil];
        [_currentSnippetViewController.view removeFromSuperview];
        [_currentSnippetViewController removeFromParentViewController];
        [self.menuManagerDelegate layoutMenuActions];
    }
    
    // Initializing child inside a sub navigation
    PMLSubNavigationController *viewController = [[PMLSubNavigationController alloc] initWithRootViewController:childViewController];
    
    // Placing the frame at the bottom of the visible current view, outside
    CGRect bottomFrame = CGRectMake(myFrame.origin.x, myFrame.origin.y + myFrame.size.height-_kbSize.height, myFrame.size.width, myFrame.size.height+1);
    _bottomView.frame = bottomFrame;
//    _bottomView.backgroundColor = [UIColor redColor];
    _bottomView.opaque=YES;
    
    // Assigning the menu controller for access from children
    viewController.parentMenuController = self;
    
    // Adding the view controller to our hierarchy
    [self addChildViewController:viewController];
    viewController.view.frame = CGRectMake(0, 0, myFrame.size.width, myFrame.size.height+1);
    [_bottomView addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
    _currentSnippetViewController = viewController;
    
    // Now animating
    [_animator removeAllBehaviors];

    UIMenuOpenBehavior *menuBehavior = [[UIMenuOpenBehavior alloc] initWithViews:@[_bottomView] open:YES boundary:myFrame.size.height-kSnippetHeight-_kbSize.height];
    [menuBehavior addPushedActions:self.menuManagerDelegate.menuActions inBounds:self.view.bounds];
    [_animator addBehavior:menuBehavior];
    
    // And dismissing menu
    [self dismissControllerMenu];

}

- (BOOL)dismissControllerSnippet {
    BOOL dismissed = NO;
    if(_inputView != nil) {
        [_inputView removeFromSuperview];
        _inputView = nil;
        dismissed = NO;
    } else if(_currentSnippetViewController) {
        // Animating (real de-allocation will be made if a new view controller is presented)
        [_animator removeAllBehaviors];
        CGRect myFrame = self.view.frame;

        // Dismissing and pushing menu views
        UIMenuOpenBehavior *menuBehavior = [[UIMenuOpenBehavior alloc] initWithViews:@[_bottomView] open:NO boundary:myFrame.size.height+_bottomView.frame.size.height];
        [menuBehavior addPushedActions:self.menuManagerDelegate.menuActions inBounds:self.view.bounds];
        [_animator addBehavior:menuBehavior];
        dismissed= YES;
    } else {
        // No snippet equals dismissed
        dismissed = YES;
    }
    
    // Dismissing menu
    [self dismissControllerMenu];
    return dismissed;
}

- (void)openCurrentSnippet {
    if(_currentSnippetViewController != nil) {
        _snippetFullyOpened = YES;
        NSInteger top = [self offsetForOpenedSnippet];
        UIMenuOpenBehavior *menuBehavior = [[UIMenuOpenBehavior alloc] initWithViews:@[_bottomView] open:YES boundary:top];
        [_animator removeAllBehaviors];
        [_animator addBehavior:menuBehavior];
    }
}

- (void)presentControllerMenu:(UIViewController *)viewController from:(CGPoint)origin withHeightPct:(CGFloat)pctHeight {

    // Adjusting frame
    CGRect bounds = self.view.bounds;
//    CGRect menuFrame = CGRectMake(-bounds.size.width*3/4, 0, bounds.size.width*3/4, bounds.size.height);
    
    if(_menuViewController !=nil && [_menuViewController isKindOfClass:[viewController class]]) {
        [self dismissControllerMenu];
        _menuViewController = nil;
    } else {
        [_menuView removeFromSuperview];
        
        // Computing width, height and frame
        CGFloat menuWidth = bounds.size.width*4/5;
        CGFloat menuHeight = bounds.size.height*pctHeight;
        CGRect frame;
        CGPoint anchorPoint;
        if(origin.x+menuWidth< bounds.size.width) {
            frame.origin.x = origin.x;
            anchorPoint.x = 0;
        } else {
            frame.origin.x = origin.x - menuWidth;
            anchorPoint.x=1;
        }
        if(origin.y+menuHeight< bounds.size.height) {
            frame.origin.y = origin.y;
            anchorPoint.y = 0;
        } else {
            frame.origin.y = origin.y - menuHeight;
            anchorPoint.y=1;
        }
        frame.size.width = menuWidth;
        frame.size.height = menuHeight;
        
        // Instantiating menu view if needed
        _menuView = [[UIView alloc] initWithFrame:frame];
        _menuView.backgroundColor = UIColorFromRGB(0x272a2e);
        _menuView.opaque=YES;
        _menuView.layer.borderColor = UIColorFromRGB(0xf36523).CGColor;
        _menuView.layer.borderWidth=2;
        _menuView.layer.cornerRadius = 5;
        _menuView.clipsToBounds = YES;
        [self.view insertSubview:_menuView belowSubview:_bottomView];
        
        // Injecting content
        if(viewController!=nil && ![self.childViewControllers containsObject:viewController]) {
            _menuViewController = viewController;
            _menuViewController.parentMenuController = self;
            [self addChildViewController:_menuViewController];
            _menuViewController.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
            [_menuView addSubview:_menuViewController.view];
            [_menuViewController didMoveToParentViewController:self];
        }
        
        // Displaying menu
//        CGPoint menuCenter = [_menuView convertPoint:origin fromView:self.view];
        NSLog(@"Center x=%d Y=%d",(int)_menuView.center.x,(int)_menuView.center.y);
        _menuView.layer.anchorPoint = anchorPoint;
        _menuView.frame = frame;
        NSLog(@"NEW Center x=%d Y=%d",(int)_menuView.center.x,(int)_menuView.center.y);
//        _menuView.translatesAutoresizingMaskIntoConstraints = NO;
        UIPopBehavior *popBehavior = [[UIPopBehavior alloc] initWithViews:@[_menuView] pop:YES delay:NO completion:^{
//            _menuView.translatesAutoresizingMaskIntoConstraints = YES;
//            [_menuView layoutIfNeeded];
        }];
        popBehavior.elasticity=0.3;
        [_menuAnimator removeAllBehaviors];
        [_menuAnimator addBehavior:popBehavior];
        //    UIMenuOpenBehavior *menuBehavior = [[UIMenuOpenBehavior alloc] initWithViews:@[_menuView] open:YES boundary:bounds.size.width*3/4 horizontal:YES];
        //    [menuBehavior addPushedViews:self.menuManagerDelegate.menuViews inBounds:self.view.bounds];
        //
        //    [_menuAnimator removeAllBehaviors];
        //    [_menuAnimator addBehavior:menuBehavior];
    }
}
-(void) removeConstraints:(UIView*)view {
    [view removeConstraints:view.constraints];
    for(UIView *childView in view.subviews) {
        [self removeConstraints:childView];
    }
}
- (void)dismissControllerMenu {
    if(_menuView != nil) {
        [self removeConstraints:_menuView];
        UIPopBehavior *popBehavior = [[UIPopBehavior alloc] initWithViews:@[_menuView] pop:NO delay:NO completion:^{
            [_menuView removeFromSuperview];
            _menuView = nil;
            _menuViewController = nil;
            _menuViewController.parentMenuController=nil;
        }];
        popBehavior.elasticity=0.3;

        [_menuAnimator removeAllBehaviors];
        [_menuAnimator addBehavior:popBehavior];
    }
}
#pragma mark - Warning label
- (void)configureWarningLabel {
//    self.topWarningLabel = [[UILabel alloc] init];
//    [self.view addSubview:self.topWarningLabel];
//    NSDictionary *dic = @{@"warnLabel" : self.topWarningLabel};
//    NSArray *width = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[warnLabel]-0-|" options:0 metrics:nil views:dic];
//    NSArray *height = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[warnLabel(30)]" options:0 metrics:nil views:dic];
//    [self.view addConstraints:width];
//    [self.view addConstraints:height];
//    self.topWarningLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:17];
//    self.topWarningLabel.textColor = [UIColor whiteColor];
//    self.topWarningLabel.hidden=YES;
}
- (void)setWarningMessage:(NSString *)message color:(UIColor *)color animated:(BOOL)animated duration:(NSTimeInterval)durationSeconds {
    if(message != nil) {

        if(self.topWarningView.hidden) {
            self.topWarningView.backgroundColor = color;
            self.topWarningLabel.text = message;
            self.topWarningView.hidden = NO;
            self.topWarningView.alpha=0;
            [UIView animateWithDuration:0.1 animations:^{
                self.topWarningView.alpha=1;
            } completion:^(BOOL finished) {
                if(durationSeconds>0) {
                    [self clearWarningMessageWithDelay:durationSeconds];
                }
            }];
        } else {
            [UIView animateWithDuration:0.1 animations:^{
                self.topWarningView.backgroundColor = color;
                self.topWarningLabel.text = message;
            } completion:^(BOOL finished) {
                if(durationSeconds>0) {
                    [self clearWarningMessageWithDelay:durationSeconds];
                }
            }];
        }
    } else {
        [self clearWarningMessage];
    }
}
- (void)clearWarningMessage {
    [self clearWarningMessageWithDelay:2];
}
-(void)clearWarningMessageWithDelay:(NSTimeInterval)delay{
    if(!self.topWarningView.hidden) {
        [UIView animateWithDuration:0.3 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.topWarningView.alpha=0;
        } completion:^(BOOL finished) {
            self.topWarningView.hidden=YES;
            self.topWarningView.alpha=1;
        }];
    }
}
#pragma mark - Menu actions
- (void)filtersTapped:(UITapGestureRecognizer*)sender {
    
    FiltersViewController *filtersController = (FiltersViewController*)[_uiService instantiateViewController:SB_ID_FILTERS_MENU];
    CGPoint topRight = CGPointMake(self.view.bounds.size.width-5, 5);
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:filtersController];
    [self presentControllerMenu:navController from:topRight withHeightPct:0.7];
}
#pragma mark - PanGestureRecognizer
-(void) dragSnippet:(CGPoint)location velocity:(CGPoint)velocity state:(UIGestureRecognizerState)state {

    location.x = CGRectGetMidX(_bottomView.bounds);
    if ( state == UIGestureRecognizerStateBegan) {
        [_animator removeAllBehaviors];
        
        _panAttachmentBehaviour = [[UIAttachmentBehavior alloc] initWithItem:_bottomView attachedToAnchor:location];
        [_animator addBehavior:_panAttachmentBehaviour];
        
        // Adding a collision to the screen top edge to constraint snippet in view bounds
        UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[_bottomView]];
        [collision addBoundaryWithIdentifier:@"top" fromPoint:CGPointMake(-2000, 1) toPoint:CGPointMake(2000, 1)];
        [_animator addBehavior:collision];
        
    } else if (state  == UIGestureRecognizerStateChanged) {
        _panAttachmentBehaviour.anchorPoint = location;
    } else if (state  == UIGestureRecognizerStateEnded) {
        // Getting frames for whole view and bottom 'sliding' view
        CGRect bottomFrame = _bottomView.frame;
        CGRect viewFrame = self.view.frame;
        CGFloat midY = CGRectGetMidY(viewFrame);
        int offset = 0;
        
        // If our bottom frame, with added velocity, is above mid-page
        if (bottomFrame.origin.y + velocity.y/4 < midY) {
            // Then we open full page
            _snippetFullyOpened = YES;
            offset = [self offsetForOpenedSnippet];
        } else {
            // Otherwise we close it back to snippet
            _snippetFullyOpened = NO;
            CGRect myFrame = self.view.frame;
            offset = myFrame.size.height + _bottomView.frame.size.height - kSnippetHeight;
        }
    
        // Building the 'open' (or 'close') behavior
        UIMenuOpenBehavior *menuBehavior = [[UIMenuOpenBehavior alloc] initWithViews:@[_bottomView] open:_snippetFullyOpened boundary:offset];

        [_animator removeAllBehaviors];
        [_animator addBehavior:menuBehavior];
        
        // Adding the user velocity
        UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[_bottomView] mode:UIPushBehaviorModeInstantaneous];
        pushBehavior.pushDirection = CGVectorMake(0, velocity.y / 20.0f);
        [_animator addBehavior:pushBehavior];
    }
}

-(NSInteger)offsetForOpenedSnippet {
//    CGRect bounds = self.view.bounds;
    NSInteger top = 0;
//    if(bounds.size.height> 600) {
//        top = MAX(bounds.size.height-600,0);
//    }
    return top;
}
#pragma mark - UIPanGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


#pragma mark - UINavigationDelegate
- (void)transitionFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController duration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL))completion {
    NSLog(@"Transition");
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == _inputView.inputText) {
        [self inputDone];
        return YES;
    } else if(textField == _mainNavBarView.searchTextField) {
        [self searchInputDone];
        return YES;
    }
    return NO;
}
- (BOOL)textFieldShouldClear:(UITextField *)textField {
    textField.text = nil;
    [self textFieldDidChange:textField];
    return NO;
}
-(void)textFieldDidChange:(UITextField*)textField {
    NSString *searchText = textField.text;
    
    if(searchText != nil) {
        // Getting current provider
        int matchCount = 0;
        Place *lastMatchedPlace = nil;
        for(Place *place in _dataService.modelHolder.allPlaces) {
            // Getting object's title
            NSString *title = place.title;
            // Searching the text to match
            if(searchText != nil && searchText.length>0 ) {
                
                NSRange range = [title rangeOfString:searchText options:NSCaseInsensitiveSearch];
                // If matched, we display this object
                if(range.location != NSNotFound) {
                    matchCount++;
                    lastMatchedPlace = place;
                    [(MapViewController*)self.rootViewController show:place];
                } else {
                    [(MapViewController*)self.rootViewController hide:place];
                }
            } else {
                [(MapViewController*)self.rootViewController show:place];
            }
        }
        // Auto-selecting if only one match
        if(matchCount == 1) {
            [(MapViewController*)self.rootViewController selectCALObject:lastMatchedPlace withSnippet:YES];
        }
    }
}
- (void) inputDone {
    // Retrieving text
    NSString *inputText = _inputView.inputText.text;
    
    // Removing current input
    [_inputView removeFromSuperview];
    _inputView = nil;
    
    // Calling back
    if(_currentInputCallback!=nil) {
        _currentInputCallback(inputText);
    }
}
- (void) searchInputDone {
    NSString *searchTerm = _mainNavBarView.searchTextField.text;
    [self dismissSearch];
    ((MapViewController*)self.rootViewController).zoomUpdateType = PMLZoomUpdateFitResults;
    [TogaytherService.dataService fetchPlacesFor:nil searchTerm:searchTerm];
//    _mainNavBarView.searchTextField.text = nil;
//    [self textFieldDidChange:_mainNavBarView.searchTextField];
}
-(void)inputButtonTapped:(id)sender {
    [self inputDone];
}

-(void)searchFocused:(id)sender {
    _mainNavBarView.cancelButton.alpha = 0;
    _mainNavBarView.cancelButton.hidden = NO;
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _mainNavBarView.leftContainerView.transform = CGAffineTransformMakeRotation(M_PI);
        _mainNavBarView.cancelButton.alpha = 1;
        _mainNavBarView.appIconView.alpha = 0;
    } completion:nil];
}
-(void)searchCancelled:(id)sender {
//    _mainNavBarView.searchTextField.text=nil;
    [self dismissSearch];
}
-(void)dismissSearch {
    [_mainNavBarView.searchTextField resignFirstResponder];
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _mainNavBarView.leftContainerView.transform = CGAffineTransformIdentity;
        _mainNavBarView.cancelButton.alpha = 0;
        _mainNavBarView.appIconView.alpha = 1;
    } completion:^(BOOL finished) {
        _mainNavBarView.cancelButton.hidden = YES;
    }];
}
#pragma mark - Keyboard management
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}
-(void)unregisterForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)keyboardWillShow:(NSNotification*)aNotification
{
    _keyboardShown = YES;
//    if( [((UIView*)aNotification.object) isDescendantOfView:_bottomView] ) {
        NSDictionary* info = [aNotification userInfo];
        _kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        NSNumber *duration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
        NSNumber *curve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
        
        CGRect viewBounds = self.view.bounds;
        CGRect snippetBounds = _bottomView.frame;
        // Only if snippet is out
        if(snippetBounds.origin.y<viewBounds.size.height) {
            
            // Then we move it above keyboard
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:duration.doubleValue];
            [UIView setAnimationCurve:curve.intValue];
            [UIView setAnimationBeginsFromCurrentState:YES];
            _bottomView.frame = CGRectMake(snippetBounds.origin.x, snippetBounds.origin.y-_kbSize.height, snippetBounds.size.width, snippetBounds.size.height);
            
            // Current snippet controller
//            if([_currentSnippetViewController isKindOfClass:[UITableViewController class]]) {
//                ((UITableViewController*)_currentSnippetViewController).tableView.contentOffset = CGPointMake(0,0);
//            }
            [UIView commitAnimations];
        }
//    }
}
-(void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    _keyboardShown = NO;

    NSDictionary* info = [aNotification userInfo];
    NSNumber *duration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    CGRect snippetBounds = self.view.bounds;

    
    // Then we move it above keyboard
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration.doubleValue];
    [UIView setAnimationCurve:curve.intValue];
    [UIView setAnimationBeginsFromCurrentState:YES];
    _bottomView.frame = CGRectMake(snippetBounds.origin.x, snippetBounds.size.height-kSnippetHeight, snippetBounds.size.width, snippetBounds.size.height);

    [UIView commitAnimations];
    _kbSize.height = 0;
    _kbSize.width = 0;

}

-(void)revealLeftMenu:(UIView*)sender {
    NSLog(@"Reveal");

    // Clearing any menu
    if(_menuViewController !=nil) {
        if(_menuView != nil) {
            UIMenuOpenBehavior *popBehavior = [[UIMenuOpenBehavior alloc] initWithViews:@[_menuView] open:NO boundary:-self.view.frame.size.width horizontal:YES];
            [popBehavior setIntensity:3.0];
            
            [_menuAnimator removeAllBehaviors];
            [_menuAnimator addBehavior:popBehavior];
        }

        _menuViewController = nil;
    } else {
        // Just in case we have residual animation artefacts
        [_menuView removeFromSuperview];
        
        // Instantiating menu view if needed
        CGRect frame = self.view.window.frame;
        frame.size.width = MIN(4.0f/5.0f*frame.size.width,300);
        frame.size.height -= self.navigationController.navigationBar.frame.size.height;
        frame = CGRectOffset(frame, -frame.size.width, 0);
        
        // Building standard menu
        _menuView = [[UIView alloc] initWithFrame:frame];
        _menuView.backgroundColor = UIColorFromRGB(0x272a2e);
        _menuView.opaque=YES;
        _menuView.layer.borderColor = UIColorFromRGB(0xf36523).CGColor;
        _menuView.layer.borderWidth=2;
        _menuView.clipsToBounds = YES;
        [self.view addSubview:_menuView];
        
        // Building contents
        MainMenuTableViewController *rearView = (MainMenuTableViewController*)[_uiService instantiateViewController:SB_ID_FILTERS_CONTROLLER];
//        rearView.view.bounds=CGRectMake(0,0,frame.size.width, frame.size.height);
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:rearView];
        
        _menuViewController = navController;
        _menuViewController.parentMenuController = self;
        [self addChildViewController:_menuViewController];
        _menuViewController.view.frame = CGRectMake(0,0, frame.size.width, frame.size.height);
        [_menuView addSubview:_menuViewController.view];
        [_menuViewController didMoveToParentViewController:self];
        
   
        
        // Displaying menu
        UIMenuOpenBehavior *menuBehavior = [[UIMenuOpenBehavior alloc] initWithViews:@[_menuView] open:YES boundary:frame.size.width-2 horizontal:YES];
        [menuBehavior setIntensity:3.0f];
        
        [_menuAnimator removeAllBehaviors];
        [_menuAnimator addBehavior:menuBehavior];

    }
    
}
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    if(object == _bottomView) {
//        [self updateMenuActions];
//    }
//}
@end
