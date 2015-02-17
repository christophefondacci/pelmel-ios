//
//  RearMenuTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 11/02/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "MainMenuTableViewController.h"
#import "TogaytherService.h"
#import "UITablePlaceTypeViewCell.h"
#import "PMLLikeStatistic.h"
#import "PMLSnippetLikesTableViewController.h"
#import "ProfileHeaderView.h"

#define kSectionsCount 1

#define kSectionSettings 0
#define kSectionPlaceType 1

#define kRowCountSettings 6

#define kRowSettingProfile 0
#define kRowSettingMessages 1
#define kRowSettingSettings 2
#define kRowSettingLikes 3
#define kRowSettingLikers 4
#define kRowSettingDisconnect 5

#define kCellIdPlaceType @"placeTypeCell"
#define kCellIdProfile @"profileTableCell"
#define kCellIdHD @"hdTableCell"

@interface MainMenuTableViewController ()

@end

@implementation MainMenuTableViewController {
    NSArray *placeTypes;
    
    SettingsService *_settingsService;
    MessageService *_messageService;
    UserService *_userService;
    UIService *_uiService;
    ImageService *_imageService;
    
    PMLLikeStatistic *_likeStat;
    ProfileHeaderView *_profileHeaderView;
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
    // Service initialization
    _settingsService = [TogaytherService settingsService];
    _messageService = [TogaytherService getMessageService];
    _userService = [TogaytherService userService];
    _imageService = [TogaytherService imageService];
    _uiService = [TogaytherService uiService];
    
    // Preparing header view
    _profileHeaderView = (ProfileHeaderView*)[_uiService loadView:@"ProfileHeader"];
    
    placeTypes = [_settingsService listPlaceTypes];

    // Setting title
    self.view.backgroundColor =UIColorFromRGB(0x272a2e);
    self.tableView.backgroundColor =  UIColorFromRGB(0x272a2e);
    self.tableView.separatorColor = [UIColor clearColor];
    
    self.title =  NSLocalizedString(@"menu.main.title",@"menu.main.title");
    self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0x2d3134);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mnuIconClose"] style:UIBarButtonItemStylePlain target:self action:@selector(closeMenu:)];
    [self.navigationController.navigationBar setTitleTextAttributes: @{
                                                                       NSFontAttributeName:[UIFont fontWithName:PML_FONT_DEFAULT size:18],
                                                                       NSForegroundColorAttributeName:[UIColor whiteColor]}];
    //NSLocalizedString(@"rearMenu.title", @"rearMenu.title");
//    self.tableView.backgroundColor = [UIColor colorWithRed:0.078 green:0.102 blue:0.184 alpha:1];
    
    

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:NO];
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
        case kSectionPlaceType:
            return placeTypes.count;
        case kSectionSettings:
            return kRowCountSettings;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier;
    switch(indexPath.section) {
        case kSectionPlaceType:
            CellIdentifier = kCellIdPlaceType;
            break;
        case kSectionSettings:
            switch(indexPath.row) {
                case kRowSettingProfile:
                    CellIdentifier = kCellIdProfile;
                    break;
                case kRowSettingSettings:
                    CellIdentifier = kCellIdHD;
                    break;
                case kRowSettingMessages:
                case kRowSettingLikes:
                case kRowSettingLikers:
                case kRowSettingDisconnect:
                    CellIdentifier = kCellIdHD;

                    
            }
            break;
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.backgroundColor = UIColorFromRGB(0x272a2e);
//    cell.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    switch(indexPath.section) {
//        case kSectionPlaceType: {
//            
//            // Getting place type to display
//            PlaceType *placeType = [placeTypes objectAtIndex:indexPath.row];
//            
//            // Getting current table cell
//            UITablePlaceTypeViewCell *placeTypeCell = (UITablePlaceTypeViewCell*)cell;
//            
//            // Getting color to display
//            UIColor *placeTypeColor = [TogaytherService.uiService colorForObject:placeType];
//            
//            // Filling cell info
//            placeTypeCell.colorView.backgroundColor = placeTypeColor;
//            placeTypeCell.label.text = placeType.label;
//            placeTypeCell.enablementSwitch.on = !placeType.filtered;
//            placeTypeCell.enablementSwitch.tag=indexPath.row;
//            [placeTypeCell.enablementSwitch addTarget:self action:@selector(switchedEnablement:) forControlEvents:UIControlEventTouchUpInside];
//        }
//            break;
        case kSectionSettings: {
            UITablePlaceTypeViewCell *placeTypeCell = (UITablePlaceTypeViewCell*)cell;
            switch(indexPath.row) {
                case kRowSettingSettings: {
                    placeTypeCell.label.text = NSLocalizedString(@"settings.settings","Settings");
                    placeTypeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    placeTypeCell.image.image = [UIImage imageNamed:@"mnuIconSettings"];
                    placeTypeCell.badgeLabel.hidden=YES;
                }
                    break;
                case kRowSettingMessages: {
                    placeTypeCell.label.text = NSLocalizedString(@"settings.messages","Messages");
                    placeTypeCell.image.image = [UIImage imageNamed:@"mnuIconMessage"];
                    placeTypeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    if(_messageService.unreadMessageCount>0) {
                        placeTypeCell.badgeLabel.hidden=NO;
                        placeTypeCell.badgeLabel.text = [NSString stringWithFormat:@"%d",_messageService.unreadMessageCount];
                    } else {
                        placeTypeCell.badgeLabel.hidden=YES;
                    }
                }
                    break;
                case kRowSettingProfile: {
                    placeTypeCell.label.text = NSLocalizedString(@"settings.account.cell", @"Edit my profile");
                    placeTypeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    placeTypeCell.image.image = [UIImage imageNamed:@"mnuIconProfile"];
                    placeTypeCell.badgeLabel.hidden=YES;
                }
                    break;
                case kRowSettingLikes: {
                    placeTypeCell.label.text = NSLocalizedString(@"settings.likes", @"I like");
                    placeTypeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    placeTypeCell.image.image = [UIImage imageNamed:@"mnuIconLikes"];
                    placeTypeCell.badgeLabel.hidden=YES;
                }
                    break;
                case kRowSettingLikers: {
                    placeTypeCell.label.text = NSLocalizedString(@"settings.likers", @"They like me");
                    placeTypeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    placeTypeCell.image.image = [UIImage imageNamed:@"mnuIconLikeBacks"];
                    placeTypeCell.badgeLabel.hidden=YES;
                }
                    break;
                case kRowSettingDisconnect: {
                    placeTypeCell.label.text = NSLocalizedString(@"disconnect", @"disconnect");
                    placeTypeCell.accessoryType = UITableViewCellAccessoryNone;
                    placeTypeCell.image.image = [UIImage imageNamed:@"mnuIconDisconnect"];
                    placeTypeCell.badgeLabel.hidden=YES;
                }
                    break;
            }
            placeTypeCell.label.font = [UIFont fontWithName:PML_FONT_DEFAULT size:13];
            break;
        }
    }
    // Configure the cell...
    
    return cell;
}
//
//- (IBAction)switchedEnablement:(id)sender {
//    UISwitch *s = (UISwitch *)sender;
//    NSInteger index = [s tag];
//    
//    PlaceType *editedPlaceType  = [placeTypes objectAtIndex:index];
//    [editedPlaceType setFiltered:![editedPlaceType filtered]];
//    [settingsService storePlaceTypeFilter:editedPlaceType];
//}

//- (IBAction)switchedHD:(id)sender {
//    UISwitch *s = (UISwitch*)sender;
//    
//    [TogaytherService setHDMode:s.on];
//    s.on = [TogaytherService isRetina];
//}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        // Filling nickname and image of header view
        CurrentUser *user = [_userService getCurrentUser];
        [_profileHeaderView setNickname:user.pseudo parentWidth:self.tableView.frame.size.width];
        _profileHeaderView.editButton.hidden=YES;
        _profileHeaderView.profileImageView.image= nil;
        if(user.mainImage) {
            [_imageService load:user.mainImage to:_profileHeaderView.profileImageView thumb:YES];
        }
        return _profileHeaderView;
    }
    return nil;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(section==0) {
        return _profileHeaderView.bounds.size.height;
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section) {
        case kSectionPlaceType:
            return NSLocalizedString(@"rearMenu.placeType.header",@"rearMenu.placeType.header");
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kSectionSettings:
            switch(indexPath.row) {
                case kRowSettingSettings:
//                    [TogaytherService setHDMode:![TogaytherService isRetina]];
//                    [self tableView:tableView cellForRowAtIndexPath:indexPath];
                    [self performSegueWithIdentifier:@"settings" sender:self];
                    break;
                case kRowSettingMessages:
                    [self performSegueWithIdentifier:@"directMsg" sender:self];
                    break;
                case kRowSettingProfile: {
                    UIViewController *accountController = [[TogaytherService uiService] instantiateViewController:SB_ID_MYACCOUNT];
                    [self.parentMenuController.navigationController pushViewController:accountController animated:YES];
                }
                    break;
                case kRowSettingLikes:
                    [self performSegueWithIdentifier:@"likes" sender:self];
                    break;
                case kRowSettingLikers:
                    [self performSegueWithIdentifier:@"likers" sender:self];
                    break;
                case kRowSettingDisconnect:
                    // Disconnecting
                    [_userService disconnect];
//                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        // Dismissing this view and immediately
                        UIViewController *controller = [TogaytherService.uiService instantiateViewController:SB_LOGIN_CONTROLLER];
                        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
                        [self.parentMenuController.navigationController presentViewController:navController animated:YES completion:nil];

//                    });
                    break;
            }
    }
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

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    if([segue.identifier isEqualToString:@"likes"] || [segue.identifier isEqualToString:@"likers"]) {
        if(_likeStat != nil) {
            [self configureSegue:segue stat:_likeStat];
        } else {
            [_userService likeStatistics:^(id obj) {
                _likeStat = (PMLLikeStatistic*)obj;
                [self configureSegue:segue stat:_likeStat];
            } failure:^(id obj) {
                NSLog(@"Error getting like stats: %@",((NSError*)obj).localizedDescription);
            }];
        }
    }
}

-(void)configureSegue:(UIStoryboardSegue*)segue stat:(PMLLikeStatistic*)stat {
    PMLSnippetLikesTableViewController *controller = (PMLSnippetLikesTableViewController*)segue.destinationViewController;
    if([segue.identifier isEqualToString:@"likes"]) {
        controller.activities = stat.likeActivities;
    } else {
        controller.activities = stat.likerActivities;
    }
    controller.likeMode =[segue.identifier isEqualToString:@"likes"];
}

#pragma mark - Action callback
-(void)closeMenu:(id)sender {
    [self.parentMenuController dismissControllerMenu];
}
@end
