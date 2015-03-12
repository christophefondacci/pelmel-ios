//
//  PMLCalendarTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 17/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLCalendarTableViewController.h"
#import "PMLCalendarEditorTableViewController.h"
#import "TogaytherService.h"
#import "PMLImagedTitleTableViewCell.h"
#import "PMLAddTableViewCell.h"
#import "ProfileHeaderView.h"
#import "SpringTransitioningDelegate.h"
#import <MBProgressHUD.h>
#import "PMLMenuManagerController.h"
#import "UIPelmelTitleView.h"

#define kPMLSectionCount 4

#define kPMLSectionIntro 0
#define kPMLSectionOpening 1
#define kPMLSectionHappy 2
#define kPMLSectionTheme 3


@interface PMLCalendarTableViewController ()
@property (nonatomic, strong) SpringTransitioningDelegate *transitioningDelegate;
@end

@implementation PMLCalendarTableViewController {
    
    // Internal vars
    NSDictionary *_hoursTypeMap;
    int _editingSections;
    
    
    // Views
    ProfileHeaderView *_headerView;
    UIPelmelTitleView *_hoursTitleView;
    UIPelmelTitleView *_happyHoursTitleView;
    UIPelmelTitleView *_themeNightsTitleView;
    
    // Services
    ConversionService *_conversionService;
    ImageService *_imageService;
    UIService *_uiService;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [TogaytherService applyCommonLookAndFeel:self];
//    [self.navigationController setNavigationBarHidden:NO ];
    self.view.backgroundColor =UIColorFromRGB(0x272a2e);
    self.tableView.backgroundColor =  UIColorFromRGB(0x272a2e);
    self.tableView.separatorColor = [UIColor clearColor];
    
    // Services init
    _conversionService  = [TogaytherService getConversionService];
    _imageService       = [TogaytherService imageService];
    _uiService          = [TogaytherService uiService];
    
    // Loading views
    _headerView = (ProfileHeaderView*)[[TogaytherService uiService] loadView:@"ProfileHeader"];
    _hoursTitleView = (UIPelmelTitleView*)[[TogaytherService uiService] loadView:@"PMLHoursSectionTitleView"];
    _happyHoursTitleView = (UIPelmelTitleView*)[[TogaytherService uiService] loadView:@"PMLHoursSectionTitleView"];
    _themeNightsTitleView = (UIPelmelTitleView*)[[TogaytherService uiService] loadView:@"PMLHoursSectionTitleView"];
    
    // Registering external table view cells
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLAddModifyViewCell" bundle:nil] forCellReuseIdentifier:@"addModify"];
    
    // Sub transitions
    self.transitioningDelegate = [[SpringTransitioningDelegate alloc] initWithDelegate:self];
    _editingSections = 0;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
-(void)refresh {
    // Processing hours hashmap
    _hoursTypeMap = [_conversionService hashHoursByType:_place];
}
- (void)viewWillAppear:(BOOL)animated {
    [self refresh];
    [self.tableView reloadData];
}
- (void)viewWillDisappear:(BOOL)animated {
    // Forcing a reload of the place
    _place.hasOverviewData=NO;
    [[TogaytherService dataService] fetchOverviewData:_place];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kPMLSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *calType = [self calendarTypeFromSection:section];
    if(calType != nil) {
        return [[_hoursTypeMap objectForKey:calType] count]+1;
    }

    return 0;
}

- (BOOL)isAddRow:(NSIndexPath*)indexPath {
    NSString *calType = [self calendarTypeFromSection:indexPath.section];
    NSInteger count = [[_hoursTypeMap objectForKey:calType] count];
    return indexPath.row == count;
}
-(NSString*)rowIdAtIndexPath:(NSIndexPath*)indexPath {
    // Is it the addition row?
    NSString *rowId;
    BOOL isAddRow = [self isAddRow:indexPath];
    if(!isAddRow) {
        PMLCalendar *cal = [self calendarForIndexPath:indexPath];
        if([self isTitledCalendar:cal]) {
            rowId = @"titledHours";
        } else {
            rowId = @"hours";
        }
    } else {
        rowId = @"addNew";
    }
    return rowId;
}
- (BOOL)isTitledCalendar:(PMLCalendar*)cal {
    return ![cal.calendarType isEqualToString:SPECIAL_TYPE_OPENING] && cal.name != nil && cal.name.length>0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Is it the addition row?
    BOOL isAddRow = [self isAddRow:indexPath];
    NSString *reuseId = [self rowIdAtIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId forIndexPath:indexPath];
    
    // Configure the cell...
    cell.backgroundColor = UIColorFromRGB(0x272a2e);

    if(!isAddRow) {
        PMLCalendar *cal = [self calendarForIndexPath:indexPath];
        if(cal != nil) {
            NSString *calendarLabel = [_conversionService stringFromCalendar:cal ];
            
            PMLImagedTitleTableViewCell *titledCell = (PMLImagedTitleTableViewCell*)cell;
            if([self isTitledCalendar:cal]) {
                titledCell.titleLabel.text = cal.name;
                titledCell.subtitleLabel.text = calendarLabel;
            } else {
                titledCell.titleLabel.text = calendarLabel;
            }
            [titledCell.deleteButton addTarget:self action:@selector(removeHoursTapped:) forControlEvents:UIControlEventTouchUpInside];
            UIImage *icon = nil;
            switch(indexPath.section) {
                case kPMLSectionHappy:
                    icon = [UIImage imageNamed:@"ovvIconSmallHappyhours"];
                    break;
                default:
                    icon = [UIImage imageNamed:@"ovvIconHours"];
                    break;
            }
            titledCell.titleImage.image = icon;
        }
    }

    
    return cell;
}

-(PMLCalendar*)calendarForIndexPath:(NSIndexPath*)indexPath {
    PMLCalendar *cal = nil;
    NSString *calType = [self calendarTypeFromSection:indexPath.section];
    if(calType != nil) {
        // Getting the calendar from its index
        NSArray *calendars = [_hoursTypeMap objectForKey:calType];
        cal = [calendars objectAtIndex:indexPath.row];
    }
    // Returning what we found
    return cal;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch(section){
        case kPMLSectionIntro:
            [_headerView setNickname:self.place.title parentWidth:self.tableView.frame.size.width];
            _headerView.editButtonIcon.hidden=YES;
            _headerView.profileImageView.image= nil;
            if(self.place.mainImage) {
                [_imageService load:self.place.mainImage to:_headerView.profileImageView thumb:YES];
            }
            return _headerView;
        case kPMLSectionOpening:
            _hoursTitleView.titleLabel.text = NSLocalizedString(@"calendar.opening",@"Opening hours");
            return _hoursTitleView;
        case kPMLSectionHappy:
            _happyHoursTitleView.titleLabel.text = NSLocalizedString(@"calendar.happy",@"Happy hours");
            return _happyHoursTitleView;
        case kPMLSectionTheme:
            _themeNightsTitleView.titleLabel.text = NSLocalizedString(@"calendar.theme",@"Theme nights");
            return _themeNightsTitleView;
    }
    return [super tableView:tableView viewForHeaderInSection:section];
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(section == kPMLSectionIntro) {
        return _headerView.bounds.size.height;
    } else {
        return 38;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(![self isAddRow:indexPath]) {
        PMLCalendar *cal = [self calendarForIndexPath:indexPath];
        if([self isTitledCalendar:cal]) {
            return 68;
        }
    }
    return 50;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(![self isAddRow:indexPath]) {
        PMLCalendar *calendar = [self calendarForIndexPath:indexPath];
        [self presentCalendarEditorFor:calendar];
    } else {
        [self addTapped:indexPath.section];
    }
}
- (void)presentCalendarEditorFor:(PMLCalendar*)calendar {
    PMLCalendarEditorTableViewController *calendarController = (PMLCalendarEditorTableViewController*)[_uiService instantiateViewController:@"hoursEditor"];
    calendarController.calendar = calendar;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:calendarController];
    
    // Preparing transition
    self.transitioningDelegate.transitioningDirection = TransitioningDirectionDown;
    [self.transitioningDelegate presentViewController:navController];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return ( (1<<indexPath.section) & _editingSections) > 0 && indexPath.row>0;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

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

-(NSString*)calendarTypeFromSection:(NSInteger)section {
    NSString *type;
    switch(section) {
        case kPMLSectionOpening:
            type = SPECIAL_TYPE_OPENING;
            break;
        case kPMLSectionHappy:
            type = SPECIAL_TYPE_HAPPY;
            break;
        case kPMLSectionTheme:
            type = SPECIAL_TYPE_THEME;
            break;
    }
    return type;
}
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - PMLAddModifyDelegate
- (void)addTapped:(NSInteger)section {
    NSString *type = [self calendarTypeFromSection:section];
    PMLCalendar *calendar = [[PMLCalendar alloc] init];
    calendar.place = _place;
    calendar.calendarType = type;
    [self presentCalendarEditorFor:calendar];
}
- (void)removeHoursTapped:(UIButton*)source {
    CGPoint center= source.center;
    CGPoint rootViewPoint = [source.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    PMLCalendar *calendar = [self calendarForIndexPath:indexPath];
    if(calendar != nil) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeDeterminate;
        hud.labelText = NSLocalizedString(@"action.wait", @"Please wait");
        [[TogaytherService dataService] deleteCalendar:calendar callback:^(PMLCalendar *calendar) {
            [hud hide:YES];
            [_place.hours removeObject:calendar];
            [self refresh];
            // Delete the row from the data source
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } errorCallback:^(NSInteger errorCode, NSString *errorMessage) {
            [hud hide:YES];
            [_uiService alertError];
        }];
        
    }
}
- (void)modifyTapped:(PMLAddTableViewCell *)sourceCell {
    BOOL wasEditing = (_editingSections >0);
    _editingSections ^= 1 << (sourceCell.tag);
    // If we were already editing, we reset editing flag to FALSE to force a refresh
    if(wasEditing && _editingSections >0) {
        self.editing = NO;
    }
    [self setEditing:(_editingSections>0) animated:YES];
}
@end
