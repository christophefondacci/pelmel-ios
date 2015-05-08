//
//  PMLSnippetTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 30/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CALObject.h"
#import "KIImagePager.h"
#import "DataService.h"
#import "PMLThumbCollectionViewController.h"
#import "PMLMenuManagerController.h"
#import "PMLEventPlaceTabsTitleView.h"

@interface PMLSnippetTableViewController : UITableViewController <PMLDataListener, KIImagePagerDataSource, PMLThumbsCollectionViewActionDelegate, KIImagePagerDelegate, UITextFieldDelegate, UITextViewDelegate, PMLSnippetDelegate, PMLUserCallback,PMLEventPlaceTabsDelegate>

@property (weak,nonatomic) CALObject *snippetItem;

/**
 * Pushes a new snippet controller for the given CAL object and presents it
 */
-(void)pushSnippetFor:(CALObject*)item;
@end
