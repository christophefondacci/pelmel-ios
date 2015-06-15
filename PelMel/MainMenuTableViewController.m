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
#import "PMLMenuManagerController.h"
#import "ProfileHeaderView.h"
#import "UIPelmelTitleView.h"
#import "PMLMessageTableViewController.h"
#import "FiltersViewController.h"

#define kSectionsCount 3

#define kSectionHeading 0
#define kSectionNetwork 1
#define kSectionSettings 2

#define kRowCountNetwork 3
#define kRowSettingMessages 0
#define kRowSettingLikes 1
#define kRowSettingLikers 2

#define kRowCountSettings 7
#define kRowSettingMyBanners 0
#define kRowSettingMyPage 1
#define kRowSettingProfile 2
#define kRowSettingSettings 3
#define kRowSettingFilters 4
#define kRowSettingHints 5
#define kRowSettingDisconnect 6

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
    
    // Header views
    ProfileHeaderView *_profileHeaderView;
    UIPelmelTitleView *_sectionNetworkHeaderView;
    UIPelmelTitleView *_sectionSettingsHeaderView;
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
    _sectionNetworkHeaderView = (UIPelmelTitleView*)[_uiService loadView:@"PMLHoursSectionTitleView"];
    _sectionSettingsHeaderView = (UIPelmelTitleView*)[_uiService loadView:@"PMLHoursSectionTitleView"];
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
    [self.tableView reloadData];
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
        case kSectionNetwork:
            return kRowCountNetwork;
        case kSectionSettings:
            return kRowCountSettings;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = kCellIdHD;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UITablePlaceTypeViewCell *placeTypeCell = (UITablePlaceTypeViewCell*)cell;
    cell.backgroundColor = UIColorFromRGB(0x272a2e);
    placeTypeCell.image.layer.cornerRadius=0;
    placeTypeCell.image.layer.masksToBounds=NO;
    placeTypeCell.image.layer.borderWidth=0;
    switch(indexPath.section) {
        case kSectionNetwork:
            switch(indexPath.row) {
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

            }
            break;
        case kSectionSettings: {

            switch(indexPath.row) {
                case kRowSettingMyBanners: {
                    placeTypeCell.label.text = NSLocalizedString(@"settings.mybanners","My banners");
                    placeTypeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    placeTypeCell.image.image = [UIImage imageNamed:@"mnuIconBanner"];
                    placeTypeCell.badgeLabel.hidden=YES;
                }
                    break;
                case kRowSettingSettings: {
                    placeTypeCell.label.text = NSLocalizedString(@"settings.settings","Settings");
                    placeTypeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    placeTypeCell.image.image = [UIImage imageNamed:@"mnuIconSettings"];
                    placeTypeCell.badgeLabel.hidden=YES;
                }
                    break;
                case kRowSettingMyPage: {
                    placeTypeCell.label.text = NSLocalizedString(@"settings.mypage", @"My Page");
                    placeTypeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    placeTypeCell.image.image = [CALImage getDefaultUserThumb];
                    CALImage *image = [_imageService imageOrPlaceholderFor:[_userService getCurrentUser] allowAdditions:NO];
                    [_imageService load:image to:placeTypeCell.image thumb:YES];
                    placeTypeCell.badgeLabel.hidden=YES;
                    placeTypeCell.image.layer.cornerRadius=15;
                    placeTypeCell.image.layer.masksToBounds=YES;
                    placeTypeCell.image.layer.borderWidth=1;
                    placeTypeCell.image.layer.borderColor=[[UIColor whiteColor] CGColor];
                    break;
                }
                case kRowSettingProfile: {
                    placeTypeCell.label.text = NSLocalizedString(@"settings.account.cell", @"Edit my profile");
                    placeTypeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    placeTypeCell.image.image = [UIImage imageNamed:@"mnuIconProfile"];
                    placeTypeCell.badgeLabel.hidden=YES;
                }
                    break;
                case kRowSettingFilters:
                    placeTypeCell.label.text = NSLocalizedString(@"settings.filters", @"Filters");
                    placeTypeCell.image.image = [UIImage imageNamed:@"mnuIconFilter"];
                    placeTypeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case kRowSettingHints: {
                    placeTypeCell.label.text = NSLocalizedString(@"settings.hints", @"Show hints");
                    placeTypeCell.accessoryType = UITableViewCellAccessoryNone;
                    placeTypeCell.image.image = [UIImage imageNamed:@"mnuIconInfo"];
                    placeTypeCell.badgeLabel.hidden=YES;
                    break;
                }
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch(section) {
        case kSectionHeading: {
            // Filling nickname and image of header view
            CurrentUser *user = [_userService getCurrentUser];
            [_profileHeaderView setNickname:user.pseudo parentWidth:self.tableView.frame.size.width];
            _profileHeaderView.editButtonIcon.hidden=YES;
            _profileHeaderView.profileImageView.image= nil;
            [[TogaytherService imageService] registerTappable:_profileHeaderView.profileImageView forViewController:self callback:self];
            CALImage *image = [_imageService imageOrPlaceholderFor:user allowAdditions:YES];
            [_imageService load:image to:_profileHeaderView.profileImageView thumb:NO];
            return _profileHeaderView;
        }
        case kSectionNetwork:
            _sectionNetworkHeaderView.titleLabel.text = NSLocalizedString(@"menu.section.network",@"My network");
            return _sectionNetworkHeaderView;
        case kSectionSettings:
            _sectionSettingsHeaderView.titleLabel.text = NSLocalizedString(@"menu.section.settings",@"My Settings");
            return _sectionSettingsHeaderView;
            
    }
    return nil;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch(section) {
        case kSectionHeading:
            return _profileHeaderView.bounds.size.height;
        case kSectionNetwork:
            return _sectionNetworkHeaderView.bounds.size.height;
        case kSectionSettings:
            return _sectionSettingsHeaderView.bounds.size.height;
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kSectionNetwork:
            switch(indexPath.row) {
                    
                case kRowSettingMessages: {
//                    [self performSegueWithIdentifier:@"directMsg" sender:self];
                    PMLMessageTableViewController *msgController = (PMLMessageTableViewController*)[_uiService instantiateViewController:@"messageView"];
                    [self.parentMenuController.navigationController pushViewController:msgController animated:YES];
                    break;
                }
                case kRowSettingLikes:
                    [self performSegueWithIdentifier:@"likes" sender:self];
                    break;
                case kRowSettingLikers:
                    [self performSegueWithIdentifier:@"likers" sender:self];
                    break;
            }
            break;
        case kSectionSettings:
            switch(indexPath.row) {
                case kRowSettingMyBanners: {
                    UIViewController *controller = [[TogaytherService uiService] instantiateViewController:SB_ID_BANNER_LIST];
                    [self.parentMenuController.navigationController pushViewController:controller animated:YES];
                    break;
                }
                case kRowSettingSettings:
                    [self performSegueWithIdentifier:@"settings" sender:self];
                    break;
                case kRowSettingMyPage:
                    [_uiService presentSnippetFor:[_userService getCurrentUser] opened:YES];
                    break;
                case kRowSettingProfile: {
                    UIViewController *accountController = [[TogaytherService uiService] instantiateViewController:SB_ID_MYACCOUNT];
                    [self.parentMenuController.navigationController pushViewController:accountController animated:YES];
                }
                    break;
                case kRowSettingFilters: {
                    FiltersViewController *filtersController = (FiltersViewController*)[_uiService instantiateViewController:SB_ID_FILTERS_MENU];
                    [self.parentMenuController.navigationController pushViewController:filtersController animated:YES];
                    break;
                }
                case kRowSettingHints:
                    [[TogaytherService helpService] resetHints];
                    [_uiService alertWithTitle:@"hint.reset.title" text:@"hint.reset.msg"];
                    break;
                case kRowSettingDisconnect:
                    // Disconnecting
                    [_userService disconnect];
                    // Dismissing this view and immediately
                    UIViewController *controller = [TogaytherService.uiService instantiateViewController:SB_LOGIN_CONTROLLER];
                    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
                    [self.parentMenuController dismissControllerMenu:YES];
                    [self.parentMenuController.navigationController presentViewController:navController animated:YES completion:nil];
                    

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
    [segue.destinationViewController setParentMenuController:self.parentMenuController];
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
    [self.parentMenuController dismissControllerMenu:YES];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint velocity = [(UIPanGestureRecognizer*)gestureRecognizer velocityInView:self.tableView];
    return (fabs(velocity.x)>fabs(velocity.y) && velocity.x <0);
}
- (void)menuPanned:(UITapGestureRecognizer*)gestureRecognizer {
    [self.parentMenuController dismissControllerMenu:YES];
}
#pragma mark - PMLImagePickerCallback
- (void)imagePicked:(CALImage *)image {
    [[TogaytherService imageService] upload:image forObject:[_userService getCurrentUser] callback:self];
}
#pragma mark - PMLImageUploadCallback
- (void)imageUploaded:(CALImage *)image {
    CurrentUser *currentUser = _userService.getCurrentUser;
    if(currentUser.otherImages == nil) {
        [currentUser setOtherImages:[[NSMutableArray alloc] init]];
    }
    CALImage *oldImage = currentUser.mainImage;
    currentUser.mainImage = image;
    if(oldImage != nil) {
        [currentUser.otherImages insertObject:oldImage atIndex:0];
    }
    _profileHeaderView.profileImageView.image = image.fullImage;
}
- (void)imageUploadFailed:(CALImage *)image {
    [_uiService alertWithTitle:@"upload.failed.title" text:@"upload.failed"];
}

@end
