//
//  PMLThumbCollectionViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 03/03/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbTableViewController.h"
#import "PMLThumbsPreviewProvider.h"

@class PMLThumbCollectionViewController;
@protocol PMLThumbsCollectionViewActionDelegate <NSObject>
- (void)thumbsTableView:(PMLThumbCollectionViewController*)thumbsController thumbTapped:(int)thumbIndex forThumbType:(PMLThumbType)type;
@end

@interface PMLThumbCollectionViewController : UICollectionViewController <UICollectionViewDelegateFlowLayout>

@property (nonatomic) id<PMLThumbsPreviewProvider> thumbProvider;
@property (nonatomic) id<PMLThumbsCollectionViewActionDelegate> actionDelegate;
@property (nonatomic) NSNumber *size; // Square size of cells (defaults to 50)
@property (nonatomic) BOOL hasShowMore; // Limits the items to visible view and displays a "see all" last thumb

@end
