//
//  PMLCalendarEditorTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 18/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLCalendarEditorTableViewController.h"
#import "TogaytherService.h"
#import "PMLTimePickerDataSource.h"
#import "PMLPickerTableViewCell.h"
#import "PMLDetailTableViewCell.h"
#import <MBProgressHUD.h>
#import "UIPelmelTitleView.h"
#import "PMLDatePickerTableViewCell.h"

#define kSectionsCount 2
#define kSectionTime 0
#define kSectionDays 1

#define kRowCountTime 2
#define kRowStartTime 0
#define kRowEndTime 1

#define kRowCountDays 7

@interface PMLCalendarEditorTableViewController ()

@end

@implementation PMLCalendarEditorTableViewController {
    
    // Services
    ConversionService *_conversionService;
    NSArray *_weekdays;
    
    // Header views
    UIPelmelTitleView *_scheduleHeaderView;
    UIPelmelTitleView *_daysHeaderView;
    
    // Time picker vars
    PMLTimePickerDataSource *_timePickerDatasource;
    NSIndexPath *_pickerIndexPath;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _conversionService = [TogaytherService getConversionService];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    _weekdays = [dateFormatter weekdaySymbols];
    [TogaytherService applyCommonLookAndFeel:self];
    self.view.backgroundColor =UIColorFromRGB(0x272a2e);
    self.tableView.backgroundColor =  UIColorFromRGB(0x272a2e);
    self.tableView.separatorColor = [UIColor clearColor];
    
    // Picker instantiation
    _timePickerDatasource = [[PMLTimePickerDataSource alloc ] initWithCallback:self];
    
    // Nav bar buttons
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
    
    
    // Header views
    _scheduleHeaderView = (UIPelmelTitleView*)[[TogaytherService uiService] loadView:@"PMLHoursSectionTitleView"];
    _daysHeaderView = (UIPelmelTitleView*)[[TogaytherService uiService] loadView:@"PMLHoursSectionTitleView"];

    self.navigationController.view.layer.cornerRadius = 10;
    self.navigationController.view.layer.masksToBounds = YES;
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
    switch(section) {
        case kSectionTime:
            return kRowCountTime + (_pickerIndexPath != nil ? 1 : 0);
        case kSectionDays:
            return kRowCountDays;
    }
    // Return the number of rows in the section.
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellId;
    switch (indexPath.section) {
        case kSectionTime:
            if(_pickerIndexPath != nil && [indexPath isEqual:_pickerIndexPath]) {
                cellId = @"datePickerCell";
            } else {
                cellId = @"timeCell";
            }
            break;
        case kSectionDays:
            cellId = @"dayCell";
            break;
        default:
            return nil;
    }

    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    cell.backgroundColor = UIColorFromRGB(0x272a2e);
    // Configure the cell...
    switch (indexPath.section) {
        case kSectionTime:
            if(_pickerIndexPath != nil && [indexPath isEqual:_pickerIndexPath]) {
                [self configureDatePickerCell:(PMLDatePickerTableViewCell*)cell];
            } else {
                [self configureStartEndCell:(PMLDetailTableViewCell*)cell isStart:(indexPath.row == 0)];
            }
            break;
        case kSectionDays: {
            PMLDetailTableViewCell *detailCell = (PMLDetailTableViewCell*)cell;
            detailCell.detailIntroLabel.text = [_weekdays objectAtIndex:(indexPath.row+1)%7];
            BOOL checked = [_calendar isEnabledFor:(indexPath.row+1)%7];
            
            detailCell.accessoryType =  checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
            break;
        default:
            break;
    }
    
    return cell;
}
- (void)configureDatePickerCell:(PMLDatePickerTableViewCell*)datePickerCell {
    [datePickerCell.datePicker removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
    [datePickerCell.datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
    
    NSDate *date = nil;
    NSDateComponents *components = [[NSDateComponents alloc] init];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    if(_pickerIndexPath.row == 1) {
        [components setHour:[_calendar startHour]];
        [components setMinute:[_calendar startMinute]];
    } else {
        [components setHour:[_calendar endHour]];
        [components setMinute:[_calendar endMinute]];
    }
    date = [gregorian dateFromComponents:components];
    [datePickerCell.datePicker setDate:date];

}
-(void)configureStartEndCell:(PMLDetailTableViewCell*)detailCell isStart:(BOOL)isStart {

    if(isStart) {
        detailCell.detailIntroLabel.text = NSLocalizedString(@"calendar.start", @"Start");
        detailCell.detailValueLabel.text = [_conversionService stringForHours:[_calendar startHour] minutes:[_calendar startMinute]];
    } else {
        detailCell.detailIntroLabel.text = NSLocalizedString(@"calendar.end", @"End");
        detailCell.detailValueLabel.text = [_conversionService stringForHours:[_calendar endHour] minutes:[_calendar endMinute]];
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *editedPath = [NSIndexPath indexPathForRow:_pickerIndexPath.row-1 inSection:_pickerIndexPath.section];
    if([editedPath isEqual:indexPath]) {
        NSIndexPath *oldIndexPath = _pickerIndexPath;
        _pickerIndexPath = nil;
        [self.tableView deleteRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if(indexPath.section == kSectionTime) {
        NSIndexPath *oldIndexPath = _pickerIndexPath;
        NSInteger pickerRow = indexPath.row;
        if(oldIndexPath == nil || oldIndexPath.row>indexPath.row ) {
            pickerRow ++;
        }
        _pickerIndexPath = [NSIndexPath indexPathForRow:pickerRow inSection:indexPath.section];
        
        if(indexPath.row == 0) {
            [_timePickerDatasource setHours:_calendar.startHour minutes:_calendar.startMinute forTag:0];
        } else {
            [_timePickerDatasource setHours:_calendar.endHour minutes:_calendar.endMinute forTag:1];
        }
        // Inserting picker
        // Deleting any previous picker
        [self.tableView beginUpdates];
        if(oldIndexPath) {
            [self.tableView deleteRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [self.tableView insertRowsAtIndexPaths:@[_pickerIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    } else if(indexPath.section == kSectionDays) {
        [_calendar toggleEnablementFor:(indexPath.row+1)%7];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }

}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath isEqual:_pickerIndexPath]) {
        return 162;
    }
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 38;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch (section) {
        case kSectionTime:
            _scheduleHeaderView.titleLabel.text = NSLocalizedString(@"calendar.time",@"Schedule");
            return _scheduleHeaderView;
        case kSectionDays:
            _daysHeaderView.titleLabel.text = NSLocalizedString(@"calendar.days", @"Days of week");
            return _daysHeaderView;
        default:
            break;
    }
    return nil;
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - PMLTimePickerCallback
- (void)timePickerChangedForTag:(NSInteger)tag hours:(NSInteger)hours minutes:(NSInteger)minutes {
    if(tag == 0) {
        [_calendar setStartHour:hours];
        [_calendar setStartMinute:minutes];
    } else {
        [_calendar setEndHour:hours];
        [_calendar setEndMinute:minutes];
    }
    
    
    if(_pickerIndexPath!=nil) {
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row-1 inSection:kSectionTime]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
}

#pragma mark - action callbacks
-(void)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)save:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"calendar.editor.saving", @"Saving...");
    hud.mode = MBProgressHUDModeIndeterminate;
    BOOL isNew = NO;
    if(_calendar.key == nil) {
        isNew = YES;
    }
    [[TogaytherService dataService] updateCalendar:self.calendar callback:^(PMLCalendar *calendar) {
        [hud hide:YES];
        if(isNew) {
            [calendar.place.hours addObject:calendar];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    } errorCallback:^(NSInteger errorCode, NSString *errorMessage) {
        [hud hide:YES];
        [[TogaytherService uiService] alertError];
    }];
}
-(void)dateChanged:(UIDatePicker*)datePicker {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    NSDateComponents *components = [gregorian components: (NSCalendarUnitHour | NSCalendarUnitMinute) fromDate: datePicker.date];
    NSMutableArray *indexPathToReload = [[NSMutableArray alloc] init];
    if(_pickerIndexPath.row == 1) {
        _calendar.startHour = components.hour;
        _calendar.startMinute = components.minute;
        [indexPathToReload addObject:[NSIndexPath indexPathForRow:0 inSection:kSectionTime]];
    } else {
        _calendar.endHour = components.hour;
        _calendar.endMinute = components.minute;
        [indexPathToReload addObject:[NSIndexPath indexPathForRow:1 inSection:kSectionTime]];
    }
    [self.tableView reloadRowsAtIndexPaths:indexPathToReload withRowAnimation:UITableViewRowAnimationNone];
}
@end
