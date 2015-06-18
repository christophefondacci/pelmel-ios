//
//  PMLActivityStatisticsTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 30/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLActivityStatisticsTableViewController.h"
#import "TogaytherService.h"
#import "PMLLoadingTableViewCell.h"
#import "PMLActivityStatTableViewCell.h"
#import "PMLActivityStatistic.h"
#import "PMLActivityDetailTableViewController.h"
#import "PMLPhotosCollectionViewController.h"
#import "PMLActivityPhotoProvider.h"

#define kSectionsCount 2
#define kSectionStats 0
#define kSectionLoading 1

#define kRowIdStat @"statCell"
#define kRowIdLoading @"loadingCell"

@interface PMLActivityStatisticsTableViewController ()
@property (nonatomic,retain) DataService *dataService;
@property (nonatomic,retain) MessageService *messageService;
@property (nonatomic,retain) ImageService *imageService;
@property (nonatomic,retain) UIService *uiService;
@property (nonatomic) long maxActivityId;
@property (nonatomic) BOOL loading;
@end

@implementation PMLActivityStatisticsTableViewController {
    NSUserDefaults *_userDefaults;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initializing services
    _dataService    = [TogaytherService dataService];
    _messageService = [TogaytherService getMessageService];
    _imageService   = [TogaytherService imageService];
    _uiService      = [TogaytherService uiService];
    _userDefaults   = [NSUserDefaults standardUserDefaults];
    _loading=YES;
    
    // Skinning
    [TogaytherService applyCommonLookAndFeel:self];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mnuIconClose"] style:UIBarButtonItemStylePlain target:self action:@selector(closeMenu:)];
    self.tableView.backgroundColor = UIColorFromRGB(0x272a2e);
    self.tableView.opaque=YES;
    self.tableView.separatorColor = UIColorFromRGB(0x272a2e);
    self.title = NSLocalizedString(@"activity.title", @"Activity");
    // Querying nearby activity
    [_messageService getNearbyActivitiesStats:self];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (void)viewWillAppear:(BOOL)animated {
    self.tableView.estimatedRowHeight = 52;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView reloadData];
}
- (void)viewWillDisappear:(BOOL)animated {
    [_messageService clearNewActivities];
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
        case kSectionStats:
            return MAX(_dataService.modelHolder.activityStats.count,_loading ? 0 : 1);
        case kSectionLoading:
            return _loading ? 1 : 0;
    }
    // Return the number of rows in the section.
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(indexPath.section == kSectionStats ? kRowIdStat : kRowIdLoading) forIndexPath:indexPath];
    cell.backgroundColor = BACKGROUND_COLOR;
    switch(indexPath.section) {
        case kSectionLoading:
            [self configureLoadingRow:(PMLLoadingTableViewCell*)cell];
            break;
        case kSectionStats:
            [self configureRowStats:(PMLActivityStatTableViewCell*)cell forRow:indexPath.row];
            break;
            
    }
    
    return cell;
}

- (void)configureLoadingRow:(PMLLoadingTableViewCell*)cell {
    cell.loadingLabel.text = NSLocalizedString(@"loading.activityStats", @"loading.activityStats");
    CGSize fitSize = [cell.loadingLabel sizeThatFits:CGSizeMake(self.view.bounds.size.width, cell.loadingLabel.bounds.size.height)];
    cell.loadingWidthConstraint.constant = fitSize.width;
}

- (void)configureRowStats:(PMLActivityStatTableViewCell*)cell forRow:(NSInteger)row {
    if(_dataService.modelHolder.activityStats.count == 0) {
        cell.activityTitle.text = NSLocalizedString(@"activity.noactivity", @"activity.noactivity");
        cell.activityImageBackground.hidden=NO;
        cell.accessoryType = UITableViewCellAccessoryNone;
        [_imageService load:[[[TogaytherService userService] getCurrentUser] mainImage] to:cell.activityImage thumb:YES];
    } else {
    
        PMLActivityStatistic *stat = [_dataService.modelHolder.activityStats objectAtIndex:row];
        NSString *locKey = [NSString stringWithFormat:@"activity.%@",stat.activityType];
        cell.activityTitle.text = [_uiService localizedString:locKey forCount:stat.totalCount];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        // Displaying background photo frames "stack" only when multiple images
        if(stat.totalCount<=1) {
            cell.activityImageBackground.hidden=YES;
        } else {
            cell.activityImageBackground.hidden=NO;
        }
        cell.activityImage.image = [[CALImage defaultNoPhotoCalImage] thumbImage];
        [_imageService load:stat.statImage to:cell.activityImage thumb:YES];
        
        self.maxActivityId = MAX(stat.maxActivityId.longValue, self.maxActivityId);
        
        // Badging
        NSNumber *number = [_userDefaults objectForKey:[self activityStatKey:stat]];
        if(number == nil || number.longValue < stat.maxActivityId.longValue ) {
            [cell showBadge:YES];
        } else {
            [cell showBadge:NO];
        }
        
    }
    CGSize fitSize = [cell.activityTitle sizeThatFits:CGSizeMake(self.view.bounds.size.width-cell.activityLeftMarginConstraint.constant-33, MAXFLOAT)];
    cell.activityHeightConstraint.constant=fitSize.height;

//    cell.titleLabel.text = stat
}
-(NSString*)activityStatKey:(PMLActivityStatistic*)activityStat {
    return [NSString stringWithFormat:@"activity.stat.seen.%@",activityStat.activityType];
}
-(void)removeBadgeFrom:(UIView*)view {
    MKNumberBadgeView *badgeView = [self badgeViewFor:view];
    if(badgeView) {
        [badgeView removeFromSuperview];
    }
}
-(MKNumberBadgeView*)badgeViewFor:(UIView*)view {
    for(UIView *subview in view.subviews) {
        if([subview isKindOfClass:[MKNumberBadgeView class]]) {
            return (MKNumberBadgeView*)subview;
        }
    }
    return nil;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(_dataService.modelHolder.activityStats.count==0) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return ;
    }
    switch(indexPath.section) {
        case kSectionStats: {
            PMLActivityStatistic *stat = [_dataService.modelHolder.activityStats objectAtIndex:indexPath.row];
            UIViewController *controller = nil;
            if(![stat.activityType isEqualToString:@"MDIA_CREATION"]) {
                PMLActivityDetailTableViewController *activityDetailController = (PMLActivityDetailTableViewController*)[_uiService instantiateViewController:SB_ID_ACTIVITY_DETAILS];
                activityDetailController.activityStatistic = stat;
                controller = activityDetailController;
            } else {
                PMLPhotosCollectionViewController *photosController = (PMLPhotosCollectionViewController*)[_uiService instantiateViewController:SB_ID_PHOTOS_COLLECTION];
                PMLActivityPhotoProvider *provider = [[PMLActivityPhotoProvider alloc] initWithActivityType:stat.activityType];
                photosController.provider = provider;
                controller = photosController;
            }
//            [self.parentMenuController.navigationController pushViewController:controller animated:YES];
            [_uiService presentSnippet:controller opened:YES root:YES];
            [_userDefaults setObject:stat.maxActivityId forKey:[self activityStatKey:stat]];
            break;
        }
        default:
            break;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - ActivitiesCallback
- (void)activityStatsFetched:(NSArray *)activityStats {
    _loading = NO;
    [self.tableView reloadData];
}

- (void)activityStatsFetchFailed:(NSString *)errorMessage {
    [[TogaytherService uiService] alertError];
}
#pragma mark - Action callback
-(void)closeMenu:(id)sender {
    [self.parentMenuController dismissControllerMenu:YES];
}

@end
