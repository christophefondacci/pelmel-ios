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
#import "PMLTextFieldTableViewCell.h"
#import "PMLEventDescriptionTableViewCell.h"

#define kSectionsCount 3
#define kSectionTitle 0
#define kSectionTime 1
//#define kSectionDescription 2
#define kSectionDays 2

#define kRowCountTitle 2
#define kRowTitle 0
#define kRowDescription 1

#define kRowCountTime 2
#define kRowStartTime 0
#define kRowEndTime 1

#define kRowCountDescription 0


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
    
    // Cells
    PMLTextFieldTableViewCell *_titleCell;
    PMLEventDescriptionTableViewCell *_descriptionCell;
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
        case kSectionTitle:
            // Only a title for hours different than opening hours
            return [self.calendar.calendarType isEqualToString:SPECIAL_TYPE_OPENING] ? 0 : kRowCountTitle;
        case kSectionTime:
            // Start / End time rows + optional time picker
            return kRowCountTime + (_pickerIndexPath != nil ? 1 : 0);
//        case kSectionDescription:
//            return kRowCountDescription;
        case kSectionDays:
            return kRowCountDays;
    }
    // Return the number of rows in the section.
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellId;
    switch (indexPath.section) {
        case kSectionTitle:
            if(indexPath.row==kRowTitle) {
                cellId = @"titleCell";
            } else {
                cellId = @"descCell";
            }
            break;
        case kSectionTime:
            if(_pickerIndexPath != nil && [indexPath isEqual:_pickerIndexPath]) {
                cellId = @"datePickerCell";
            } else {
                cellId = @"timeCell";
            }
            break;
//        case kSectionDescription:
//            cellId = @"descCell";
//            break;
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
        case kSectionTitle:
            if(indexPath.row == kRowTitle) {
                [self configureTitleCell:(PMLTextFieldTableViewCell*)cell];
            } else {
                [self configureDescriptionCell:(PMLEventDescriptionTableViewCell*)cell];
            }
            break;
        case kSectionTime:
            if(_pickerIndexPath != nil && [indexPath isEqual:_pickerIndexPath]) {
                [self configureDatePickerCell:(PMLDatePickerTableViewCell*)cell];
            } else {
                [self configureStartEndCell:(PMLDetailTableViewCell*)cell isStart:(indexPath.row == 0)];
            }
            break;
//        case kSectionDescription:
//
//            break;
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
        [_titleCell.textField resignFirstResponder];
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
    if(indexPath.section == kSectionTitle && indexPath.row == kRowDescription) {
        return 60;
    }
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch(section) {
        case kSectionDays:
        case kSectionTime:
            return 38;
        default:
            return 0;
    }

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
#pragma mark - Cell configuration
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
-(void)configureTitleCell:(PMLTextFieldTableViewCell*)cell {
    _titleCell = cell;
    cell.textField.text = self.calendar.name;
    cell.textField.returnKeyType = UIReturnKeyNext;
    cell.textField.delegate = self;
    cell.textField.attributedPlaceholder = 
        [[NSAttributedString alloc  ] initWithString: NSLocalizedString(@"calendar.title.placeholder",@"Name (optional)") attributes: @{NSForegroundColorAttributeName : UIColorFromRGB(0x939597)}];
    [cell.textField addTarget:self
                       action:@selector(titleDidChange:)
             forControlEvents:UIControlEventEditingChanged];
}
-(void)configureDescriptionCell:(PMLEventDescriptionTableViewCell*)cell {
    cell.descriptionTextView.text = self.calendar.miniDesc;
    if(self.calendar.miniDesc.length==0) {
        cell.placeholderLocalizedCode = @"calendar.desc.placeholder";
    } else {
        cell.placeholderLocalizedCode = nil;
    }
    _descriptionCell = cell;
}
#pragma mark - UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:kRowStartTime inSection:kSectionTime];
    
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    return YES;
}


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
-(void)titleDidChange:(UITextField*)textField {
    self.calendar.name = textField.text;
}
-(void)save:(id)sender {
    self.calendar.miniDesc = _descriptionCell.descriptionTextView.text;
    // Filling title
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
