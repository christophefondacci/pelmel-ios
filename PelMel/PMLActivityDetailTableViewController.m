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
#define kActivityPlaceLike      @"I_PLAC"
#define kActivityEventCreation  @"EVNT_CREATION"
#define kActivityEventAttend    @"I_EVNT"

@interface PMLActivityDetailTableViewController ()
@property (nonatomic,retain) NSArray *activities;
@property (nonatomic,retain) UIService *uiService;
@property (nonatomic) BOOL loading;
@end

@implementation PMLActivityDetailTableViewController {
    NSUserDefaults *_defaults;
}

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

    // Title (trying to get activityType-specific title, or falls back to default)
    NSString *localizedKey = [NSString stringWithFormat:@"activity.title.%@",self.activityStatistic.activityType];
    NSString *title = NSLocalizedString(localizedKey, localizedKey);
    if(![title hasPrefix:@"activity.title."]) {
        self.title = title;
    } else {
        self.title = NSLocalizedString(@"activity.title", @"activity.title");
    }
    
    // Auto-height config
    self.tableView.estimatedRowHeight = 52;
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        self.tableView.rowHeight = UITableViewAutomaticDimension;
    } else {
        if([self.activityStatistic.activityType hasPrefix:@"EVNT"] || [self.activityStatistic.activityType hasSuffix:@"EVNT"]) {
            self.tableView.rowHeight = 72;
        } else {
            self.tableView.rowHeight = 52;
        }

    }
    
    // Misc init
    _defaults = [NSUserDefaults standardUserDefaults];
    
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
    for(Activity *a in _activities) {
        [_defaults setObject:[NSNumber numberWithBool:YES] forKey:[self activitySeenKey:a]];
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [TogaytherService applyCommonLookAndFeel:self];
    self.navigationController.navigationBar.translucent=NO;

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
    cell.backgroundColor = BACKGROUND_COLOR;
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
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == kSectionActivities) {
        Activity *activity = [_activities objectAtIndex:indexPath.row];
        CALObject *sourceObject = [self activityObject:activity source:YES];
        CALObject *activityObject = [self activityObject:activity source:NO];
        
        CALObject *obj = activityObject !=nil ? activityObject : sourceObject;
        [self presentObject:obj];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [cell setSelected:NO animated:YES];
        [_defaults setObject:[NSNumber numberWithBool:YES] forKey:[self activitySeenKey:activity]];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];

    }
}


#pragma mark - Row setup
- (void)configureActivityCell:(PMLActivityDetailTableViewCell*)cell forRow:(NSInteger)row {
    Activity *activity = [_activities objectAtIndex:row];
    
    // Setting user and target object
    CALObject *sourceObject = [self activityObject:activity source:YES];
    CALObject *activityObject = [self activityObject:activity source:NO];
    
    // Left image configuration (rounded, border and image)
    cell.leftImage.layer.borderWidth=1;
    if([sourceObject.key hasPrefix:@"USER"]) {
        cell.leftImage.layer.cornerRadius = cell.leftImage.bounds.size.width/2;
    } else {
        cell.leftImage.layer.cornerRadius = 0;
    }
    cell.leftImage.layer.masksToBounds=YES;
    cell.leftImage.layer.borderColor = [[[TogaytherService uiService] colorForObject:sourceObject] CGColor];
    cell.leftImage.image = [CALImage getDefaultUserThumb];
    cell.leftActionCallback = ^{
        [_defaults setObject:[NSNumber numberWithBool:YES] forKey:[self activitySeenKey:activity]];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:kSectionActivities]] withRowAnimation:UITableViewRowAnimationNone];
        [self presentObject:sourceObject];
    };
    CALImage *image = [[TogaytherService imageService] imageOrPlaceholderFor:sourceObject allowAdditions:NO];
    [[TogaytherService imageService] load:image to:cell.leftImage thumb:YES];
    
    // Right image configuration
    cell.rightImage.layer.borderWidth=1;
    cell.rightImage.layer.borderColor = [[UIColor whiteColor] CGColor];
    cell.rightImage.image = [CALImage getDefaultThumb];
    cell.rightActionCallback = ^{
        [_defaults setObject:[NSNumber numberWithBool:YES] forKey:[self activitySeenKey:activity]];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:kSectionActivities]] withRowAnimation:UITableViewRowAnimationNone];
        [self presentObject:activityObject];
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
    

    
    NSString *text = nil;
    if(activity.activitiesCount.intValue == 0) {
        text = [NSString stringWithFormat:localizedTemplate,[DisplayHelper getName:sourceObject],[DisplayHelper getName:activityObject]];
    } else {
        if(activity.activitiesCount.intValue==1) {
            template = [template stringByAppendingString:@".singular"];
        }
        localizedTemplate = NSLocalizedString(template, template);
        NSString *countString = [NSString stringWithFormat:localizedTemplate,[DisplayHelper getName:sourceObject],activity.activitiesCount.intValue];
        text = countString;
    }
    
    // Define general attributes for the entire text
    NSDictionary *attribs = @{
                              NSForegroundColorAttributeName: cell.activityText.textColor,
                              NSFontAttributeName: [UIFont fontWithName:PML_FONT_DEFAULT size:cell.activityText.font.pointSize]
                              };
    // Configuring attributed text
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text
                                                            attributes:attribs];
    NSRange sourceRange = [text rangeOfString:[DisplayHelper getName:sourceObject]];
    NSRange targetRange = [text rangeOfString:[DisplayHelper getName:activityObject]];
    if(sourceRange.location != NSNotFound) {
        [attributedText setAttributes:@{NSFontAttributeName:[UIFont fontWithName:PML_FONT_DEFAULT_BOLD size:cell.activityText.font.pointSize]} range:sourceRange];
    }
    if(targetRange.location != NSNotFound) {
        [attributedText setAttributes:@{NSFontAttributeName:[UIFont fontWithName:PML_FONT_DEFAULT_BOLD size:cell.activityText.font.pointSize]} range:targetRange];
    }
    cell.activityText.attributedText = attributedText;
    
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

    // Badge configuration
    NSNumber *val = nil;
    if(activity.key!=nil) {
        val = [_defaults objectForKey:[self activitySeenKey:activity]];
        if(val == nil) {
            [cell showBadge:YES];
        } else {
            [cell showBadge:NO];
        }
    } else {
        [cell showBadge:NO];
    }
}
-(void)presentObject:(CALObject*)object {
    [_uiService presentSnippetFor:object opened:YES];
//    PMLSnippetTableViewController *snippetController = (PMLSnippetTableViewController*)[_uiService instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
//    snippetController.snippetItem = object;
//    [snippetController menuManager:self.parentMenuController snippetWillOpen:YES];
//    [self.parentMenuController.navigationController pushViewController:snippetController animated:YES];
}
/**
 * Provides the activity object
 * @param activity the Activity to extract object from
 * @param source YES to get the source, NO to get the target
 */
-(CALObject*)activityObject:(Activity*)activity source:(BOOL)source{
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
    } else if([self.activityStatistic.activityType isEqualToString:kActivityEventCreation]) {
        activityObject = activity.extraEvent;
    }
    return source ? sourceObject : activityObject;
}
-(NSString*)activitySeenKey:(Activity*)activity {
    return [NSString stringWithFormat:@"activity.seen.%@",activity.key];
}

- (void)configureLoadingCell:(PMLLoadingTableViewCell*)cell {
    cell.loadingLabel.text = NSLocalizedString(@"loading.activityStats", @"loading.activityStats");
    CGSize fitSize = [cell.loadingLabel sizeThatFits:CGSizeMake(self.view.bounds.size.width, cell.loadingLabel.bounds.size.height)];
    cell.loadingWidthConstraint.constant = fitSize.width;
}

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
//    [[TogaytherService uiService] popNavigationToMenuManager];
////    [self.parentMenuController dismissControllerMenu:YES];
//    [self.parentMenuController dismissControllerSnippet];
    [[TogaytherService uiService] presentSnippetFor:nil opened:NO];
}
@end
