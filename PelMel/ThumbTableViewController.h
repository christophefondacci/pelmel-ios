//
//  ThumbTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 27/01/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbsPreviewView.h"

@class ThumbTableViewController;

@protocol PMLThumbsTableViewActionDelegate <NSObject>
- (void)thumbsTableView:(ThumbTableViewController*)thumbsTableView thumbTapped:(int)thumbIndex;
@end

@protocol ThumbsPreviewProvider <NSObject>
- (CALImage*)imageAtIndex:(NSInteger)index;
- (UIImage*)topLeftDecoratorForIndex:(NSInteger)index;
- (UIImage*)bottomRightDecoratorForIndex:(NSInteger)index;
- (NSArray*)items;
- (NSString*)titleAtIndex:(NSInteger)index;

// Optional
@optional
- (NSInteger)fontSize;
- (BOOL)rounded; // Whether or not images are rounded corners (defaults to YES)
- (BOOL)isSelected:(NSInteger)index;
- (UIColor*) colorFor:(NSInteger)index; // Color to use when displaying element (border color), defaults to white

// V1 and deprecated unless needed
- (NSString*)getMoreSegueId;
- (NSString*)getPreviewSegueIdForThumb:(int)thumbIndex;
- (void)prepareSegue:(UIViewController*)controller;
- (BOOL)showMoreButton;
- (NSString*)getLabel;
- (UIImage*)getIcon;
- (BOOL)shouldShow;
@end


@interface ThumbTableViewController : UITableViewController

@property (nonatomic) id<ThumbsPreviewProvider> thumbProvider;
@property (nonatomic) id<PMLThumbsTableViewActionDelegate> actionDelegate;
@property (nonatomic) NSNumber *size; // Square size of cells (defaults to 50)

@end
