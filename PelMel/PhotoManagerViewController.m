//
//  PhotoManagerViewController.m
//  togayther
//
//  Created by Christophe Fondacci on 10/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "PhotoManagerViewController.h"
#import "TogaytherService.h"
#import "UITablePhotoViewCell.h"
#import "GalleryService.h"
#import "PhotoPreviewViewController.h"
@interface PhotoManagerViewController ()

@end

@implementation PhotoManagerViewController {
    // Services
    UserService *userService;
    ImageService *imageService;
    UIService *_uiService;
    
    // Controls
    UISegmentedControl *button;
    
    // State
    BOOL operationInProgress;
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
    userService = [TogaytherService userService];
    imageService = [TogaytherService imageService];
    _uiService = [TogaytherService uiService];
    
//    CurrentUser *user = userService.getCurrentUser;
//    [imageService getThumbs:user mainImageOnly:NO callback:self];
    
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    [_uiService addProgressTo:self.navigationController];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.editing = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    CurrentUser *user = userService.getCurrentUser;
    int mainImageCount = user.mainImage == nil ? 0 : 1;
    return user.otherImages.count+mainImageCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"photo";
    UITablePhotoViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    CurrentUser *user = userService.getCurrentUser;
    CALImage *image;
    if(indexPath.row == 0) {
        image = user.mainImage;
        cell.label.text = NSLocalizedString(@"photos.profile", @"Title of a profile photo in the photo list");
    } else {
        image = [user.otherImages objectAtIndex:indexPath.row-1];
        cell.label.text = [NSString stringWithFormat:NSLocalizedString(@"photos.other", @"Title of a non-profile photo in the photo list"),indexPath.row+1];
    }
    
    [imageService load:image to:cell.photo thumb:YES];
    [cell.activity stopAnimating];
    cell.activity.hidden=YES;
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self tableView:tableView canMoveRowAtIndexPath:indexPath];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        CurrentUser *user = userService.getCurrentUser;
        // Getting an array with all images for manipulation
        NSMutableArray *images = [self getImagesArray:user];
        // Getting image to delete
        CALImage *image=[images objectAtIndex:indexPath.row];
        // Removing it from server
        operationInProgress = YES;
        [imageService remove:image callback:self];
        // Removing it from local structure
        [images removeObject:image];
        
        // Updating user's images
        [self rearrangeImages:user images:images];
        
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    CurrentUser *user = userService.getCurrentUser;
    
    NSMutableArray *images = [self getImagesArray:user];
    
    // Getting moved element
    CALImage *image = [images objectAtIndex:fromIndexPath.row];
    [images removeObject:image];
    [images insertObject:image atIndex:toIndexPath.row];
    
    // Rearranging
    [self rearrangeImages:user images:images];
    operationInProgress = YES;
    [imageService reorder:image newIndex:(int)toIndexPath.row callback:self];
}

-(NSMutableArray*)getImagesArray:(Imaged*)user {
    NSMutableArray *images = [NSMutableArray arrayWithArray:user.otherImages];
    [images insertObject:user.mainImage atIndex:0];
    return images;
}
-(void) rearrangeImages:(Imaged*)user images:(NSMutableArray*)images {
    // Re-arranging user
    user.mainImage = [images objectAtIndex:0];
    [images removeObjectAtIndex:0];
    user.otherImages = images;
}


// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    CurrentUser *user = userService.getCurrentUser;
    BOOL allImagesHaveKey = YES;
    // Checking that every image have keys
    for(CALImage *otherImage in user.otherImages) {
        allImagesHaveKey = allImagesHaveKey && otherImage.key!=nil;
    }
    // We only allow move if all images have keys otherwise we cannot move
    return user.mainImage.key != nil && allImagesHaveKey && !operationInProgress;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 51;
}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        button = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:NSLocalizedString(@"photos.add",@"Add photo button")]];
        button.momentary = YES;
//        [button addTarget:self action:@selector(addPhoto:) forControlEvents:UIControlEventTouchUpInside];
        [imageService registerTappable:button forViewController:self callback:self];
        return button;
    }
    return [self tableView:tableView viewForHeaderInSection:section];
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (void)imagePicked:(CALImage *)image {
    [button setTitle:NSLocalizedString(@"photos.uploading", @"Uploading photo") forSegmentAtIndex:0];
    [button setEnabled:NO];
    CurrentUser *user = [userService getCurrentUser];
    [imageService upload:image forObject:user callback:self];
}
- (void)imageUploaded:(CALImage *)image {
    NSLog(@"Image uploaded : adjusting list");
    CurrentUser *user = userService.getCurrentUser;
    if(user.otherImages == nil) {
        [user setOtherImages:[[NSMutableArray alloc] init]];
    }
    if(user.mainImage != nil) {
        [user.otherImages insertObject:user.mainImage atIndex:0];
    }
    user.mainImage=image;
    
    image.fullImage = nil;
    image.thumbImage = nil;
    // Refetching thumbs to get the real thumb of upload image, as seen
    // by other users
//    [imageService getThumbs:user mainImageOnly:NO callback:self];
    
    [self.tableView reloadData];
    [button setEnabled:YES];
    [button setTitle:NSLocalizedString(@"photos.add", @"Add photo button") forSegmentAtIndex:0];
}
- (void)imageUploadFailed:(CALImage *)image {
    NSLog(@"Upload failed");
    [button setEnabled:YES];
    [button setTitle:NSLocalizedString(@"photos.add", @"Add photo button") forSegmentAtIndex:0];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"previewPhoto"]) {
        // Retrieving selection
        NSIndexPath *selectedPath = [self.tableView indexPathForSelectedRow];
        // Retrieving image to preview
        CurrentUser *user = userService.getCurrentUser;
        CALImage *image;
        if(selectedPath.row == 0) {
            image = user.mainImage;
        } else {
            image = [user.otherImages objectAtIndex:selectedPath.row-1];
        }
        PhotoPreviewViewController *controller = [segue destinationViewController];
        [controller setCurrentImage:image];
        [controller setImaged:user];
    }
}

- (void)imageRemoved:(CALImage *)image {
    operationInProgress = NO;
}
- (void)imageReordered:(CALImage *)image {
    operationInProgress = NO;
}

- (void)imageRemovalFailed:(CALImage *)image message:(NSString *)message {
    NSLog(@"TODO: Implement removal failure");
}
@end
