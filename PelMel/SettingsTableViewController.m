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

@implementation SettingsTableViewController {
    MessageService *_messageService;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    _messageService = [TogaytherService getMessageService];
    
    self.title = NSLocalizedString(@"menu.settings.title",@"menu.settings.title");
    self.view.backgroundColor       = UIColorFromRGB(0x272a2e);
    self.tableView.backgroundColor  = UIColorFromRGB(0x272a2e);
    self.tableView.separatorColor   = [UIColor clearColor];
    [_pushSwitch addTarget:self action:@selector(pushSwitchTapped:) forControlEvents:UIControlEventTouchUpInside];
    _pushSwitch.on = [_messageService pushEnabled];
    
//    _pushCell.translatesAutoresizingMaskIntoConstraints = NO;
    _pushCell.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    _pushCell.backgroundColor = UIColorFromRGB(0x272a2e);
}

-(void)pushSwitchTapped:(UISwitch*)sender {
    [self setPushMode:_pushSwitch.on];
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
@end
