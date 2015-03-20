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
#import "PMLMainNavBarView.h"
#import "FiltersViewController.h"
#import "MainMenuTableViewController.h"
#import "PMLFakeViewController.h"
#import "UIViewController+BackButtonHandler.h"
#import "SpringTransitioningDelegate.h"
#import "PMLSnippetTableViewController.h"

#define kSnippetHeight 110

@interface PMLMenuManagerController ()
@property (nonatomic, strong) SpringTransitioningDelegate *transitioningDelegate;
@end

static void *MyParentMenuControllerKey;
@implementation UIViewController (UIMenuManagerControllerItem)

-(PMLMenuManagerController *)parentMenuController {
    PMLMenuManagerController *parentController = objc_getAssociatedObject(self, &MyParentMenuControllerKey);
    // If we have it defined, we return it
    if(parentController!= nil) {
        return parentController;
    } else if(self.navigationController != nil) {
        // Otherwise, we pass the call to our parent navigation controller
        parentController = self.navigationController.parentMenuController;
        if(parentController == nil) {
            return [[TogaytherService uiService] menuManagerController];
        } else {
            return parentController;
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
//    UIView *_bottomView;
    
    // Menu view for left slide interaction
    UIView *_menuView;
    UIImageView *_gripView;
    
    // Gesture recognizer
    UIAttachmentBehavior *_panAttachmentBehaviour;
    
    // Input management
    UITextInputView *_inputView;
    TextInputCallback _currentInputCallback;
    
    // Keyboard state (for adjusting snippet
    CGSize _kbSize;
    BOOL _keyboardShown;

    UIView *_progressView;
    
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

- (instancetype)initWithViewController:(MapViewController *)rootViewController with:(NSObject<PMLMenuManagerDelegate> *)menuManagerDelegate
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
- (void)setRootViewController:(MapViewController *)rootViewController {
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
    CGRect myFrame = self.rootViewController.view.bounds;
    CGRect bottomFrame = CGRectMake(myFrame.origin.x, myFrame.origin.y + myFrame.size.height, myFrame.size.width, myFrame.size.height);
    
    // Initializing the bottom view and adding to our controller view
    _bottomView = [[UIView alloc] initWithFrame:bottomFrame];
    [self.view addSubview:_bottomView];
    
    // Status bar view
    UIView *statusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 20)];
    statusView.backgroundColor = [UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1];
    [self.view addSubview:statusView];
    
    // Grip
    _gripView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"snpGripTop"]];
    
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
    [_mainNavBarView.leftContainerView addGestureRecognizer:tapRecognizer];
    _mainNavBarView.leftContainerView.userInteractionEnabled=YES;
    
    // Adding the badge view for messages
    MKNumberBadgeView *badgeView = [[MKNumberBadgeView alloc] init];
    badgeView.frame = CGRectMake(_mainNavBarView.appIconView.frame.size.width-10, -10, 30, 20);
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
    self.topWarningViewTopContraint.constant=self.navigationController.navigationBar.frame.size.height+[UIApplication sharedApplication].statusBarFrame.size.height;
//    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
//        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
//    }
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

#pragma mark - Snippet management
- (void)presentControllerSnippet:(UIViewController *)childViewController {
    [self presentControllerSnippet:childViewController animated:YES];
}
-(void)removeCurrentSnippetController {
    // Detaching current controller
    if(_currentSnippetViewController) {
        [_currentSnippetViewController willMoveToParentViewController:nil];
        [_currentSnippetViewController.view removeFromSuperview];
        [_currentSnippetViewController removeFromParentViewController];
//        [self.menuManagerDelegate layoutMenuActions];
        _currentSnippetViewController = nil;
        [_gripView removeFromSuperview];
    }
}
- (void)presentControllerSnippet:(UIViewController *)childViewController animated:(BOOL)animated {
    CGRect myFrame = self.rootViewController.view.bounds;

    [self removeCurrentSnippetController];
    // Initializing child inside a sub navigation
    //    PMLSubNavigationController *viewController = [[PMLSubNavigationController alloc] initWithRootViewController:childViewController];
    UINavigationController *viewController = [[UINavigationController alloc] initWithRootViewController:childViewController];
    [viewController.interactivePopGestureRecognizer setDelegate:self];
    
    // Placing the frame at the bottom of the visible current view, outside
    CGRect bottomFrame = CGRectMake(myFrame.origin.x, myFrame.origin.y + myFrame.size.height-_kbSize.height, myFrame.size.width, myFrame.size.height+1-[self offsetForOpenedSnippet]);
    _bottomView.frame = bottomFrame;
    _bottomView.opaque=YES;
    
    // Grip view alignement
    [_gripView removeFromSuperview];
    CGRect frame = _bottomView.frame;
    CGRect gripFrame = _gripView.frame;
    _gripView.frame = CGRectMake(CGRectGetMidX(frame)-CGRectGetWidth(gripFrame)/2, -gripFrame.size.height+1, gripFrame.size.width, gripFrame.size.height);
    [_bottomView addSubview:_gripView];
    
    // Assigning the menu controller for access from children
    viewController.parentMenuController = self;
    
    // Adding the view controller to our hierarchy
    [self addChildViewController:viewController];
    viewController.view.frame = CGRectMake(0, 0, myFrame.size.width, myFrame.size.height+1-[self offsetForOpenedSnippet]);
    [_bottomView addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
    _currentSnippetViewController = viewController;
    [self setSnippetFullyOpened:NO];
    // Now animating
    [_animator removeAllBehaviors];
    
    // Positioning snippet
    NSInteger offset = myFrame.size.height-kSnippetHeight-_kbSize.height;
    [self animateSnippetToOffset:offset animated:animated];
    [self dismissControllerMenu:animated];
    
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
        
        [self animateSnippetToOffset:self.view.bounds.size.height+_gripView.frame.size.height animated:YES];
        dismissed= YES;
    } else {
        // No snippet equals dismissed
        dismissed = YES;
    }
    [self setSnippetFullyOpened:NO];
    // Dismissing menu
    [self dismissControllerMenu:YES];
    return dismissed;
}


- (void)openCurrentSnippet:(BOOL)animated {
    if(_currentSnippetViewController != nil) {
        [self setSnippetFullyOpened:YES];
        NSInteger top = [self offsetForOpenedSnippet];
        [self animateSnippetToOffset:top animated:animated];
    }
}
- (void)minimizeCurrentSnippet:(BOOL)animated {
    if(_currentSnippetViewController != nil) {
        [self setSnippetFullyOpened:NO];
        NSInteger offset = [self offsetForMinimizedSnippet];
        [self animateSnippetToOffset:offset animated:animated];
    }
}
- (void)setSnippetFullyOpened:(BOOL)snippetFullyOpened {
    // We are opening it from a non-opened state
    if(!_snippetFullyOpened && snippetFullyOpened) {
        
        // So we fade out the nav view
        _snippetFullyOpened = snippetFullyOpened;
        
        // Removing nav bar
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        
    } else if( _snippetFullyOpened && !snippetFullyOpened) {
        
        // We are minimizing the snippet from an opened state
        _snippetFullyOpened = snippetFullyOpened;
        
        // Showing nav bar
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    
    // Notifying delegate
    [self sendSnippetDelegateState:YES];
}

- (id<PMLSnippetDelegate>)snippetDelegateFor:(NSObject*)object {
    return self.snippetDelegate;
}

- (void)sendSnippetDelegateState:(BOOL)animated {
    if(_snippetFullyOpened && [self.snippetDelegate respondsToSelector:@selector(menuManager:snippetOpened:)]) {
        [self.snippetDelegate menuManager:self snippetOpened:animated];
    } else if(!_snippetFullyOpened && [self.snippetDelegate respondsToSelector:@selector(menuManager:snippetMinimized:)]) {
        [self.snippetDelegate menuManager:self snippetMinimized:animated];
    }
}
- (void)presentControllerMenu:(UIViewController *)viewController from:(CGPoint)origin withHeightPct:(CGFloat)pctHeight {

    // Adjusting frame
    CGRect bounds = self.view.bounds;
//    CGRect menuFrame = CGRectMake(-bounds.size.width*3/4, 0, bounds.size.width*3/4, bounds.size.height);
    
    if(_menuViewController !=nil && [_menuViewController isKindOfClass:[viewController class]]) {
        [self dismissControllerMenu:YES];
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
        NSLog(@"Center x=%d Y=%d",(int)_menuView.center.x,(int)_menuView.center.y);
        _menuView.layer.anchorPoint = anchorPoint;
        _menuView.frame = frame;
        NSLog(@"NEW Center x=%d Y=%d",(int)_menuView.center.x,(int)_menuView.center.y);
        UIPopBehavior *popBehavior = [[UIPopBehavior alloc] initWithViews:@[_menuView] pop:YES delay:NO completion:nil];
        popBehavior.elasticity=0.3;
        [_menuAnimator removeAllBehaviors];
        [_menuAnimator addBehavior:popBehavior];

    }
}
//-(void) removeConstraints:(UIView*)view {
//    [view removeConstraints:view.constraints];
//    for(UIView *childView in view.subviews) {
//        [self removeConstraints:childView];
//    }
//}
- (void)dismissControllerMenu:(BOOL)animated {
    if(_menuView != nil) {
        CGRect frame = _menuView.frame;
        frame = CGRectMake(-frame.size.width-1, frame.origin.y, frame.size.width, frame.size.height);
        [_menuAnimator removeAllBehaviors];
        if(animated) {
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                _menuView.frame = frame;
            } completion:^(BOOL finished) {
                [_menuView removeFromSuperview];
                _menuView = nil;
                _menuViewController = nil;
                _menuViewController.parentMenuController=nil;
            }];
        } else {
            [_menuView removeFromSuperview];
            _menuView = nil;
            _menuViewController = nil;
            _menuViewController.parentMenuController=nil;
        }
        
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
    CGPoint topRight = CGPointMake(self.view.bounds.size.width-5, 5+self.navigationController.navigationBar.frame.size.height+20);
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:filtersController];
    [self presentControllerMenu:navController from:topRight withHeightPct:0.7];
}
#pragma mark - PanGestureRecognizer
-(void) dragSnippet:(CGPoint)location velocity:(CGPoint)velocity state:(UIGestureRecognizerState)state {

    location.x = CGRectGetMidX(self.view.bounds);
    if ( state == UIGestureRecognizerStateBegan) {
        [_animator removeAllBehaviors];
        
        _panAttachmentBehaviour = [[UIAttachmentBehavior alloc] initWithItem:_bottomView attachedToAnchor:location];
        [_animator addBehavior:_panAttachmentBehaviour];
        
        // Adding a collision to the screen top edge to constraint snippet in view bounds
        UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[_bottomView]];
        NSInteger top = [self offsetForOpenedSnippet];
        [collision addBoundaryWithIdentifier:@"top" fromPoint:CGPointMake(-4000, top) toPoint:CGPointMake(4000, top)];
        [_animator addBehavior:collision];
        
    } else if (state  == UIGestureRecognizerStateChanged) {
        _panAttachmentBehaviour.anchorPoint = location;
        [self snippetPannedCallback];

    } else if (state  == UIGestureRecognizerStateEnded) {
        // Getting frames for whole view and bottom 'sliding' view
        CGRect bottomFrame = _bottomView.frame;
        CGRect viewFrame = self.view.frame;
        CGFloat midY = CGRectGetMidY(viewFrame);
        NSInteger offset = 0;
        
        // If our bottom frame, with added velocity, is above mid-page
        if (bottomFrame.origin.y + velocity.y/4 < midY) {
            // Then we open full page
            [self setSnippetFullyOpened:YES];
            offset = [self offsetForOpenedSnippet];
        } else if(bottomFrame.origin.y > self.view.bounds.size.height-(kSnippetHeight/2)) {
//            [self setSnippetFullyOpened:NO];
//            offset=self.view.bounds.size.height-kSnippetHeight+_gripView.frame.size.height;
            [self dismissControllerSnippet];
            return;
        } else {
            // Otherwise we close it back to snippet
            [self setSnippetFullyOpened:NO];
            
            offset = [self offsetForMinimizedSnippet];
        }
        
        // Animating snippet
        [self animateSnippetToOffset:offset animated:YES];
    }
}
-(void)animateSnippetToOffset:(NSInteger)offset animated:(BOOL)animated {
    // Building the 'open' (or 'close') behavior
    [_animator removeAllBehaviors];
    if(_bottomView.frame.origin.y!=offset) {
        CGRect frame = _bottomView.frame;
        frame.origin.y=offset;
        frame.origin.x=0;
        if(animated) {
            [UIView animateWithDuration:0.3 animations:^{
                _bottomView.frame = frame;
            } completion:^(BOOL finished) {
                if(frame.origin.y>self.view.bounds.size.height) {
                    [self removeCurrentSnippetController];
                }
            }];
        } else {
            _bottomView.frame = frame;
            if(frame.origin.y>self.view.bounds.size.height) {
                [self removeCurrentSnippetController];
            }
        }
    }
}
- (void)snippetPannedCallback {
    
    // Callbacking delegate
//    if([self.snippetDelegate respondsToSelector:@selector(menuManager:snippetPanned:)]) {
//        CGPoint location = _bottomView.frame.origin;
//        CGSize size = self.view.bounds.size;

//        float pctOpened = 1.0f - ((float)(location.y-kPMLSnippetTopOffset) / (float)(size.height- (kSnippetHeight-kPMLSnippetTopOffset)));
//                NSLog(@"PCT=%.02f / Loc y= %.02f / Height= %.02f",pctOpened, location.y,size.height);
//        [self.snippetDelegate menuManager:self snippetPanned:pctOpened];
//    }
}
-(NSInteger)offsetForMinimizedSnippet {
    CGRect myFrame = self.view.frame;
    return myFrame.size.height  - kSnippetHeight;
}
-(NSInteger)offsetForOpenedSnippet {
//    CGRect bounds = self.view.bounds;
    NSInteger top = kPMLSnippetTopOffset;
//    if(bounds.size.height> 600) {
//        top = MAX(bounds.size.height-600,0);
//    }
    return top;
}
#pragma mark - UIPanGestureRecognizerDelegate
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
//    return YES;
//}
#pragma mark Menu
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if(gestureRecognizer == ((UINavigationController*)_currentSnippetViewController).interactivePopGestureRecognizer) {
        return ((UINavigationController*)_currentSnippetViewController).childViewControllers.count>1;
    } else {
        CGPoint velocity = [(UIPanGestureRecognizer*)gestureRecognizer velocityInView:_menuView];
        return (fabs(velocity.x)>fabs(velocity.y) && velocity.x <0);
    }
}
- (void)menuPanned:(UITapGestureRecognizer*)gestureRecognizer {
    if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self dismissControllerMenu:YES];
    }
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

    NSDictionary* info = [aNotification userInfo];
    _kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    NSNumber *duration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    CGRect snippetBounds = _bottomView.frame;
    if(snippetBounds.origin.y>_kbSize.height) {
        _keyboardShown = YES;
        [_animator removeAllBehaviors];
        // Then we move it above keyboard
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:duration.doubleValue];
        [UIView setAnimationCurve:curve.intValue];
        [UIView setAnimationBeginsFromCurrentState:YES];
        // Computing proper Y
        CGFloat snippetTop ;
        if( _snippetFullyOpened ) {
            snippetTop = [self offsetForOpenedSnippet]+_kbSize.height;
        } else {
            snippetTop = [self offsetForMinimizedSnippet];
        }
        _bottomView.frame = CGRectMake(snippetBounds.origin.x, snippetBounds.origin.y-_kbSize.height, snippetBounds.size.width, snippetBounds.size.height);
        
        [UIView commitAnimations];
        
    }
}
-(void)keyboardWillBeHidden:(NSNotification*)aNotification
{


    NSDictionary* info = [aNotification userInfo];
    NSNumber *duration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    CGRect snippetBounds = _bottomView.frame;

    if(snippetBounds.origin.y>0 && _keyboardShown && !_snippetFullyOpened) {

        // Then we move it above keyboard
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:duration.doubleValue];
        [UIView setAnimationCurve:curve.intValue];
        [UIView setAnimationBeginsFromCurrentState:YES];
        _bottomView.frame = CGRectMake(snippetBounds.origin.x, self.view.frame.size.height-kSnippetHeight, snippetBounds.size.width, snippetBounds.size.height);
        
        [UIView commitAnimations];
    }
    _keyboardShown = NO;
    _kbSize.height = 0;
    _kbSize.width = 0;

}

-(void)revealLeftMenu:(UIView*)sender {
    NSLog(@"Reveal");

    // Clearing any menu
    if(_menuViewController !=nil) {
        [self dismissControllerMenu:YES];
    } else {
        // Just in case we have residual animation artefacts
        [_menuView removeFromSuperview];
        
        // Instantiating menu view if needed
        CGRect frame = self.view.window.frame;
        frame.size.width = MIN(4.0f/5.0f*frame.size.width,300);
        frame.size.height -= self.navigationController.navigationBar.frame.size.height+[UIApplication sharedApplication].statusBarFrame.size.height-1;
        frame = CGRectOffset(frame, -frame.size.width, self.navigationController.navigationBar.frame.size.height+[UIApplication sharedApplication].statusBarFrame.size.height);
        
        // Building standard menu
        _menuView = [[UIView alloc] initWithFrame:frame];
        _menuView.backgroundColor = UIColorFromRGB(0x272a2e);
        _menuView.opaque=YES;
        _menuView.layer.shadowOffset = CGSizeMake(1, 1);
        _menuView.layer.shadowColor = [[UIColor blackColor] CGColor];
        _menuView.layer.shadowRadius = 2;
        _menuView.layer.shadowOpacity = 0.7;
        _menuView.layer.shadowPath = [[UIBezierPath bezierPathWithRect:_menuView.layer.bounds] CGPath];
        _menuView.layer.borderColor = UIColorFromRGB(0xf36523).CGColor;
        _menuView.layer.borderWidth=1;
        _menuView.clipsToBounds = NO;
        [self.view addSubview:_menuView];
        
        // Building contents
        MainMenuTableViewController *rearView = (MainMenuTableViewController*)[_uiService instantiateViewController:SB_ID_FILTERS_CONTROLLER];
        rearView.parentMenuController = self;
//        rearView.view.bounds=CGRectMake(0,0,frame.size.width, frame.size.height);
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:rearView];
        
        _menuViewController = navController;
        _menuViewController.parentMenuController = self;
        [self addChildViewController:_menuViewController];
        _menuViewController.view.frame = CGRectMake(0,0, frame.size.width, frame.size.height);
        [_menuView addSubview:_menuViewController.view];
        [_menuViewController didMoveToParentViewController:self];
        
        // Pan gesture for dismissing menu
        UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(menuPanned:)];
        [recognizer setMaximumNumberOfTouches:1];
        [recognizer setMinimumNumberOfTouches:1];
        recognizer.delegate=self;
        [_menuView addGestureRecognizer:recognizer];
        
        // Displaying menu
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _menuView.frame = CGRectMake(-2, frame.origin.y, frame.size.width, frame.size.height);
        } completion:nil];
        [_menuAnimator removeAllBehaviors];

    }
    
}
#pragma mark - Snippet delegate
- (void)setSnippetDelegate:(NSObject<PMLSnippetDelegate> *)snippetDelegate {
    _snippetDelegate = snippetDelegate;
    [self sendSnippetDelegateState:NO];
}

#pragma mark - Modal
- (void)presentModal:(UIViewController *)controller {
    // Preparing transition
    self.transitioningDelegate = [[SpringTransitioningDelegate alloc] initWithDelegate:self];
    self.transitioningDelegate.transitioningDirection = TransitioningDirectionDown;
    [self.transitioningDelegate presentViewController:controller];
}
@end
