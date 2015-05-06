//
//  PMLActivityDetailTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 04/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLActivityDetailTableViewController.h"
#import "TogaytherService.h"
#import "PMLActivityDetailTableViewCell.h"
#import "PMLLoadingTableViewCell.h"
#import "PMLSnippetTableViewController.h"
#import "DisplayHelper.h"

#define kSectionsCount 2

#define kSectionActivities 0
#define kSectionLoading 1

#define kRowIdActivity @"activityCell"
#define kRowIdLoading @"loadingCell"


#define kActivityUserRegister   @"R_USER"
#define kActivityUserLike       @"I_USER"
#define kActivityPlaceLike       @"I_PLAC"

@interface PMLActivityDetailTableViewController ()
@property (nonatomic,retain) NSArray *activities;
@property (nonatomic,retain) UIService *uiService;
@property (nonatomic) BOOL loading;
@end

@implementation PMLActivityDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Service init
    self.uiService = [TogaytherService uiService];
    
    // Appearance
    [TogaytherService applyCommonLookAndFeel:self];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mnuIconClose"] style:UIBarButtonItemStylePlain target:self action:@selector(closeMenu:)];
    self.tableView.backgroundColor = UIColorFromRGB(0x272a2e);
    self.tableView.opaque=YES;
    self.tableView.separatorColor = UIColorFromRGB(0x272a2e);
    self.title = NSLocalizedString(@"activity.title", @"Activity");
    _loading = YES;

    // Loading data 
    [[TogaytherService getMessageService] getNearbyActivitiesFor:_activityStatistic.activityType callback:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    // Registering max id
    [[TogaytherService getMessageService] registerMaxActivityId:_activityStatistic.maxActivityId];
}
- (void)viewWillAppear:(BOOL)animated {
    [TogaytherService applyCommonLookAndFeel:self];
    self.tableView.estimatedRowHeight = 52;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return kSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section) {
        case kSectionActivities:
            return _activities.count;
        case kSectionLoading:
            return _loading ? 1 : 0;
    }
    // Return the number of rows in the section.
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(indexPath.section == kSectionActivities ? kRowIdActivity : kRowIdLoading) forIndexPath:indexPath];
    
    switch(indexPath.section) {
        case kSectionActivities:
            [self configureActivityCell:(PMLActivityDetailTableViewCell*)cell forRow:indexPath.row];
            break;
        case kSectionLoading:
            [self configureLoadingCell:(PMLLoadingTableViewCell*)cell];
    }
    // Configure the cell...
    
    return cell;
}

- (void)configureActivityCell:(PMLActivityDetailTableViewCell*)cell forRow:(NSInteger)row {
    Activity *activity = [_activities objectAtIndex:row];
    
    // Setting user and target object
    CALObject *sourceObject = activity.user;
    CALObject *activityObject = activity.activityObject;
    if([self.activityStatistic.activityType isEqualToString:kActivityUserLike] || [self.activityStatistic.activityType isEqualToString:kActivityPlaceLike]) {
        if(activityObject != nil) {
            sourceObject = (User*)activityObject;
        }
        activityObject = nil;
    } else if([self.activityStatistic.activityType isEqualToString:kActivityUserRegister]) {
        activityObject = nil;
    }
    
    // Left image configuration (rounded, border and image)
    cell.leftImage.layer.borderWidth=1;
    cell.leftImage.layer.cornerRadius = cell.leftImage.bounds.size.width/2;
    cell.leftImage.layer.masksToBounds=YES;
    cell.leftImage.layer.borderColor = [[[TogaytherService uiService] colorForObject:sourceObject] CGColor];
    cell.leftImage.image = [CALImage getDefaultUserThumb];
    cell.leftActionCallback = ^{
        PMLSnippetTableViewController *snippetController = (PMLSnippetTableViewController*)[_uiService instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
        snippetController.snippetItem = sourceObject;
        [snippetController menuManager:self.parentMenuController snippetWillOpen:YES];
        [self.navigationController pushViewController:snippetController animated:YES];

    };
    CALImage *image = [[TogaytherService imageService] imageOrPlaceholderFor:sourceObject allowAdditions:NO];
    [[TogaytherService imageService] load:image to:cell.leftImage thumb:YES];
    
    // Right image configuration
    cell.rightImage.layer.borderWidth=1;
    cell.rightImage.layer.borderColor = [[UIColor whiteColor] CGColor];
    cell.rightImage.image = [CALImage getDefaultThumb];
    cell.rightActionCallback = ^{
        PMLSnippetTableViewController *snippetController = (PMLSnippetTableViewController*)[_uiService instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
        snippetController.snippetItem = activityObject;
        [snippetController menuManager:self.parentMenuController snippetWillOpen:YES];
        [self.parentMenuController.navigationController pushViewController:snippetController animated:YES];
    };
    CALImage *placeImage = [[TogaytherService imageService] imageOrPlaceholderFor:activityObject allowAdditions:NO];
    NSInteger additionalWidth = 0;
    if(activityObject == nil) {
        cell.rightImage.hidden=YES;
        cell.activityTextRightConstraint.constant=8;
        additionalWidth = 48;
    } else {
        cell.rightImage.hidden=NO;
        cell.activityTextRightConstraint.constant=56;
        [[TogaytherService imageService] load:placeImage to:cell.rightImage thumb:YES];
    }

    
    // Activity text
    NSString *template = [NSString stringWithFormat:@"activity.detail.%@",_activityStatistic.activityType];
    NSString *localizedTemplate = NSLocalizedString(template, template);
    if(activity.activitiesCount.intValue == 0) {
        cell.activityText.text = [NSString stringWithFormat:localizedTemplate,[DisplayHelper getName:sourceObject],[DisplayHelper getName:activityObject]];
    } else {
        if(activity.activitiesCount.intValue==1) {
            template = [template stringByAppendingString:@".singular"];
        }
        localizedTemplate = NSLocalizedString(template, template);
        NSString *countString = [NSString stringWithFormat:localizedTemplate,[DisplayHelper getName:sourceObject],activity.activitiesCount.intValue];
        cell.activityText.text = countString;
    }
//    [cell layoutIfNeeded];
    CGSize size = [cell.activityText sizeThatFits:CGSizeMake(cell.activityText.bounds.size.width+additionalWidth, MAXFLOAT)];
    cell.activityTextHeightConstraint.constant = MAX(cell.activityText.bounds.size.height,size.height);
    
    // Activity date
    if(activity.activityDate!=nil) {
        NSString * delay = [[TogaytherService uiService] delayStringFrom:activity.activityDate];
        cell.activityTimeLabel.text = delay;
    } else {
        cell.activityTimeLabel.text = nil;
    }

}

- (void)configureLoadingCell:(PMLLoadingTableViewCell*)cell {
    cell.loadingLabel.text = NSLocalizedString(@"loading.activityStats", @"loading.activityStats");
    CGSize fitSize = [cell.loadingLabel sizeThatFits:CGSizeMake(self.view.bounds.size.width, cell.loadingLabel.bounds.size.height)];
    cell.loadingWidthConstraint.constant = fitSize.width;
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
- (void)activityFetched:(NSArray *)activities {
    _activities = activities;
    _loading = NO;
    [self.tableView reloadData];
}
-(void)activityFetchFailed:(NSString *)errorMessage {
    _loading=NO;
    [self.tableView reloadData];
    [[TogaytherService uiService] alertError];
}
#pragma mark - Action callback
-(void)closeMenu:(id)sender {
    [self.parentMenuController.navigationController popToRootViewControllerAnimated:YES];
//    [self.parentMenuController dismissControllerMenu:YES];
    [self.parentMenuController dismissControllerSnippet];
}
@end
