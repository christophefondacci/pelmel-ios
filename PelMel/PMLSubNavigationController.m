//
//  PMLSubNavigationViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 03/08/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLSubNavigationController.h"
#import <objc/runtime.h>

@interface PMLSubNavigationController ()

@end

@implementation PMLSubNavigationController {
    NSMutableArray *_viewControllers;
    UIButton *_backButton;
    UIImageView *_gripView;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super init];
    if (self) {
        _viewControllers = [NSMutableArray arrayWithObject:rootViewController];
        rootViewController.subNavigationController = self;
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _backButton.frame = CGRectMake(9, 60, 35, 35);
    [_backButton setBackgroundImage:[UIImage imageNamed:@"btnSubBack"] forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(backTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // Adding snippet grip
    _gripView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"snpGripTop"]];
    CGRect frame = self.view.frame;
    CGRect gripFrame = _gripView.frame;
    _gripView.frame = CGRectMake(CGRectGetMidX(frame)-CGRectGetWidth(gripFrame)/2, -gripFrame.size.height+1, gripFrame.size.width, gripFrame.size.height);
    [self.view addSubview:_gripView];
    
    if(_viewControllers.count>0) {
        UIViewController *topController = [self topViewController];
        
        // Adding the view controller in our hierarchy
        [self addChildViewController:topController];
        topController.subNavigationController = self;
        topController.view.frame = self.view.bounds;
        [self.view insertSubview:topController.view belowSubview:_gripView];
        [topController didMoveToParentViewController:self];
    }
    
}
- (UIViewController*)topViewController {
    return [_viewControllers objectAtIndex:_viewControllers.count-1];
}
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    viewController.view.frame = self.view.bounds;
    [self switchToViewController:viewController fromViewController:[self topViewController] back:NO];
}
-(void)switchToViewController:(UIViewController*)toViewController fromViewController:(UIViewController*)fromViewController back:(BOOL)isBack {
    // Getting current controller
    CGRect currentFrame = fromViewController.view.frame;

    
    // Preparing to add child at the right side of current view
    [self addChildViewController:toViewController];
    if(!isBack) {
        [_viewControllers addObject:toViewController];
    } else {
        [_viewControllers removeObject:fromViewController];
    }
    CGRect nextFrame = CGRectOffset(currentFrame, isBack ? -currentFrame.size.width:currentFrame.size.width, 0);
    toViewController.view.frame = nextFrame;
    
    // Preparing to remove current
    [fromViewController willMoveToParentViewController:nil];
    [_backButton removeFromSuperview];
    if(_viewControllers.count>1) {
        [toViewController.view addSubview:_backButton];
    }
    
    // Transitioning
    toViewController.subNavigationController =self;
    [self transitionFromViewController:fromViewController toViewController:toViewController duration:0.5 options:UIViewAnimationOptionCurveEaseInOut /*| UIViewAnimationOptionTransitionCrossDissolve*/ animations:^{
        
        CGRect previousFrame = CGRectOffset(currentFrame, isBack ?currentFrame.size.width:-currentFrame.size.width, 0);
        
        // Assigning current frame to new controller and previous frame to current
        fromViewController.view.frame=previousFrame;
        toViewController.view.frame=currentFrame;
    } completion:^(BOOL finished) {
        [toViewController didMoveToParentViewController:self];
        [fromViewController removeFromParentViewController];
        
        // Subnavigation specifics
        fromViewController.subNavigationController = nil;
    }];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    if(_viewControllers.count>1) {
        // Getting last controller
        UIViewController *poppedController = [_viewControllers objectAtIndex:_viewControllers.count-2];
        UIViewController *topController = [self topViewController];
        
        [self switchToViewController:poppedController fromViewController:topController back:YES];
        
        return poppedController;
    } else {
        return nil;
    }

}

-(void)viewWillAppear:(BOOL)animated {
    UIViewController *child = [_viewControllers objectAtIndex:_viewControllers.count-1];
    child.view.frame = self.view.bounds;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Back action
- (void)backTapped:(id)sender {
    NSLog(@"Back");
    [self popViewControllerAnimated:YES];
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

@end

#pragma mark - PMLSubNavigationItem
static void *MySubNavigationControllerKey;
@implementation UIViewController (PMLSubNavigationItem)

-(PMLSubNavigationController *)subNavigationController {
    PMLSubNavigationController *parentController = objc_getAssociatedObject(self, &MySubNavigationControllerKey);
    // If we have it defined, we return it
    if(parentController!= nil) {
        return parentController;
    } else {
        // Otherwise, we pass the call to our parent navigation controller
        if(self.navigationController != nil) {
            return self.navigationController.subNavigationController;
        }
    }
    return nil;
}
-(void)setSubNavigationController:(PMLSubNavigationController *)subNavigationController {
    objc_setAssociatedObject(self, &MySubNavigationControllerKey, subNavigationController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end