//
//  ProfileTableViewController.m
//  nativeTest
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "ProfileTableViewController.h"
#import "ProfileHeaderView.h"
#import "TogaytherService.h"
#import "CurrentUser.h"
#import "DescriptionHeaderView.h"
#import "UITableMeasureViewCell.h"
#import "UITableDescriptionViewCell.h"
#import "LanguagePickerDataSource.h"
#import "Description.h"
#import "PickerInputTableViewCell.h"
#import "DescriptionEditorViewController.h"
#import "UITableTagViewCell.h"
#import "ImageService.h"


#define kMeasureHeight @"height"
#define kMeasureWeight @"weight"

@interface ProfileTableViewController ()

@end

@implementation ProfileTableViewController {
    DatePickerDataSource *datePickerDataSource;
    LanguagePickerDataSource *langPickerDataSource;
    UIView *currentPicker;
    
    // Services
    UserService *userService;
    ConversionService *conversionService;
    DataService *dataService;
    SettingsService *settingsService;
    ImageService *imageService;
    UIService *_uiService;
    
    // Picker
    UIPickerView *languagePicker;
    UIPickerView *datePicker;
    UIActivityIndicatorView *activityView;
    UIImageView __weak *profileImageView;
    
    ProfileHeaderView *profileHeaderView;
    DescriptionHeaderView *descriptionHeaderView;
    UIButton *disconnectButton;
    
    // Progress
    UIProgressView *_progressView;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [TogaytherService applyCommonLookAndFeel:self];
    
    // Setting title
    self.view.backgroundColor =UIColorFromRGB(0x272a2e);
    self.tableView.backgroundColor =  UIColorFromRGB(0x272a2e);
    self.tableView.separatorColor = [UIColor clearColor];
    self.title = NSLocalizedString(@"profile.title", nil);
    
    // Getting service instance
    userService = [TogaytherService userService];
    conversionService = [TogaytherService getConversionService];
    dataService = [TogaytherService dataService];
    settingsService = [TogaytherService settingsService];
    imageService = [TogaytherService imageService];
    _uiService = [TogaytherService uiService];
    
    // Initializing date picker
    datePickerDataSource = [[DatePickerDataSource alloc] initWithCallback:self];
    langPickerDataSource = [[LanguagePickerDataSource alloc] initWithCallback:self];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    // Configuring language picker
    languagePicker = [[UIPickerView alloc] init];
    languagePicker.dataSource = langPickerDataSource;
    languagePicker.delegate = langPickerDataSource;
    [languagePicker setShowsSelectionIndicator:YES];
    languagePicker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    // Configuring birth date picker
    datePicker = [[UIPickerView alloc] init];
    datePicker.dataSource = datePickerDataSource;
    datePicker.delegate = datePickerDataSource;
    [datePicker setShowsSelectionIndicator:YES];
    datePicker.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    // Fetching user thumb image
    CurrentUser *user = userService.getCurrentUser;
    CALImage *mainImage = user.mainImage;
    if(mainImage==nil || [mainImage getThumbImage]==nil) {

        [imageService load:user.mainImage to:profileImageView thumb:YES];
//        [imageService getThumbs:user mainImageOnly:YES callback:self];
    }

    // Loading profile header view
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"ProfileHeader" owner:self options:nil];
    profileHeaderView = [views objectAtIndex:0];
    
    // Loading description header view
    views = [[NSBundle mainBundle] loadNibNamed:@"DescriptionHeader" owner:self options:nil];
    descriptionHeaderView = [views objectAtIndex:0];
    [descriptionHeaderView.addDescriptionButton addTarget:self action:@selector(addDescription:) forControlEvents:UIControlEventTouchUpInside];
    
    // Building the disconnect button
    disconnectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [disconnectButton setBackgroundImage:[[UIImage imageNamed:@"delete-button.png"]
                                           stretchableImageWithLeftCapWidth:8.0f
                                           topCapHeight:0.0f]
                                 forState:UIControlStateNormal];
    
    [disconnectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    disconnectButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    disconnectButton.titleLabel.shadowColor = [UIColor lightGrayColor];
    disconnectButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    [disconnectButton setTitle:NSLocalizedString(@"disconnect", @"Disconnect button label") forState:UIControlStateNormal];
    [disconnectButton setBackgroundColor:[UIColor whiteColor]];
    [disconnectButton addTarget:self action:@selector(disconnectTapped:) forControlEvents:UIControlEventTouchUpInside];
}
- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"Will appear");
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    if(_progressView == nil) {
        // Progress view
        _progressView = [_uiService addProgressTo:self.navigationController];
    } else {
        [_uiService setProgressView:_progressView];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"View did appear");
    [self.tableView reloadData];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}
- (void)viewDidUnload
{
    datePickerDataSource = nil;
    currentPicker = nil;
    settingsService = nil;
    languagePicker = nil;
    datePicker = nil;
    activityView = nil;
    profileImageView = nil;
    descriptionHeaderView = nil;
    disconnectButton = nil;
    profileHeaderView = nil;
    userService = nil;
    conversionService = nil;
    langPickerDataSource = nil;
    datePickerDataSource = nil;
    dataService = nil;
    imageService = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [imageService unregisterTappable:profileImageView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case 0:
            return 1;
        case 1:
            return 2;
        case 2: {
            CurrentUser *user = userService.getCurrentUser;
            int descCount = (int)[user.descriptions count];
            return descCount == 0 ? 1 : descCount;
        }
        case 3:
            return 1;
        case 4:
            return settingsService.listTags.count;
    }
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *birthdayCell = @"birthDate";
    static NSString *measureCell = @"measure";
    static NSString *descCell = @"desc";
    static NSString *tagCell = @"tag";
    static NSString *photosCell = @"photos";
    
    // Selecting the cell type
    NSString *cellId;
    switch(indexPath.section) {
        case 0:
            cellId = birthdayCell;
            break;
        case 1:
            cellId = measureCell;
            break;
        case 2:
            cellId = descCell;
            break;
        case 3:
            cellId = photosCell;
            break;
        case 4:
            cellId = tagCell;
            break;
    }
    // Retrieving a cell instance
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    CurrentUser *user = userService.getCurrentUser;
    cell.backgroundColor = UIColorFromRGB(0x272a2e);
    // Formatting the cell
    switch(indexPath.section) {
        case 0: {
            // Birthday cell
            [self dateUpdated:user.birthDate label:cell.detailTextLabel];
            [datePickerDataSource registerTargetLabel:cell.detailTextLabel];
            PickerInputTableViewCell *pickerCell = (PickerInputTableViewCell*) cell;
            [pickerCell setPicker:datePicker];
            pickerCell.rowPath = indexPath;
            break;
        }
        case 1:
            // Measure cells
            switch(indexPath.row) {
                case 0: {
                    // Formatting height
                    UITableMeasureViewCell *measureCell = (UITableMeasureViewCell*)cell;
                    measureCell.measureLabel.text = NSLocalizedString(@"profile.height", @"Height label of profile section");
                    measureCell.measureSlider.minimumValue = 120;
                    measureCell.measureSlider.maximumValue = 210;
                    [measureCell.measureSlider setValue:user.heightInCm];
                    // Registering as delegate to be notified of measure changes
                    [measureCell setDelegate:self id:kMeasureHeight];
                    break;
                }
                case 1: {
                    // Formatting weight
                    UITableMeasureViewCell *measureCell = (UITableMeasureViewCell*)cell;
                    measureCell.measureLabel.text = NSLocalizedString(@"profile.weight", @"Weight label of profile section");
                    measureCell.measureSlider.minimumValue= 40;
                    measureCell.measureSlider.maximumValue= 150;
                    [measureCell.measureSlider setValue:user.weightInKg];
                    // Registering as delegate to be notified of measure changes
                    [measureCell setDelegate:self id:kMeasureWeight];
                    break;
                }
            }
            break;
        case 2: {
            UITableDescriptionViewCell *descCell=(UITableDescriptionViewCell*)cell;
            [descCell setPicker:languagePicker];
            Description *d = [self getDescriptionFor:(int)indexPath.row];
            descCell.languageCodeLabel.text= [d.languageCode uppercaseString];
            descCell.descriptionLabel.text = d.descriptionText;
            
//            UITableDescriptionViewCell *descCell=(UITableDescriptionViewCell*)cell;
//            descCell.inputView = picker;
//            [descCell setPicker:picker];
//            descCell.descriptionText.inputView = picker;
            break;
        }
        case 3: {
            int mainImage = user.mainImage == nil ? 0 : 1;
            NSInteger photosCount = user.otherImages.count+mainImage;
            NSString *photosLabel = [NSString stringWithFormat:NSLocalizedString(@"profile.photo.subtitle", @"subtitle for number of photos"),photosCount];
            cell.textLabel.text = NSLocalizedString(@"profile.photo.manage", nil);
            cell.detailTextLabel.text = photosLabel;
            break;
        }
        case 4: {
            UITableTagViewCell *tagCell = (UITableTagViewCell*)cell;
            NSArray *tags = settingsService.listTags;
            NSString *tagCode = [tags objectAtIndex:indexPath.row];
            tagCell.icon.image = [imageService getTagImage:tagCode];
            tagCell.label.text = tagCode;
            if([user.tags containsObject:tagCode]) {
                tagCell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                tagCell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    }
    return cell;
}


- (void)measureChanged:(UITableMeasureViewCell *)cell id:(NSString *)identifier {
    if(currentPicker != nil) {
        [currentPicker removeFromSuperview];
    }
    float value = cell.measureSlider.value;
    CurrentUser *user = userService.getCurrentUser;
    if([kMeasureHeight isEqualToString:identifier]) {
        cell.measureInternationalLabel.text = [conversionService getHeightLabel:value imperial:NO];
        cell.measureImperialLabel.text=[conversionService getHeightLabel:value imperial:YES];
        [user setHeightInCm:(NSInteger)value];
    } else {
        cell.measureInternationalLabel.text = [conversionService getWeightLabel:value imperial:NO];
        cell.measureImperialLabel.text=[conversionService getWeightLabel:value imperial:YES];
        [user setWeightInKg:value];
    }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 2;
}
- (void)languageChanged:(NSString *)languageCode label:(UILabel *)label index:(int)index {
    label.text = languageCode;
    CurrentUser *user = userService.getCurrentUser;
    Description *d = [user.descriptions objectAtIndex:index];
    [d setLanguageCode:languageCode];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        switch (indexPath.section) {
            case 2: {
                CurrentUser *user = [userService getCurrentUser];
                if(user.descriptions.count > indexPath.row) {
                    [user.descriptions removeObjectAtIndex:indexPath.row];
                }
                // Delete the row from the data source
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
            }
            default:
                break;
        }
        
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.section) {
        case 0: {
            // Setting current date
            CurrentUser *user = userService.getCurrentUser;
            [datePickerDataSource setDate:user.birthDate picker:datePicker];
            break;
        }
        case 2: {
            UITableDescriptionViewCell *cell = (UITableDescriptionViewCell*)[tableView cellForRowAtIndexPath:indexPath];
            [langPickerDataSource registerLabel:cell.languageCodeLabel forIndex:(int)indexPath.row];
            
            Description *d = [self getDescriptionFor:(int)indexPath.row];
            [langPickerDataSource setLanguage:d.languageCode picker:languagePicker];
            
            
//            [self editLanguage:indexPath.row];
            break;
        }
        case 4: {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            // Retrieving selected tag
            NSString *tagCode = [settingsService.listTags objectAtIndex:indexPath.row];
            CurrentUser *user = userService.getCurrentUser;
            // Unselected if previously selected
            if(cell.accessoryType  == UITableViewCellAccessoryCheckmark) {
                cell.accessoryType = UITableViewCellAccessoryNone;
                [user.tags removeObject:tagCode];
            } else {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [user.tags addObject:tagCode];
            }
            [cell setSelected:NO animated:YES   ];
            break;
        }
    }
    // Navigation logic may go here. Create and push another view controller.
    /*
     DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"Nib name" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}
-(Description*)getDescriptionFor:(int)index {
    // Setting current date
    CurrentUser *user = userService.getCurrentUser;
    if(user.descriptions.count <= index) {
        [user addDescription:@"" language:@"fr"];
    }
    return [user.descriptions objectAtIndex:index];
}
- (void) selectCell:(UITableViewCell*)cellToSelect {
    if(currentPicker != nil) {
        [currentPicker removeFromSuperview];
        currentPicker = nil;
    }
    [cellToSelect setSelected:YES];
}
- (void)dateUpdated:(NSDate *)date label:(UILabel*)label {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    label.text = [dateFormatter stringFromDate:date];
    [label sizeToFit];
    CurrentUser *user = userService.getCurrentUser;
    user.birthDate =date;
}
- (IBAction)dismiss:(id)sender {
    CurrentUser *user = [userService getCurrentUser];
    int age = [userService getAge:user];
    if(age<12) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"profile.mustBe18.title", @"profile.mustBe18.title")
                                                        message:NSLocalizedString(@"profile.mustBe18", @"profile.mustBe18")
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // Registering user info
    self.title = NSLocalizedString(@"profile.save", "Wait message while sending user data to server for save");
    // Updating
    [userService updateCurrentUser];
    // Dismissing
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
}


-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch(section) {
        case 0: {

            CurrentUser *user = userService.getCurrentUser;
            
            // Updating header title with user pseudo
            profileHeaderView.pseudoLabel.text=user.pseudo;
            
            // Updating image thumb for user
            CALImage *mainImage = user.mainImage;
            profileImageView = profileHeaderView.profileImageView;
            [imageService registerTappable:profileImageView forViewController:self callback:self];
            
            [activityView stopAnimating];
            [profileHeaderView.activityIndicator stopAnimating];
            profileHeaderView.activityIndicator.hidden=YES;
            [imageService load:mainImage to:profileImageView thumb:YES];
            
            return profileHeaderView;
        }
        case 2: {
            return descriptionHeaderView;
        }
    }
    return [super tableView:tableView viewForHeaderInSection:section];
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    switch (section) {
        case 4: {
            return disconnectButton;
        }
    }
    return [super tableView:tableView viewForFooterInSection:section];
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    switch(section) {
        case 4:
            return 45;
    }
    return [super tableView:tableView heightForFooterInSection:section];
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section) {
        case 3:
            return NSLocalizedString(@"profile.photo.header", "Title of the tags section in profile page");
        case 4:
            return NSLocalizedString(@"profile.tags.title", "Title of the tags section in profile page");
    }
    return [super tableView:tableView titleForHeaderInSection:section];
}
-(void)addDescription:(id)source {
    CurrentUser *user = [userService getCurrentUser];
    NSString *currentLanguage = [[[NSLocale preferredLanguages] objectAtIndex:0] substringToIndex:2];
    [user addDescription:@"" language:currentLanguage];
    
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch(section) {
        case 0:
            return 90;
        case 2:
            return 40;
        case 3:
            return 40;
        case 4:
            return 40;
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case 4:
            return 35;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 2) {
        Description *desc = [self getDescriptionFor:(int)indexPath.row];
        [self performSegueWithIdentifier:@"editDesc" sender:desc];
    }
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"editDesc"]) {
        DescriptionEditorViewController *controller = segue.destinationViewController;
        controller.editedDescription = (Description*)sender;
    }
}

- (void)imagePicked:(CALImage *)image {
    CurrentUser *currentUser = userService.getCurrentUser;
    CALImage *oldImage = currentUser.mainImage;
    currentUser.mainImage = image;
    if(oldImage != nil) {
        [currentUser.otherImages insertObject:oldImage atIndex:0];
    }
    [self.tableView reloadData];
    [imageService upload:image forObject:currentUser callback:self];
}

- (void)imageUploaded:(CALImage *)image {
    image.fullImage = nil;
    image.thumbImage = nil;
    CurrentUser *user = [userService getCurrentUser];
    // Refetching thumbs to get the real thumb of upload image, as seen
    // by other users
    [imageService load:user.mainImage to:profileImageView thumb:YES];
}
- (void)imageUploadFailed:(CALImage *)image {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"upload.failed.title", @"upload.failed.title")
                                                    message:NSLocalizedString(@"upload.failed", @"upload.failed")
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    CurrentUser *user = [userService getCurrentUser];
    if(user.mainImage == image) {
        user.mainImage = [user.otherImages objectAtIndex:0];
        [user.otherImages removeObjectAtIndex:0];
    } else {
        for(int i = 0 ; i<  user.otherImages.count ; i++) {
            CALImage *img = [user.otherImages objectAtIndex:i];
            if(img == image) {
                [user.otherImages removeObjectAtIndex:i];
                break;
            }
        }
    }
    [self.tableView reloadData];
}

-(void)disconnectTapped:(id)sender {
    // Disconnecting
    [userService disconnect];
    // Dismissing this view and immediately
    [self performSegueWithIdentifier:@"login" sender:self];
}
@end
