//
//  RearMenuTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 11/02/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "FiltersViewController.h"
#import "TogaytherService.h"
#import "UITablePlaceTypeViewCell.h"
#import "PMLSectionTitleView.h"

#define kSectionsCount 2
#define kSectionHours 0
#define kSectionPlaceType 1
#define kRowCountSettings 2
#define kRowCountHours 3

#define kRowHoursOpening 0
#define kRowHoursSpecials 1
#define kRowHoursEvents 2

#define kCellIdPlaceType @"placeTypeCell"

@interface FiltersViewController ()

@end

@implementation FiltersViewController {
    NSArray *placeTypes;
    
    SettingsService *settingsService;
    
    PMLSectionTitleView *_sectionTitleTypeHeaderView;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [TogaytherService applyCommonLookAndFeel:self];
    self.tableView.backgroundColor = UIColorFromRGBAlpha(0x2d3134,0.7);
    self.tableView.separatorColor = [UIColor clearColor];
    //    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    settingsService = TogaytherService.settingsService;
    placeTypes = [settingsService listPlaceTypes];
    
    // Setting title
    self.view.backgroundColor =UIColorFromRGB(0x272a2e);
    self.tableView.backgroundColor =  UIColorFromRGB(0x272a2e);
    self.tableView.separatorColor = [UIColor clearColor];
    
    self.title =  NSLocalizedString(@"menu.filters.title",@"menu.filters.title");
    self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0x2d3134);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mnuIconClose"] style:UIBarButtonItemStylePlain target:self action:@selector(closeMenu:)];
    [self.navigationController.navigationBar setTitleTextAttributes: @{
                                                                       NSFontAttributeName:[UIFont fontWithName:PML_FONT_DEFAULT size:18],
                                                                       NSForegroundColorAttributeName:[UIColor whiteColor]}];
    // Preloading headers
    _sectionTitleTypeHeaderView = [[TogaytherService uiService] loadView:@"PMLSectionTitleView"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case kSectionHours:
            return kRowCountHours;
        case kSectionPlaceType:
            return placeTypes.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier;
    switch(indexPath.section) {
        case kSectionHours:
        case kSectionPlaceType:
            CellIdentifier = kCellIdPlaceType;
            break;
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.backgroundColor = [UIColor clearColor]; //FromRGBAlpha(0x666769, 0.8);
    switch(indexPath.section) {
        case kSectionHours:
            [self configureHoursCell:(UITablePlaceTypeViewCell*)cell indexPath:indexPath];
            break;
        case kSectionPlaceType:
            [self configurePlaceTypeCell:(UITablePlaceTypeViewCell*)cell indexPath:indexPath];
            break;
    }
    
    return cell;
}



- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch(section) {
        case kSectionPlaceType:
            _sectionTitleTypeHeaderView.titleLabel.text = NSLocalizedString(@"filters.placeType.header",@"filters.placeType.header");
            return _sectionTitleTypeHeaderView;
    }
    return nil;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kSectionHours:
            switch (indexPath.row) {
                case kRowHoursOpening:
                    [settingsService enableFilter:PMLFilterOpeningHours enablement:![settingsService isFilterEnabled:PMLFilterOpeningHours]];
                    break;
                case kRowHoursSpecials:
                    [settingsService enableFilter:PMLFilterHappyHours enablement:![settingsService isFilterEnabled:PMLFilterHappyHours]];
                    break;
                case kRowHoursEvents:
                    [settingsService enableFilter:PMLFilterEvents enablement:![settingsService isFilterEnabled:PMLFilterEvents]];
                    break;
                default:
                    break;
            }
            break;
        case kSectionPlaceType: {
            
            PlaceType *editedPlaceType  = [placeTypes objectAtIndex:indexPath.row];
            
            if(settingsService.allFiltersActive) {
                for(PlaceType *pt in [settingsService listPlaceTypes]) {
                    if([pt.code isEqualToString:editedPlaceType.code]) {
                        pt.visible = YES;
                    } else {
                        pt.visible = NO;
                    }
                    [settingsService storePlaceTypeFilter:pt];
                }
            } else {
                [editedPlaceType setVisible:![editedPlaceType visible]];
                [settingsService storePlaceTypeFilter:editedPlaceType];
            }
        }
            break;
    }
    // Triggers a refresh of the row
    [self.tableView reloadData];

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch(section) {
        case kSectionPlaceType:
            return _sectionTitleTypeHeaderView.frame.size.height;
    }
    return 0;
}
/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a story board-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 
 */

#pragma mark - Cell configuration
-(void) configureHoursCell:(UITablePlaceTypeViewCell*)cell indexPath:(NSIndexPath*)indexPath {
    switch (indexPath.row) {
        case kRowHoursOpening:
            cell.image.image = [UIImage imageNamed:@"ovvIconHours"];
            cell.label.text = NSLocalizedString(@"filters.hours.open", @"Open");
            cell.accessoryType = [settingsService isFilterEnabled:PMLFilterOpeningHours] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case kRowHoursSpecials:
            cell.image.image = [UIImage imageNamed:@"ovvIconSmallHappyhours"];
            cell.label.text = NSLocalizedString(@"filters.hours.happy", @"Happy hours");
            cell.accessoryType = [settingsService isFilterEnabled:PMLFilterHappyHours] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

            break;
        case kRowHoursEvents:
            cell.image.image = [UIImage imageNamed:@"snpIconEvent"];
            cell.label.text = NSLocalizedString(@"filters.hours.events", @"WithEvents");
            cell.accessoryType = [settingsService isFilterEnabled:PMLFilterEvents] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            

    }
}

- (void)configurePlaceTypeCell:(UITablePlaceTypeViewCell*)placeTypeCell indexPath:(NSIndexPath*)indexPath {
    // Getting place type to display
    PlaceType *placeType = [placeTypes objectAtIndex:indexPath.row];
    
    // Getting color to display
    UIColor *placeTypeColor = [TogaytherService.uiService colorForObject:placeType];
    
    // Filling cell info
    placeTypeCell.colorView.backgroundColor = placeTypeColor;
    placeTypeCell.label.text = placeType.label;
//    placeTypeCell.label.font = [UIFont fontWithName:PML_FONT_DEFAULT size:17];
    placeTypeCell.image.image = placeType.filterIcon;
    placeTypeCell.accessoryType = placeType.visible && !settingsService.allFiltersActive ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

#pragma mark - Action callback
-(void)closeMenu:(id)sender {
    [self.parentMenuController dismissControllerMenu:YES];
}

@end
