//
//  MasterViewController.h
//  nativeTest
//
//  Created by Christophe Fondacci on 20/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ModelBased.h"
#import "DataService.h"
#import "UserService.h"
#import "SettingsService.h"
#import "EGORefreshTableHeaderView.h"

@class DetailViewController;



@interface MasterViewController : UITableViewController <PMLDataListener, PMLUserCallback, UISearchBarDelegate,SettingsListener> {
    
}

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) CALObject *parentObject;  // The optional parent object to fetch elements from
@property (weak, nonatomic) IBOutlet UIBarButtonItem *accountButton;
- (IBAction)switchPlaceEventsMode:(id)sender;

@property (weak, nonatomic) IBOutlet UISegmentedControl *placeEventsSwitch;

@end
