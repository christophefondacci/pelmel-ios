//
//  UIMenuManagerMainDelegate.m
//  PelMel
//
//  Created by Christophe Fondacci on 12/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "UIMenuManagerMainDelegate.h"
#import "TogaytherService.h"
#import "Constants.h"
#import "UIPopBehavior.h"
#import "UITouchBehavior.h"
#import "MainMenuTableViewController.h"
#import "PMLSnippetTableViewController.h"
#import "TogaytherService.h"
#import "MKNumberBadgeView.h"

#define kPMLLoaderSize 55
#define kPMLActionSize 55

@implementation UIMenuManagerMainDelegate {
    
    // Services
    DataService *_dataService;
    UIService *_uiService;
    
    // Parent menu controller
    PMLMenuManagerController *_menuManagerController;
    UIView *_bottomView;
    
    // Our list of current actions
    NSMutableArray *_actions;
    MenuAction *_loaderAction;
    MenuAction *_eventsAction;

    
    // Menu controls
    NSMutableArray *_menuActions;
    NSMutableSet *_initializedActions;
    
    // Loader
    UIActivityIndicatorView *_activityView;
    UIView *_eventsActionView;
    
    // Animation
    UIDynamicAnimator *_animator;
    UITouchBehavior *_menuTouchBehavior;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // List initializations
        _menuActions = [[NSMutableArray alloc] init];
        _initializedActions = [[NSMutableSet alloc] init];
        _actions = [[NSMutableArray alloc] init];
        _dataService = TogaytherService.dataService;
        _uiService = TogaytherService.uiService;
        // Listening to dataservice events for loader start/stop
        [_dataService registerDataListener:self];
    }
    return self;
}

- (void)initializeActionsFor:(PMLMenuManagerController *)menuManagerController belowView:(UIView *)bottomView {
    _menuManagerController = menuManagerController;
    _bottomView = bottomView;
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:_menuManagerController.view];
    
    // Adding the chat action
    if(_pelmelLogo==nil) {

        _pelmelLogo = [[MenuAction alloc] initWithIcon:[UIImage imageNamed:@"logoMob"] pctWidth:0 pctHeight:1 action:^(PMLMenuManagerController *menuManagerController, MenuAction *menuAction) {
            PMLSnippetTableViewController *snippetController = (PMLSnippetTableViewController*)[_uiService instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
            
            [menuManagerController presentControllerSnippet:snippetController];
        }];
        _pelmelLogo.bottomMargin= 5;
        _pelmelLogo.pctWidthPosition=1;
        _pelmelLogo.rightMargin = 5;
    }
    [self setupMenuAction:_pelmelLogo];
    

    // Loader view
    [self configureLoaderAction];
    
    // Events view
//    [self configureEventsAction];
    
}
- (void)configureLoaderAction {
    // Building loader view
    if(_activityView == nil) {
        UIView *bgView = [[UIView alloc] init];
        bgView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
        bgView.layer.cornerRadius = 5;
        bgView.alpha = 0;
        bgView.bounds = CGRectMake(0, 0, kPMLLoaderSize, kPMLLoaderSize);
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityView.frame = CGRectMake(kPMLLoaderSize/2-_activityView.bounds.size.width/2, kPMLLoaderSize/2-_activityView.bounds
                                         .size.height/2, _activityView.bounds.size.width, _activityView.bounds.size.height);
        _activityView.hidesWhenStopped = NO;
        [bgView addSubview:_activityView];
        _activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        if(_loaderAction == nil) {
            _loaderAction = [[MenuAction alloc] initWithView:bgView pctWidth:0 pctHeight:0.25 action:nil];
            _loaderAction.leftMargin = 4;
        }
    }
    
    [self setupMenuAction:_loaderAction];
}
- (void)configureEventsAction {
    if(_eventsAction == nil) {
        _eventsActionView = [[UIView alloc] init];
        _eventsActionView.backgroundColor = [UIColor clearColor];
        _eventsActionView.layer.cornerRadius=5;
        _eventsActionView.layer.shadowOffset = CGSizeMake(2, 2);
        _eventsActionView.layer.shadowRadius = 2;
        _eventsActionView.bounds = CGRectMake(0, 0, 50, 50);
        _eventsActionView.layer.shadowPath = [[UIBezierPath bezierPathWithRect:_eventsActionView.layer.bounds] CGPath];
        _eventsActionView.clipsToBounds = NO;
        _eventsActionView.layer.shadowOpacity = 0.5;

        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"snpIconTicket"]];
        icon.contentMode = UIViewContentModeCenter;
        icon.frame = CGRectMake(0, 0, _eventsActionView.bounds.size.width, _eventsActionView.bounds.size.height);
        icon.backgroundColor =UIColorFromRGB(0xe9791e);
        icon.layer.cornerRadius = 5;
        icon.layer.masksToBounds=YES;
        icon.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_eventsActionView addSubview:icon];
        _eventsAction = [[MenuAction alloc] initWithView:_eventsActionView pctWidth:0 pctHeight:0.5 action:^(PMLMenuManagerController *menuManagerController, MenuAction *menuAction) {
            [_uiService presentSnippetFor:nil opened:YES];
        }];
        _eventsAction.leftMargin=4;
    }
    [self setupMenuAction:_eventsAction];
}
- (void)layoutMenuActions {
    for(MenuAction *action in _menuActions) {
        [self setupMenuAction:action];
    }
}
-(void)setupMenuAction:(MenuAction *)action {
    


    CGSize size = _menuManagerController.containerView.bounds.size;
    CGRect actionBounds = action.menuActionView.bounds;
    
    // Computing X-position
    float pctWidth, pctHeight,leftMargin,rightMargin;
    BOOL reverse = [[TogaytherService settingsService] leftHandedMode];
    pctWidth = reverse ? (1-action.pctWidthPosition) : action.pctWidthPosition;
    pctHeight = action.pctHeightPosition; //reverse ? (1-action.pctHeightPosition) : action.pctHeightPosition;
    leftMargin = reverse ? action.rightMargin : action.leftMargin;
    rightMargin = reverse ? action.leftMargin : action.rightMargin;
    
    float x = pctWidth*size.width-actionBounds.size.width/2+leftMargin;
    x = MIN(x,size.width-actionBounds.size.width-rightMargin);
    x = MAX(x,leftMargin);
    
    // Computing Y-position
    float y = pctHeight*size.height-actionBounds.size.height/2+action.topMargin;
    y = MIN(y,size.height-actionBounds.size.height-action.bottomMargin);
    y = MAX(y,action.topMargin);
//    NSLog(@"Menu action y=%d",(int)y);
    // Setting frame
    action.menuActionView.frame = CGRectMake(x, y, actionBounds.size.width, actionBounds.size.height);
    
    if(![_initializedActions containsObject:action]) {
        [_initializedActions addObject:action];
        [_actions addObject:action];
        // Adding to our list of menu views for global animation
        [_menuActions addObject:action];
        
        // Adding tap gesture
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTapped:)];
        
        // Tagging so that we know who is tapped
        action.menuActionView.tag = [_actions indexOfObject:action];
        [action.menuActionView addGestureRecognizer:tapRecognizer];
        action.menuActionView.userInteractionEnabled=YES;
        
        // Adding menu action view
        [_menuManagerController.containerView insertSubview:action.menuActionView belowSubview:_bottomView];
    }
    
}

- (void)removeMenuAction:(MenuAction *)menuAction {
    // Unregistering and preventing any further touch event
    [_initializedActions removeObject:menuAction.menuActionView];
    [_actions removeObject:menuAction];
    menuAction.menuActionView.userInteractionEnabled=NO;
    // Animating
    float alpha = menuAction.menuActionView.alpha;
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        menuAction.menuActionView.alpha=0;
    } completion:^(BOOL finished) {
        // Final removing
        [menuAction.menuActionView removeFromSuperview];
        menuAction.menuActionView.alpha = alpha;
    }];
}

- (NSArray *)menuActions {
    return _menuActions;
}

- (void)loadingStart {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    });
}
- (void)loadingEnd {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    });
}
-(void)actionTapped:(UIGestureRecognizer*)sender {
    MenuAction *action = [_actions objectAtIndex:sender.view.tag];
    if(action != nil) {
        MenuAction *action = [_menuActions objectAtIndex:sender.view.tag];

        UIView *actionView = action.menuActionView;
        if(_menuTouchBehavior != nil) {
            [_animator removeBehavior:_menuTouchBehavior];
        }
        // Resetting position / sizes
        CGPoint center = actionView.center;
//        actionView.bounds = CGRectMake(center.x-action.initialWidth/2, center.y-action.initialHeight/2, action.initialWidth, action.initialHeight);
        // Touch animation
//        _menuTouchBehavior = [[UITouchBehavior alloc] initWithTarget:actionView];
//        [_animator addBehavior:_menuTouchBehavior];
        [UIView animateWithDuration:0.1 animations:^{
            CGFloat width =1.1*action.initialWidth;
            CGFloat height=1.1*action.initialHeight;
            actionView.bounds = CGRectMake(center.x-width/2, center.y-height/2, width, height);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.7 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                actionView.bounds = CGRectMake(center.x-action.initialWidth/2, center.y-action.initialHeight/2, action.initialWidth, action.initialHeight);
            } completion:nil];
        }];
        // Executing action
        if(action.menuAction) {
            action.menuAction(_menuManagerController,action);
        }
    }
}
#pragma mark - PMLDataListener

- (void)willUpdatePlace:(Place *)place {
    [self loadingStart];
}
- (void)didUpdatePlace:(Place *)place {
    [self loadingEnd];
}
- (void)didLoadData:(ModelHolder *)modelHolder silent:(BOOL)isSilent {
    [self loadingEnd];
//    [_menuManagerController.mainNavBarView.searchTextField setText:nil];
}
-(void)willSendReportFor:(CALObject *)object {
    [self loadingStart];
}
- (void)didSendReportFor:(CALObject *)object {
    [self loadingEnd];
    NSString *title = NSLocalizedString(@"action.report.done.title",@"");
    NSString *message = NSLocalizedString(@"action.report.done",@"");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}
- (void)reportFailedWithMessage:(NSString *)message {
    [self loadingEnd];
    NSString *title = NSLocalizedString(@"action.report.done.title",@"");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}


@end
