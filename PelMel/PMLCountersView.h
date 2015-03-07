//
//  PMLCountersView.h
//  PelMel
//
//  Created by Christophe Fondacci on 03/03/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PopupAction.h"
@class PMLPopupActionManager;

#define kPMLCounterIndexLike 0
#define kPMLCounterIndexCheckin 1
#define kPMLCounterIndexComment 2

// Contract of the datasource of a counters view
@protocol PMLCountersDatasource <NSObject>

//- (NSInteger)countersCount; // For future use

// Provides icon and label for the counter
//- (NSString*)counterImageNameAtIndex:(NSInteger)index;
- (NSString*)counterLabelAtIndex:(NSInteger)index;
- (BOOL)isCounterSelectedAtIndex:(NSInteger)index;
/**
 * Action to wire on the counter at this position. If no action should
 * be bound, return PMLActionTypeNoAction
 */
- (PMLActionType)counterActionAtIndex:(NSInteger)index;
- (PMLPopupActionManager*)actionManager;
@end

@interface PMLCountersView : UIView
@property (weak, nonatomic) IBOutlet UIView *likeContainerView;
@property (weak, nonatomic) IBOutlet UILabel *likeCounterLabel;
@property (weak, nonatomic) IBOutlet UILabel *likeTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *likeIcon;
@property (weak, nonatomic) IBOutlet UIView *checkinsContainerView;
@property (weak, nonatomic) IBOutlet UILabel *checkinCounterLabel;
@property (weak, nonatomic) IBOutlet UILabel *checkinTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *checkinIcon;
@property (weak, nonatomic) IBOutlet UIView *commentsContainerView;
@property (weak, nonatomic) IBOutlet UILabel *commentsCounterLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentsTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *commentsIcon;

@property (weak,nonatomic) NSObject<PMLCountersDatasource> *datasource;

// Refreshes the view by pulling information from the datasource
-(void)reloadData;
@end