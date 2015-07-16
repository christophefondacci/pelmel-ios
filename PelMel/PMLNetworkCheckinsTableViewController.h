//
//  PMLNetworkCheckinsTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 15/07/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLThumbCollectionViewController.h"

@interface PMLNetworkCheckinsTableViewController : UITableViewController <PMLThumbsCollectionViewActionDelegate>
-(void)updateData;
@end
