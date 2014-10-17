//
//  SettingsTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 05/10/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UISwitch *pushSwitch;
@property (weak, nonatomic) IBOutlet UITableViewCell *pushCell;

@end
