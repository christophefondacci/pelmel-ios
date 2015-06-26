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

/**
 * Called when an item has been selected by the user
 * @param item the selected CALObject
 * @return YES if the controller can dismiss the view or else NO 
 */
-(BOOL)itemSelected:(CALObject*)item;
/**
 * Called to inform the delegate that the current list is empty.
 * The controller will dismiss the view after this method is called
 */
-(void)itemsListEmpty;

@end
@interface PMLItemSelectionTableViewController : UITableViewController

@property (nonatomic) PMLTargetType targetType;
@property (nonatomic,retain) id<PMLItemSelectionDelegate> delegate;
@property (nonatomic) PMLSortStrategy sortStrategy;
@property (nonatomic) PMLFilterStrategy filterStrategy;
@property (nonatomic) NSString *titleKey;

/**
 * Informs whether the controller, as configured at the time of calling, 
 * would display empty contents.
 */
-(BOOL)isEmpty;
@end
