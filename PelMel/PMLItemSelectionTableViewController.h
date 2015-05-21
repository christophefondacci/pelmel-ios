//
//  PMLPlacesTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 19/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLBannerEditorTableViewCell.h"

@protocol PMLItemSelectionDelegate <NSObject>

-(void)itemSelected:(CALObject*)item;

@end
@interface PMLItemSelectionTableViewController : UITableViewController

@property (nonatomic) PMLTargetType targetType;
@property (nonatomic,retain) id<PMLItemSelectionDelegate> delegate;
@end
