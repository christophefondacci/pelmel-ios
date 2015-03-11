////
////  PMLSubNavigationViewController.h
////  PelMel
////
////  Created by Christophe Fondacci on 03/08/14.
////  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
////
//
//#import <UIKit/UIKit.h>
//
//@protocol PMLSubNavigationDelegate <NSObject>
//
///**
// * Provides a container for the sub navigation back button
// */
//- (UIView*)subNavigationBackButtonContainer;
//
//@end
///**
// * This controller handles a mini navigation stack and a small back button for the snippet 
// * view. The interface matches UINavigationController for smooth migration.
// * This mini navigation only handles pop and push operations.
// */
//@interface PMLSubNavigationController : UIViewController
//
//@property (nonatomic,weak) id<PMLSubNavigationDelegate> delegate;
//
///*
// * Instantiates a sub navigation with the given root view controller
// */
//-(instancetype) initWithRootViewController: (UIViewController*)rootViewController;
//
///**
// * The current UIViewController being displayed
// */
//- (UIViewController*)topViewController;
//
///**
// * Pushes a new view controller on the stack.
// */
//- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
//
///**
// * Pops the previous view controller from the stack and dismiss the current one
// */
//- (UIViewController *)popViewControllerAnimated:(BOOL)animated; // Returns the popped controller.
//
///**
// * Provides the array of sub controllers, which might be different from childViewControllers as controllers
// * are removed from the hierarchy after transition
// */
//- (NSArray*)subControllers;
//@end
//
//
///**
// * This category allows direct access to the sub navigation controller from any of its children
// */
//@interface UIViewController (PMLSubNavigationItem)
//
///**
// * Provides the nearest PMLSubNavigationController
// */
//@property (atomic,retain) PMLSubNavigationController *subNavigationController;
//
//@end