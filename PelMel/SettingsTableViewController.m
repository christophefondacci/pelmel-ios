//
//  SettingsTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 05/10/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "TogaytherService.h"

#define kSectionPush 0
#define kRowPushActive 0
#define kRowLeftHanded 1

@implementation SettingsTableViewController {
    MessageService *_messageService;
    SettingsService *_settingsService;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    _messageService = [TogaytherService getMessageService];
    _settingsService = [TogaytherService settingsService];
    
    // Navbar
    self.title = NSLocalizedString(@"menu.settings.title",@"menu.settings.title");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mnuIconClose"] style:UIBarButtonItemStylePlain target:self action:@selector(closeMenu:)];
    
    // Colors
    self.view.backgroundColor       = UIColorFromRGB(0x272a2e);
    self.tableView.backgroundColor  = UIColorFromRGB(0x272a2e);
    self.tableView.separatorColor   = [UIColor clearColor];
    
    // Actions
    [_pushSwitch addTarget:self action:@selector(pushSwitchTapped:) forControlEvents:UIControlEventTouchUpInside];
    _pushSwitch.on = [_messageService pushEnabled];
    _leftHandedSwitch.on = [_settingsService leftHandedMode];
    
//    _pushCell.translatesAutoresizingMaskIntoConstraints = NO;
//    _pushCell.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    _pushCell.backgroundColor = UIColorFromRGB(0x272a2e);
    _leftHandedCell.backgroundColor = UIColorFromRGB(0x272a2e);
    _leftHandedLabel.text = NSLocalizedString(@"settings.leftHanded", @"settings.leftHanded");
}

-(void)pushSwitchTapped:(UISwitch*)sender {
    [self setPushMode:_pushSwitch.on];
}
- (IBAction)leftHandedTapped:(id)sender {
    [_settingsService setLeftHandedMode:_leftHandedSwitch.on];
    [self.parentMenuController.menuManagerDelegate layoutMenuActions];
    [self.parentMenuController dismissControllerMenu];
}

-(void)setPushMode:(BOOL)active {
    if(active) {
        [_messageService handlePushNotificationProposition:^(BOOL pushActive) {
            [_pushSwitch setOn:pushActive animated:YES];
        }];
    } else {
        [_pushSwitch setOn:NO animated:YES];
        [_messageService setPushEnabled:NO];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kSectionPush:
            switch (indexPath.row) {
                case kRowPushActive:
                    [self setPushMode:!_pushSwitch.on];
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
}

-(void)closeMenu:(id)sender {
    [self.parentMenuController dismissControllerMenu];
}
@end
