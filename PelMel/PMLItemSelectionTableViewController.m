//
//  PMLPlacesTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 19/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLItemSelectionTableViewController.h"
#import "TogaytherService.h"

#define kPMLRowId @"placeOrEvent"

#define kSectionsCount 1
#define kSectionList 0

@interface PMLItemSelectionTableViewController ()

@property (nonatomic,retain) UIService *uiService;
@property (nonatomic,retain) NSArray *items;

@end

@implementation PMLItemSelectionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Service initialization
    self.uiService = [TogaytherService uiService];
    
    // Common look and feel
    [TogaytherService applyCommonLookAndFeel:self];
    self.tableView.backgroundColor = UIColorFromRGB(0x272a2e);
    self.tableView.opaque=YES;
    self.tableView.separatorColor = UIColorFromRGB(0x272a2e);

    // Registering rows
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLEventTableViewCell" bundle:nil] forCellReuseIdentifier:kPMLRowId];
    
    // Snapshotting content
    if(self.targetType == PMLTargetTypePlace) {
        self.items = [[[[TogaytherService dataService] modelHolder] places] copy];
    } else if(self.targetType == PMLTargetTypeEvent) {
        self.items = [[[[TogaytherService dataService] modelHolder] events] copy];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return kSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PMLEventTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPMLRowId forIndexPath:indexPath];
    cell.backgroundColor = UIColorFromRGB(0x272a2e);
    //
    CALObject *item = [self.items objectAtIndex:indexPath.row];
    switch(self.targetType) {
        case PMLTargetTypePlace:
            [_uiService configureRowPlace:cell place:(Place*)item];
            break;
        case PMLTargetTypeEvent:
            [_uiService configureRowOvEvents:cell forEvent:(Event*)item usingInfoProvider:[_uiService infoProviderFor:item]];
            break;
        default:
            break;
    }
    // Configure the cell...
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CALObject *item = [self.items objectAtIndex: indexPath.row];
    if(self.delegate != nil) {
        [self.delegate itemSelected:item];
        [self.navigationController popViewControllerAnimated:YES];
    }
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 144;
}

@end
