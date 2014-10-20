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
#import "UITablePhotoViewCell.h"
#import "PMLAddTableViewCell.h"
#import "PhotoPreviewViewController.h"

#define kSectionCount 5
#define kSectionBirthday 0
#define kSectionMeasure 1
#define kSectionDescriptions 2
#define kSectionPhotos 3
#define kSectionTags 4

#define kRowCountBirthday 1
#define kRowCountMeasure 2
#define kRowIndexHeight 0
#define kRowIndexWeight 1

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
    
    // Progress
    UIProgressView *_progressView;
    // State
    BOOL operationInProgress;
    
    // Edit states
    BOOL _photoEdition;
    BOOL _descEdition;
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
//    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
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
    
//    // Loading description header view
//    views = [[NSBundle mainBundle] loadNibNamed:@"DescriptionHeader" owner:self options:nil];
//    descriptionHeaderView = [views objectAtIndex:0];
//    [descriptionHeaderView.addDescriptionButton addTarget:self action:@selector(addDescription:) forControlEvents:UIControlEventTouchUpInside];
    

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
    CurrentUser *user = userService.getCurrentUser;
    switch(section) {
        case kSectionBirthday:
            return 1;
        case kSectionMeasure:
            return 2;
        case kSectionDescriptions: {
            int descCount = (int)[user.descriptions count];
            return (descCount == 0 ? 1 : descCount)+1;
        }
        case kSectionPhotos: {
            int mainImageCount = user.mainImage == nil ? 0 : 1;
            return user.otherImages.count+mainImageCount+1;
        }
        case kSectionTags:
            return settingsService.listTags.count;
    }
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *birthdayCell = @"birthDate";
    static NSString *measureCell = @"measure";
    static NSString *descCell = @"descriptionUnique";
    static NSString *tagCell = @"tag";
    static NSString *photosCell = @"photo";
    static NSString *addCell = @"add";
    
    CurrentUser *user = userService.getCurrentUser;
    // Selecting the cell type
    NSString *cellId;
    switch(indexPath.section) {
        case kSectionBirthday:
            cellId = birthdayCell;
            break;
        case kSectionMeasure:
            cellId = measureCell;
            break;
        case kSectionDescriptions:
            cellId = indexPath.row == 0 ? addCell :descCell;
            break;
        case kSectionPhotos:
            // Last row of photo section is the add button, otherwise it is a photo cell
            cellId = indexPath.row == 0 ? addCell : photosCell;
            break;
        case kSectionTags:
            cellId = tagCell;
            break;
    }
    // Retrieving a cell instance
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];

    cell.backgroundColor = UIColorFromRGB(0x272a2e);
    // Formatting the cell
    switch(indexPath.section) {
        case kSectionBirthday: {
            // Birthday cell
            [self dateUpdated:user.birthDate label:cell.detailTextLabel];
            [datePickerDataSource registerTargetLabel:cell.detailTextLabel];
            PickerInputTableViewCell *pickerCell = (PickerInputTableViewCell*) cell;
            [pickerCell setPicker:datePicker];
            pickerCell.rowPath = indexPath;
            break;
        }
        case kSectionMeasure:
            // Measure cells
            switch(indexPath.row) {
                case kRowIndexHeight: {
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
                case kRowIndexWeight: {
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
        case kSectionDescriptions: {
            if(indexPath.row == 0) {
                PMLAddTableViewCell *addCell = (PMLAddTableViewCell*)cell;
                
                // Add button text and action
                addCell.addButton.titleLabel.text = NSLocalizedString(@"map.option.add", @"Add");
                [addCell.addButton addTarget:self action:@selector(addDescriptionTapped:) forControlEvents:UIControlEventTouchUpInside];

                // Modify button text and action
                addCell.modifyButton.titleLabel.text = NSLocalizedString(@"modify", @"modify");
                [addCell.modifyButton addTarget:self action:@selector(modifyDescriptionTapped:) forControlEvents:UIControlEventTouchUpInside];
                
                // Colors (a bug reverts colors of buttons to blue
                addCell.addButton.titleLabel.textColor = UIColorFromRGB(0x2db024);
                addCell.modifyButton.titleLabel.textColor = [UIColor whiteColor];
            } else {
                UITableDescriptionViewCell *descCell=(UITableDescriptionViewCell*)cell;
                [descCell setPicker:languagePicker];
                Description *d = [self getDescriptionFor:(int)indexPath.row];
                NSString *language = [NSString stringWithFormat:@"language.%@",d.languageCode];
                descCell.languageCodeLabel.text= NSLocalizedString(language,@"language");
                descCell.descriptionLabel.text = d.descriptionText;
                descCell.editButton.tag = indexPath.row;
                [descCell.editButton addTarget:self action:@selector(descriptionEditTapped:) forControlEvents:UIControlEventTouchUpInside];
                //            UITableDescriptionViewCell *descCell=(UITableDescriptionViewCell*)cell;
                //            descCell.inputView = picker;
                //            [descCell setPicker:picker];
                //            descCell.descriptionText.inputView = picker;
            }
            break;
        }
        case kSectionPhotos:
            if(indexPath.row > 0) {
                UITablePhotoViewCell *photoCell = (UITablePhotoViewCell*)cell;
                
                CALImage *image = [self imageForIndexPath:indexPath];
                if(indexPath.row == 1) {
                    photoCell.label.text = NSLocalizedString(@"photos.profile", @"Title of a profile photo in the photo list");
                } else {
                    photoCell.label.text = nil; //[NSString stringWithFormat:NSLocalizedString(@"photos.other", @"Title of a non-profile photo in the photo list"),indexPath.row+1];
                }
                
                [imageService load:image to:photoCell.photo thumb:YES];
                [photoCell.activity stopAnimating];
                photoCell.activity.hidden=YES;
            } else {
                PMLAddTableViewCell *addCell = (PMLAddTableViewCell*)cell;
                addCell.addButton.titleLabel.text = NSLocalizedString(@"map.option.add", @"Add");
                [addCell.addButton addTarget:self action:@selector(addPhotoTapped:) forControlEvents:UIControlEventTouchUpInside];
                addCell.modifyButton.titleLabel.text = NSLocalizedString(@"modify", @"modify");
                [addCell.modifyButton addTarget:self action:@selector(modifyPhotoTapped:) forControlEvents:UIControlEventTouchUpInside];
                
                // Colors (a bug reverts colors of buttons to blue
                addCell.addButton.titleLabel.textColor = UIColorFromRGB(0x2db024);
                addCell.modifyButton.titleLabel.textColor = [UIColor whiteColor];
            }

//            int mainImage = user.mainImage == nil ? 0 : 1;
//            NSInteger photosCount = user.otherImages.count+mainImage;
//            NSString *photosLabel = [NSString stringWithFormat:NSLocalizedString(@"profile.photo.subtitle", @"subtitle for number of photos"),photosCount];
//            cell.textLabel.text = NSLocalizedString(@"profile.photo.manage", nil);
//            cell.detailTextLabel.text = photosLabel;
            break;

        case kSectionTags: {
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

-(CALImage*)imageForIndexPath:(NSIndexPath*)indexPath {
    CALImage *image;
    CurrentUser *user = userService.getCurrentUser;
    if(indexPath.row == 1) {
        image = user.mainImage;
    } else {
        image = [user.otherImages objectAtIndex:indexPath.row-2];
    }
    return image;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CurrentUser *user = userService.getCurrentUser;
    switch(indexPath.section) {
        case kSectionBirthday:
            // Setting current date
            [datePickerDataSource setDate:user.birthDate picker:datePicker];
            break;
        case kSectionDescriptions: {
            UITableDescriptionViewCell *cell = (UITableDescriptionViewCell*)[tableView cellForRowAtIndexPath:indexPath];
            [langPickerDataSource registerLabel:cell.languageCodeLabel forIndex:(int)indexPath.row];
            
            Description *d = [self getDescriptionFor:(int)indexPath.row];
            [langPickerDataSource setLanguage:d.languageCode picker:languagePicker];
            
            
//            [self editLanguage:indexPath.row];
            break;
        }
        case kSectionPhotos: {
            if(indexPath.row >0) {
                [self performSegueWithIdentifier:@"previewPhoto" sender:self];
            }
            break;
        }
        case kSectionTags: {
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
    if(user.descriptions.count <= index-1) {
        [user addDescription:@"" language:@"fr"];
    }
    return [user.descriptions objectAtIndex:index-1];
}
- (void) selectCell:(UITableViewCell*)cellToSelect {
    if(currentPicker != nil) {
        [currentPicker removeFromSuperview];
        currentPicker = nil;
    }
    [cellToSelect setSelected:YES];
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
            
            // Sizing label to fit its width (so the edit button will be next to the text
            CGSize optimalSize = [profileHeaderView.pseudoLabel sizeThatFits:CGSizeMake(tableView.bounds.size.width, profileHeaderView.pseudoLabel.bounds.size.height)];
            profileHeaderView.nicknameLabelWidthConstraint.constant = optimalSize.width;
            
            // Updating image thumb for user
            CALImage *mainImage = user.mainImage;
            profileImageView = profileHeaderView.profileImageView;
            [imageService registerTappable:profileImageView forViewController:self callback:self];
            
            [activityView stopAnimating];
            [profileHeaderView.activityIndicator stopAnimating];
            profileHeaderView.activityIndicator.hidden=YES;
            [imageService load:mainImage to:profileImageView thumb:YES];
            
            [profileHeaderView.editButton addTarget:self action:@selector(editNicknameTapped:) forControlEvents:UIControlEventTouchUpInside];
            return profileHeaderView;
        }
//        case 2: {
//            return descriptionHeaderView;
//        }
    }
    return [super tableView:tableView viewForHeaderInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section) {
        case kSectionMeasure:
            return NSLocalizedString(@"settings.account.cell", @"settings.account.cell");
        case kSectionDescriptions:
            return NSLocalizedString(@"profile.description", @"profile.description");
        case 3:
            return NSLocalizedString(@"profile.photo.header", "Title of the tags section in profile page");
        case 4:
            return NSLocalizedString(@"profile.tags.title", "Title of the tags section in profile page");
    }
    return [super tableView:tableView titleForHeaderInSection:section];
}
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    switch (section) {
        case kSectionMeasure:
        case kSectionDescriptions:
        case kSectionPhotos:
        case kSectionTags: {
            UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView*)view;
            headerView.textLabel.textColor = [UIColor whiteColor];
            headerView.textLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:15];
            headerView.backgroundView.backgroundColor = UIColorFromRGB(0x2d2f31);
            break;
        }
        default:
            break;
    }

}
-(BOOL)hasDescriptionFor:(NSString*)language {
    CurrentUser *user = [userService getCurrentUser];
    BOOL hasLang = NO;
    for(Description *desc in user.descriptions) {
        if([desc.languageCode isEqualToString: language]) {
            hasLang = YES;
            break;
        }
    }
    return hasLang;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch(section) {
        case 0:
            return profileHeaderView.bounds.size.height;

//        case kSectionDescriptions:
//            return 40;
//        case kSectionPhotos:
//            return 40;
//        case kSectionTags:
//            return 40;
        case kSectionMeasure:
        case kSectionDescriptions:
        case kSectionPhotos:
        case kSectionTags:
            return 30;
        default:
            return [super tableView:tableView heightForHeaderInSection:section];
    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kSectionDescriptions: {
            if(indexPath.row == 0) {
                return 44;
            } else {
                Description *desc = [self getDescriptionFor:indexPath.row];
                NSInteger width = tableView.bounds.size.width-49;
                CGRect rect = [desc.descriptionText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                              attributes:@{NSFontAttributeName: [UIFont fontWithName:PML_FONT_DEFAULT size:15]}
                                                                 context:nil];
                return rect.size.height+37;
            }
        }
        case kSectionPhotos:
            return 64;
        case kSectionTags:
            return 35;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"editDesc"]) {
        DescriptionEditorViewController *controller = segue.destinationViewController;
        controller.editedDescription = (Description*)sender;
    } else if([segue.identifier isEqualToString:@"previewPhoto"]) {
        // Retrieving selection
        NSIndexPath *selectedPath = [self.tableView indexPathForSelectedRow];
        // Retrieving image to preview
        CurrentUser *user = userService.getCurrentUser;
        CALImage *image = [self imageForIndexPath:selectedPath];
        PhotoPreviewViewController *controller = [segue destinationViewController];
        [controller setCurrentImage:image];
        [controller setImaged:user];
    }

}

#pragma mark - TableView edition
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == kSectionDescriptions && indexPath.row>0 && _descEdition ) || (indexPath.section == kSectionPhotos && indexPath.row>0 && _photoEdition);
}
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    CurrentUser *user = userService.getCurrentUser;
    if(indexPath.section == kSectionPhotos) {
        if(indexPath.row == 0) {
            return NO;
        } else {
            
            BOOL allImagesHaveKey = YES;
            // Checking that every image have keys
            for(CALImage *otherImage in user.otherImages) {
                allImagesHaveKey = allImagesHaveKey && otherImage.key!=nil;
            }
            // We only allow move if all images have keys otherwise we cannot move
            return user.mainImage.key != nil && allImagesHaveKey && !operationInProgress;
        }
    } else {
        return NO;
    }
}
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        switch (indexPath.section) {
            case 2: {
                CurrentUser *user = [userService getCurrentUser];
                if(user.descriptions.count > indexPath.row-1) {
                    // Description will be removed when validating profile
                    [user.descriptions removeObjectAtIndex:indexPath.row-1];
                }
                // Delete the row from the data source
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
            }
            case kSectionPhotos: {
                CurrentUser *user = userService.getCurrentUser;
                // Getting an array with all images for manipulation
                NSMutableArray *images = [self getImagesArray:user];
                // Getting image to delete
                CALImage *image=[self imageForIndexPath:indexPath];
                // Removing it from server
                operationInProgress = YES;
                [imageService remove:image callback:self];
                // Removing it from local structure
                [images removeObject:image];
                
                // Updating user's images
                [self rearrangeImages:user images:images];
                
                // Delete the row from the data source
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
            }
            default:
                break;
        }
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    
}


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    CurrentUser *user = userService.getCurrentUser;
    if(fromIndexPath.section == kSectionPhotos && toIndexPath.section == kSectionPhotos) {
        NSMutableArray *images = [self getImagesArray:user];
        
        // Getting moved element
        CALImage *image = [self imageForIndexPath:fromIndexPath];
        [images removeObject:image];
        [images insertObject:image atIndex:toIndexPath.row-1];
        
        // Rearranging
        [self rearrangeImages:user images:images];
        operationInProgress = YES;
        [imageService reorder:image newIndex:(int)toIndexPath.row-1 callback:self];
    }
}
-(NSMutableArray*)getImagesArray:(Imaged*)user {
    NSMutableArray *images = [NSMutableArray arrayWithArray:user.otherImages];
    [images insertObject:user.mainImage atIndex:0];
    return images;
}
-(NSInteger)imageCount:(Imaged*)user {
    return (user.mainImage ? 1 : 0) + user.otherImages.count;
}
-(void) rearrangeImages:(Imaged*)user images:(NSMutableArray*)images {
    // Re-arranging user
    user.mainImage = [images objectAtIndex:0];
    [images removeObjectAtIndex:0];
    user.otherImages = images;
}

#pragma mark - PMLImagePickerCallback
- (void)imagePicked:(CALImage *)image {
    CurrentUser *currentUser = userService.getCurrentUser;

    [imageService upload:image forObject:currentUser callback:self];
}

- (void)imageUploaded:(CALImage *)image {
    CurrentUser *currentUser = userService.getCurrentUser;
    if(currentUser.otherImages == nil) {
        [currentUser setOtherImages:[[NSMutableArray alloc] init]];
    }
    CALImage *oldImage = currentUser.mainImage;
    currentUser.mainImage = image;
    if(oldImage != nil) {
        [currentUser.otherImages insertObject:oldImage atIndex:0];
    }
    [self.tableView reloadData];
    
    
    image.fullImage = nil;
    image.thumbImage = nil;
    // Refetching thumbs to get the real thumb of upload image, as seen
    // by other users
    [imageService load:currentUser.mainImage to:profileImageView thumb:YES];
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

#pragma mark - Action callbacks



- (void)languageChanged:(NSString *)languageCode label:(UILabel *)label index:(int)index {
    label.text = languageCode;
    CurrentUser *user = userService.getCurrentUser;
    Description *d = [user.descriptions objectAtIndex:index];
    [d setLanguageCode:languageCode];
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
- (void)dateUpdated:(NSDate *)date label:(UILabel*)label {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    label.text = [dateFormatter stringFromDate:date];
    [label sizeToFit];
    CurrentUser *user = userService.getCurrentUser;
    user.birthDate =date;
}

- (void)descriptionEditTapped:(UIButton*)button {
    Description *desc = [self getDescriptionFor:(int)button.tag];
    [self performSegueWithIdentifier:@"editDesc" sender:desc];
}
- (void)addPhotoTapped:(UIButton*)button {
    [imageService promptUserForPhoto:self callback:self];
}
- (void)modifyPhotoTapped:(UIButton*)button {
    _photoEdition = !_photoEdition;
    [self updateEditingStyle];
}
- (void)modifyDescriptionTapped:(UIButton*)button {
    _descEdition = !_descEdition;
    [self updateEditingStyle];
}
-(void) updateEditingStyle {
    BOOL newEditing = (_photoEdition || _descEdition);
    if(self.editing && newEditing) {
        self.editing = NO;
    }
    [self setEditing:newEditing animated:YES];
}
-(void)addDescriptionTapped:(id)source {
    CurrentUser *user = [userService getCurrentUser];
    NSString *currentLanguage = [[[NSLocale preferredLanguages] objectAtIndex:0] substringToIndex:2];
    NSArray *languages = @[@"en",@"es",@"fr",@"de",@"it",@"nl"];
    int index = 0;
    while([self hasDescriptionFor:currentLanguage] && index < languages.count) {
        currentLanguage = [languages objectAtIndex:index++];
    }
    
    // Only adding if available
    if(![self hasDescriptionFor:currentLanguage]) {
        [user addDescription:@"" language:currentLanguage];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:user.descriptions.count inSection:kSectionDescriptions]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
-(void)editNicknameTapped:(UIButton*)button {
    NSString *title = NSLocalizedString(@"profile.nickname.change.title", @"profile.nickname.change.title");
    NSString *message = NSLocalizedString(@"profile.nickname.change.msg", @"profile.nickname.change.msg");;
    NSString *cancel = NSLocalizedString(@"cancel", @"cancel");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:@"Ok", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    // Initializing text field to current user nickname
    CurrentUser *user = [userService getCurrentUser];
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.text = user.pseudo;
    [alertView show];
}
#pragma mark - ImageManagementCallback
- (void)imageRemoved:(CALImage *)image {
    operationInProgress = NO;
}
- (void)imageReordered:(CALImage *)image {
    operationInProgress = NO;
}

- (void)imageRemovalFailed:(CALImage *)image message:(NSString *)message {
    NSLog(@"TODO: Implement removal failure");
}
#pragma  mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex != [alertView cancelButtonIndex]) {
        CurrentUser *user = [userService getCurrentUser];
        UITextField *textField = [alertView textFieldAtIndex:0];
        [user setPseudo:textField.text];
        [self.tableView reloadData];
    }
}
@end
