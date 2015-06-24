//
//  PMLPlacesTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 19/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLBannerEditorTableViewCell.h"

typedef enum {
    PMLSortStrategyDefault,
    PMLSortStrategyNearby,
    PMLSortStrategyName
} PMLSortStrategy;

typedef enum {
    PMLFilterAll,
    PMLFilterCheckin,
} PMLFilterStrategy;


@protocol PMLItemSelectionDelegate <NSObject>

-(BOOL)itemSelected:(CALObject*)item;

@end
@interface PMLItemSelectionTableViewController : UITableViewController

@property (nonatomic) PMLTargetType targetType;
@property (nonatomic,retain) id<PMLItemSelectionDelegate> delegate;
@property (nonatomic) PMLSortStrategy sortStrategy;
@property (nonatomic) PMLFilterStrategy filterStrategy;
@property (nonatomic) NSString *titleKey;
@end
