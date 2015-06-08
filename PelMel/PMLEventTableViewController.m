//
//  PMLEventTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 22/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLEventTableViewController.h"
#import "PMLDatePickerTableViewCell.h"
#import "PMLDetailTableViewCell.h"
#import "PMLTextFieldTableViewCell.h"
#import "PMLEventDescriptionTableViewCell.h"
#import "TogaytherService.h"
#import <MBProgressHUD.h>

#define kPMLSectionsCount 3

#define kPMLSectionGeneral 0
#define kPMLSectionHours 1
#define kPMLSectionDescription 2

#define kPMLRowName 0

#define kPMLRowsCountHours 2
#define kPMLRowStart 0
#define kPMLRowEnd 1

#define kPMLRowsCountDescription 1
#define kPMLRowDescription 0

@interface PMLEventTableViewController ()

@end

@implementation PMLEventTableViewController {
    NSIndexPath *_datePickerIndexPath;
    
    ConversionService *_conversionService;
    
    PMLEventDescriptionTableViewCell *_descriptionCell;
    
    // Temporary edition data
    NSString *_editedName;
    NSDate *_editedStartDate;
    NSDate *_editedEndDate;
    NSString *_editedDescription;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Service initialization
    [TogaytherService applyCommonLookAndFeel:self];
    _conversionService = [TogaytherService getConversionService];
    
    self.tableView.backgroundColor = UIColorFromRGB(0x272a2e);
    self.tableView.opaque=YES;
    self.tableView.separatorColor = UIColorFromRGB(0x3e4146);
    self.tableView.separatorInset = UIEdgeInsetsZero;
    if([self.tableView respondsToSelector:@selector(layoutMargins)]){
        self.tableView.layoutMargins = UIEdgeInsetsZero;
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTapped:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveTapped:)];
    self.navigationItem.rightBarButtonItem.enabled = self.event.name!=nil && self.event.name.length>0;
    
    self.navigationController.view.layer.cornerRadius = 10;
    self.navigationController.view.layer.masksToBounds = YES;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewDidAppear:(BOOL)animated {
//    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:kPMLRowName inSection:kPMLSectionGeneral] animated:YES scrollPosition:UITableViewScrollPositionTop];
    PMLTextFieldTableViewCell *cell = (PMLTextFieldTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kPMLRowName inSection:kPMLSectionGeneral]];
    [cell.textField becomeFirstResponder];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kPMLSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section) {
        case kPMLSectionGeneral:
            return 1;
        case kPMLSectionHours:
            return kPMLRowsCountHours + (_datePickerIndexPath ? 1 : 0);
        case kPMLSectionDescription:
            return kPMLRowsCountDescription;
            
    }
    // Return the number of rows in the section.
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellId;
    switch(indexPath.section) {
        case kPMLSectionHours:
            if(_datePickerIndexPath != nil && [indexPath isEqual:_datePickerIndexPath]) {
                cellId = @"pickerCell";
            } else {
                cellId = @"dateCell";
            }
            break;
        case kPMLSectionGeneral:
            switch(indexPath.row) {
                case kPMLRowName:
                    cellId = @"nameCell";
            }
            break;
        case kPMLSectionDescription:
            cellId = @"descCell";
            break;
        default:
            return nil;
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    cell.backgroundColor = cell.contentView.backgroundColor;
    switch(indexPath.section) {
        case kPMLSectionGeneral:
            [self configureNameCell:(PMLTextFieldTableViewCell*)cell];
            break;
        case kPMLSectionHours:
            if(_datePickerIndexPath != nil && [indexPath isEqual:_datePickerIndexPath]) {
                PMLDatePickerTableViewCell *pickerCell = (PMLDatePickerTableViewCell*)cell;
                [self configureDatePicker:pickerCell forIndex:indexPath.row-1];
            } else {
                PMLDetailTableViewCell *detailCell = (PMLDetailTableViewCell*)cell;
                [self configureDateCell:detailCell forIndex:indexPath.row];
            }
            break;
        case kPMLSectionDescription:
            [self configureDescriptionCell:(PMLEventDescriptionTableViewCell*)cell];
            break;

    }
    // Configure the cell...
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == kPMLSectionDescription) {
        return 100;
    }
    if(_datePickerIndexPath != nil && [indexPath isEqual:_datePickerIndexPath]) {
        return 162;
    } else {
        return 44;
    }
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *editedPath = [NSIndexPath indexPathForRow:_datePickerIndexPath.row-1 inSection:_datePickerIndexPath.section];
    if([editedPath isEqual:indexPath]) {
        NSIndexPath *oldIndexPath = _datePickerIndexPath;
        _datePickerIndexPath = nil;
        [self.tableView deleteRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if(indexPath.section == kPMLSectionHours) {
        NSIndexPath *oldIndexPath = _datePickerIndexPath;
        NSInteger pickerRow = indexPath.row;
        if(oldIndexPath == nil || oldIndexPath.row>indexPath.row ) {
            pickerRow ++;
        }
        _datePickerIndexPath = [NSIndexPath indexPathForRow:pickerRow inSection:indexPath.section];

        // Resigning any keyboard
        PMLTextFieldTableViewCell *cell = (PMLTextFieldTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kPMLRowName inSection:kPMLSectionGeneral]];
        [cell.textField resignFirstResponder];
        
        // Inserting picker
        // Deleting any previous picker
        [self.tableView beginUpdates];
        if(oldIndexPath) {
            [self.tableView deleteRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [self.tableView insertRowsAtIndexPaths:@[_datePickerIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    } else if(indexPath.section == kPMLSectionGeneral && indexPath.row == kPMLRowName) {
        PMLTextFieldTableViewCell *cell = (PMLTextFieldTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell.textField becomeFirstResponder];
    }
}
#pragma mark - Row configuration
-(void)configureNameCell:(PMLTextFieldTableViewCell*)cell {
    cell.textField.attributedPlaceholder =
    [[NSAttributedString alloc  ] initWithString: NSLocalizedString(@"events.new.placeholder",@"Event Name") attributes: @{NSForegroundColorAttributeName : UIColorFromRGB(0x939597)}];
    cell.textField.delegate=self;
    [cell.textField addTarget:self
                  action:@selector(textChanged:)
        forControlEvents:UIControlEventEditingChanged];
    cell.textField.text = _editedName;
}
-(void)configureDateCell:(PMLDetailTableViewCell*)detailCell forIndex:(NSInteger)row {
    if(row == 0) {
        detailCell.detailIntroLabel.text = NSLocalizedString(@"calendar.start", @"Start");
//        detailCell.detailValueLabel.text = [_conversionService eventDateLabel:self.event isStart:YES];
        detailCell.detailValueLabel.text = [_conversionService stringForEventDate:_editedStartDate timeOnly:NO timezoneId:nil];

    } else {
        detailCell.detailIntroLabel.text = NSLocalizedString(@"calendar.end", @"End");
//        detailCell.detailValueLabel.text = [_conversionService eventDateLabel:self.event isStart:NO];
        detailCell.detailValueLabel.text = [_conversionService stringForEventDate:_editedEndDate timeOnly:[_editedEndDate timeIntervalSinceDate:_editedStartDate]< 86400 timezoneId:nil];
    }

}
-(void)configureDatePicker:(PMLDatePickerTableViewCell*)datePickerCell forIndex:(NSInteger)row {
    datePickerCell.datePicker.tag = row;
    [datePickerCell.datePicker removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
    [datePickerCell.datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
    if(row == 0) {
        [datePickerCell.datePicker setDate:_editedStartDate];
    } else {
        [datePickerCell.datePicker setDate:_editedEndDate];
    }
}
-(void)configureDescriptionCell:(PMLEventDescriptionTableViewCell*)cell {
    cell.descriptionTextView.text = _editedDescription;
    if(self.event.miniDesc.length==0) {
        cell.placeholderLocalizedCode = @"calendar.desc.placeholder";
    } else {
        cell.placeholderLocalizedCode = nil;
    }
    _descriptionCell = cell;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Action callbacks
-(void) dateChanged:(UIDatePicker*)datePicker {
    if(datePicker.tag==0) {
        _editedStartDate = datePicker.date;
        
        NSMutableArray *indexPathToReload = [NSMutableArray new];
        [indexPathToReload addObject:[NSIndexPath indexPathForRow:0 inSection:kPMLSectionHours]];
        
        // Adjusting end date if before start date
        if([_editedEndDate timeIntervalSinceDate:datePicker.date]<0) {
            _editedEndDate = [datePicker.date dateByAddingTimeInterval:7200];
            [indexPathToReload addObject:[NSIndexPath indexPathForRow:2 inSection:kPMLSectionHours]];
        }
        [self.tableView reloadRowsAtIndexPaths:indexPathToReload withRowAnimation:UITableViewRowAnimationNone];
    } else {
        _editedEndDate = datePicker.date;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:kPMLSectionHours]] withRowAnimation:UITableViewRowAnimationNone];
    }
}
- (void)textChanged:(UITextField*)textField {
    _editedName = textField.text;
    self.navigationItem.rightBarButtonItem.enabled = _editedName!=nil && _editedName.length>0;
}
-(void)cancelTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)saveTapped:(id)sender {
    BOOL newEvent = self.event.key == nil;
    self.event.miniDesc = _descriptionCell.descriptionTextView.text;
    self.event.name = _editedName;
    self.event.startDate = _editedStartDate;
    self.event.endDate = _editedEndDate;
    
    if([self.event.endDate timeIntervalSinceDate:self.event.startDate]<0) {
        [[TogaytherService uiService] alertWithTitle:@"validation.errorTitle" text:@"validation.endDateError"];
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"action.wait", @"Please wait...");
    [[TogaytherService dataService] updateEvent:self.event callback:^(Event *event) {
        if(newEvent) {
            [event.place.events addObject:event];
        }
        [hud hide:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
        [[TogaytherService uiService] presentSnippetFor:event opened:YES];
    } errorCallback:^(NSInteger errorCode, NSString *errorMessage) {
        [hud hide:YES];
        [[TogaytherService uiService] alertError];
    }];
}
#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:kPMLRowStart inSection:kPMLSectionHours ];

    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    return YES;
}

- (void)setEvent:(Event *)event {
    _event = event;
    
    // Capturing variables for edition (so we don't alter original event before save)
    _editedName = event.name;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:event.place.timezoneId]];
    
    // Converting event start date to local event date
    NSString *startDate = [dateFormatter stringFromDate:event.startDate];
    NSString *endDate = [dateFormatter stringFromDate:event.endDate];
    
    // Converting back to a date
    [dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
    
    _editedStartDate = [dateFormatter dateFromString:startDate];
    _editedEndDate = [dateFormatter dateFromString:endDate];
    _editedDescription = event.miniDesc;
}
@end
