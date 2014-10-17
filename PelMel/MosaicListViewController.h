//
//  MenListViewController.h
//  nativeTest
//
//  Created by Christophe Fondacci on 02/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Place.h"

@protocol MosaicObjectProvider
-(NSString *) getLabel;
-(BOOL)isOnline;
-(CALImage*)getImage;
-(CALObject*)getObject;
@end

@interface MosaicListViewController : UITableViewController

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong) NSString* viewTitle;
@property (strong, nonatomic) CALObject *parentObject;
@property (strong, nonatomic) NSArray* objects;
@end
