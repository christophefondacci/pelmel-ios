//
//  PMLReportingTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 15/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLReportingTableViewController.h"
#import "PMLGraphTableViewCell.h"
#import "TogaytherService.h"
#import "PMLReportData.h"
#import "PMLReportRangeSelectorTableViewCell.h"
#import "JBLineChartFooterView.h"
#import "PMLButtonTableViewCell.h"
#import "PMLMessageAudienceTableViewController.h"
#import "SpringTransitioningDelegate.h"
#import <MBProgressHUD.h>

#define kSectionsCount 2
#define kSectionRangeSelector 0
#define kSectionGraphs 1

#define kRowMessageButton 0
#define kRowTabs 1

#define kRowIdRangeSelector @"rangeSelector"
#define kRowIdReport @"graphCell"
#define kRowIdButton @"button"

#define PML_REPORT_VIEWS @"VIEW"
#define PML_REPORT_LOCALIZATION @"LOCALIZATION_AUTO_STAT"
#define PML_REPORT_CHECKIN @"CHECKIN"
#define PML_REPORT_DEAL @"DEAL_USED"
#define PML_REPORT_CHECKOUT @"CHECKOUT"


CGFloat const kJBLineChartViewControllerChartPadding = 10.0f;
CGFloat const kJBLineChartViewControllerChartHeaderHeight = 75.0f;
CGFloat const kJBLineChartViewControllerChartHeaderPadding = 20.0f;
CGFloat const kJBLineChartViewControllerChartFooterHeight = 20.0f;


@interface PMLReportingTableViewController ()

@property (nonatomic,retain) NSArray *reportTypesOrder;
@property (nonatomic,retain) NSArray *sortedTypes;
@property (nonatomic,retain) NSMutableDictionary *typedReportData;
@property (nonatomic,retain) NSMutableDictionary *typedReportMaxY;
@property (nonatomic,retain) NSMutableDictionary *typedReportCells;
@property (nonatomic,retain) NSNumber *minY;
@property (nonatomic,retain) NSDateFormatter *dateFormatter;
@property (nonatomic,retain) NSNumberFormatter *numberFormatter;

@property (nonatomic,retain) SpringTransitioningDelegate *transitioningDelegate;
@end

@implementation PMLReportingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [TogaytherService applyCommonLookAndFeel:self];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.tableView.backgroundColor = BACKGROUND_COLOR;
    self.tableView.opaque=YES;
    self.tableView.separatorColor = BACKGROUND_COLOR;
    self.title = self.reportingPlace.title;
    // Definition of report types order for display
    _reportTypesOrder = @[PML_REPORT_VIEWS,PML_REPORT_LOCALIZATION,PML_REPORT_CHECKIN,PML_REPORT_DEAL,PML_REPORT_CHECKOUT];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm"];
    _numberFormatter = [[NSNumberFormatter alloc] init];
    _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    self.typedReportCells = [[NSMutableDictionary alloc] init];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLButtonTableViewCell" bundle:nil] forCellReuseIdentifier:kRowIdButton];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section) {
        case kSectionRangeSelector:
            return 2;
        case kSectionGraphs:
            return _typedReportData == nil ? 0 : [_sortedTypes count];
    }
    return 0;
}

-(NSString*)rowIdForIndexPath:(NSIndexPath*)indexPath {
    switch(indexPath.section) {
        case kSectionRangeSelector:
            switch(indexPath.row) {
                case kRowTabs:
                    return kRowIdRangeSelector;
                case kRowMessageButton:
                    return kRowIdButton;
            }
            break;
        case kSectionGraphs:
            return kRowIdReport;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[self rowIdForIndexPath:indexPath] forIndexPath:indexPath];
    cell.backgroundColor = BACKGROUND_COLOR;
    switch(indexPath.section) {
        case kSectionRangeSelector:
            switch(indexPath.row) {
                case kRowTabs:
                    [self configureRowRangeSelector:(PMLReportRangeSelectorTableViewCell*)cell];
                    break;
                case kRowMessageButton:
                    [self configureRowMessage:(PMLButtonTableViewCell*)cell];
            }
            break;
        case kSectionGraphs:
            [self configureRowGraph:(PMLGraphTableViewCell*)cell forRow:indexPath.row];
            break;
    }

    // Configure the cell...
    
    return cell;
}
-(void)configureRowRangeSelector:(PMLReportRangeSelectorTableViewCell*)cell {
    if(cell.delegate == nil) {
        cell.delegate = self;
        [cell selectRange:PMLReportRangeSemester];
    }
}
-(void)configureRowMessage:(PMLButtonTableViewCell*)cell {
    cell.buttonImageView.image = [UIImage imageNamed:@"icoClaimStats"];
    cell.buttonLabel.text = NSLocalizedString(@"reporting.messageButton", @"reporting.messageButton");
}
-(NSString*)typeForRow:(NSInteger)row {

    NSString *type = [self.sortedTypes objectAtIndex:row];
    return type;
}
-(void)configureRowGraph:(PMLGraphTableViewCell*)cell forRow:(NSInteger)row {
//    if(cell.chartView.delegate == nil) {
    [cell layoutIfNeeded];
    cell.chartView.tag = row;
    cell.chartView.delegate = self;
    cell.chartView.dataSource = self;
    [cell.chartView reloadData];
    
    // Updating title
    NSString *type = [self typeForRow:row];
    NSArray *typedData = [self.typedReportData objectForKey:type];
    [self.typedReportCells setObject:cell forKey:type];
    PMLReportData *firstPoint = [typedData objectAtIndex:0];
    PMLReportData *lastPoint = [typedData objectAtIndex:typedData.count-1];
    
    NSString *template = [NSString stringWithFormat:@"reporting.graphTitles.%@",type];
    cell.reportTitleLabel.text = NSLocalizedString(template, template);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd hh:mm"];
    JBLineChartFooterView *footerView = [[JBLineChartFooterView alloc] initWithFrame:CGRectMake(kJBLineChartViewControllerChartPadding, ceil(self.view.bounds.size.height * 0.5) - ceil(kJBLineChartViewControllerChartFooterHeight * 0.5), self.view.bounds.size.width - (kJBLineChartViewControllerChartPadding * 2), kJBLineChartViewControllerChartFooterHeight)];
    footerView.backgroundColor = [UIColor clearColor];
    footerView.leftLabel.text = [dateFormatter stringFromDate:firstPoint.date];
    footerView.leftLabel.textColor = [UIColor whiteColor];
    footerView.rightLabel.text = [dateFormatter stringFromDate:lastPoint.date];
    footerView.rightLabel.textColor = [UIColor whiteColor];
    
    cell.minYLabel.text = @"0";
    NSNumber *maxY = [self.typedReportMaxY objectForKey:type];
    cell.maxYLabel.text = [NSString stringWithFormat:@"%d",maxY.intValue];
    //        footerView.sectionCount = [[self largestLineData] count];
    cell.chartView.footerView = footerView;
    
//        [self.view addSubview:self.lineChartView];

//    }
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kSectionRangeSelector:
            switch(indexPath.row) {
                case kRowTabs:
                    return 44;
                case kRowMessageButton:
                    return 62;
            }

        case kSectionGraphs:
            return 200;
    }
    return 44;
}
-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == kSectionRangeSelector && indexPath.row == kRowMessageButton;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == kSectionRangeSelector && indexPath.row == kRowMessageButton) {
        PMLMessageAudienceTableViewController *msgController = (PMLMessageAudienceTableViewController*)[[TogaytherService uiService] instantiateViewController:SB_ID_MSG_AUDIENCE];
        msgController.place = self.reportingPlace;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:msgController];
        self.transitioningDelegate = [[SpringTransitioningDelegate alloc] initWithDelegate:self];
        self.transitioningDelegate.transitioningDirection = TransitioningDirectionDown;
        [self.transitioningDelegate presentViewController:navController];
        
    }
}

#pragma mark - JBLineChartViewDataSource
- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView {
    return 1;
}
- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex {
    NSString *type = [_sortedTypes objectAtIndex:lineChartView.tag];
    NSArray *typedData = [_typedReportData objectForKey:type];
    return typedData.count;
}
-(BOOL)lineChartView:(JBLineChartView *)lineChartView smoothLineAtLineIndex:(NSUInteger)lineIndex {
    return YES;
}
- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex {
    return [UIColor whiteColor];
}
- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSUInteger)lineIndex {
    return 1.0f;
}

#pragma mark - JBLineChartViewDelegate
- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex {
    NSString *type = [_sortedTypes objectAtIndex:lineChartView.tag];
    NSArray *typedData = [_typedReportData objectForKey:type];
    PMLReportData *data = [typedData objectAtIndex:horizontalIndex];
    return [data.count floatValue];
}

-(UIColor *)lineChartView:(JBLineChartView *)lineChartView fillColorForLineAtLineIndex:(NSUInteger)lineIndex {
    return UIColorFromRGBAlpha(0x3daf2c,1);
}

-(void)lineChartView:(JBLineChartView *)lineChartView didSelectLineAtIndex:(NSUInteger)lineIndex horizontalIndex:(NSUInteger)horizontalIndex touchPoint:(CGPoint)touchPoint {
    NSString *type = [_sortedTypes objectAtIndex:lineChartView.tag];
    NSArray *typedData = [_typedReportData objectForKey:type];
    PMLReportData *data = [typedData objectAtIndex:horizontalIndex];
    PMLGraphTableViewCell *cell = [self.typedReportCells objectForKey:type];
    cell.selectionView.hidden = NO;
    cell.selectionDateLabel.text = [_dateFormatter stringFromDate:data.date];
    cell.selectionDateLabel.hidden = NO;
    cell.selectionValueLabel.text = [data.count stringValue];
    cell.selectionValueLabel.hidden=NO;
    if(touchPoint.x>self.view.bounds.size.width/2) {
        cell.selectionLeadingConstraint.constant = touchPoint.x +lineChartView.frame.origin.x- 30 - cell.selectionView.bounds.size.width;
        cell.selectionTopConstraint.constant = touchPoint.y+lineChartView.frame.origin.y-cell.selectionView.bounds.size.height - 30;
    } else {
        cell.selectionLeadingConstraint.constant = touchPoint.x +lineChartView.frame.origin.x+ 30;
        cell.selectionTopConstraint.constant = touchPoint.y+lineChartView.frame.origin.y-cell.selectionView.bounds.size.height - 30;
    }
}
- (void)didDeselectLineInLineChartView:(JBLineChartView *)lineChartView {
    NSString *type = [_sortedTypes objectAtIndex:lineChartView.tag];
    PMLGraphTableViewCell *cell = [self.typedReportCells objectForKey:type];
    cell.selectionView.hidden = YES;
}
#pragma mark - PMLReportRangeSelector 
- (void)didSelectRange:(PMLReportRange)range {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"reporting.loading", @"reporting.loading");
    [[TogaytherService dataService] fetchReportFor:self.reportingPlace timeRange:range onSuccess:^(NSArray *reportDataList) {
        self.minY = @0;
        self.typedReportData = [[NSMutableDictionary alloc] init];
        self.typedReportMaxY = [[NSMutableDictionary alloc] init];
        for(PMLReportData *data in reportDataList) {
            // Appending typed data to map
            NSMutableArray *typedData = [self.typedReportData objectForKey:data.type];
            NSNumber *maxY = [self.typedReportMaxY objectForKey:data.type];
            if(maxY == nil) {
                maxY = @0;
            }
            if(typedData == nil) {
                typedData = [[NSMutableArray alloc] init];
                [self.typedReportData setObject:typedData forKey:data.type];
            }
            [typedData addObject:data];
            // Handling max Y for scale
            if(data.count.longValue>maxY.longValue) {
                maxY = [NSNumber numberWithInt:data.count.intValue];
                [self.typedReportMaxY setObject:maxY forKey:data.type];
            }
        }
        
        _sortedTypes = [self.typedReportData.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSInteger obj1Index = [self.reportTypesOrder indexOfObject:obj1];
            NSInteger obj2Index = [self.reportTypesOrder indexOfObject:obj2];
            if(obj1Index<obj2Index) {
                return NSOrderedAscending;
            } else if(obj1Index>obj2Index) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        }];
        
        [self.tableView reloadData];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    } onFailure:^(NSInteger errorCode, NSString *errorMessage) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [[TogaytherService uiService] alertWithTitle:@"Error" text:@"Error fetching report data or you are not authorized to acces this data"];
    }];
}
@end
