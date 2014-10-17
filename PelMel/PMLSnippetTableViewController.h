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
#import "ThumbTableViewController.h"

@interface PMLSnippetTableViewController : UITableViewController <PMLDataListener, PMLThumbsTableViewActionDelegate, KIImagePagerDataSource, KIImagePagerDelegate, UITextFieldDelegate, UITextViewDelegate>

@property (weak,nonatomic) CALObject *snippetItem;

@end
