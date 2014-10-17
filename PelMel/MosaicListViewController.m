//
//  MenListViewController.m
//  nativeTest
//
//  Created by Christophe Fondacci on 02/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "MosaicListViewController.h"
#import "GalleryService.h"
#import "User.h"
#import "UITableGridImageCell.h"
#import "providers/MosaicUserProvider.h"
#import "providers/MosaicPlaceProvider.h"
#import "DetailViewController.h"

@interface MosaicListViewController ()

@end

@implementation MosaicListViewController {
    GalleryService *galleryService;
    ImageService *imageService;
    UIPanGestureRecognizer *_panRecognizer;
    NSMutableArray *_providers;
    NSMutableDictionary *buttonsProvidersMap;
}
@synthesize tableView = _tableView;
@synthesize objects = _objects;

- (void) setObjects:(NSArray *)objects {
    [_providers removeAllObjects];
    
    // We build a list of providers from our objects list
    for(CALObject *object in objects) {
        id<MosaicObjectProvider> provider;
        
        // Initializing provider
        if([object isKindOfClass:[User class]]) {
            provider = [[MosaicUserProvider alloc] initWithUser:(User*)object];
        } else if([object isKindOfClass:[Place class]]) {
            provider = [[MosaicPlaceProvider alloc] initWithPlace:(Place*)object];
        }
        
        // Adding the built provider
        if(provider != nil) {
            [_providers addObject:provider];
        }
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configure];
    }
    return self;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self configure];
    }
    return self;
}
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
       [self configure];
    }
    return self;
}
- (void)configure {
    _providers = [[NSMutableArray alloc] init];

}
- (void)viewDidLoad
{
    [super viewDidLoad];

    imageService = [[ImageService alloc] init];
    buttonsProvidersMap = [[NSMutableDictionary alloc] init];
    galleryService = [[GalleryService alloc] initWithController:self imaged:_parentObject initialImage:_parentObject.mainImage panEnabled:NO tapEnabled:NO];
    [galleryService setInitialContentMode:UIViewContentModeScaleAspectFit];
    _tableView.backgroundView = [galleryService getTopView];
//    _tableView.backgroundColor = [UIColor whiteColor];

    [self setTitle:_viewTitle];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (void)viewDidAppear:(BOOL)animated {
    [galleryService viewVisible];
}
- (void)viewDidUnload
{
    buttonsProvidersMap = nil;
    imageService = nil;
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (IBAction)imagePan:(UIPanGestureRecognizer *)panrecognizer {
    [galleryService imagePan:panrecognizer];
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
    // Return the number of rows in the section.
    NSInteger count = _providers.count /3;
    if(_providers.count % 3 != 0) {
        count++;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"imageRow";
    UITableGridImageCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    NSInteger startIndex = indexPath.row*3;

    NSMutableArray *imageViews = [[NSMutableArray alloc] initWithCapacity:3];
    NSMutableArray *labels = [[NSMutableArray alloc] initWithCapacity:3];
    NSMutableArray *onlines = [[NSMutableArray alloc] initWithCapacity:3];
    NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:3];
    
    [imageViews addObject:cell.image1];
    [imageViews addObject:cell.image2];
    [imageViews addObject:cell.image3];
    [labels addObject:cell.label1];
    [labels addObject:cell.label2];
    [labels addObject:cell.label3];
    [onlines addObject:cell.online1];
    [onlines addObject:cell.online2];
    [onlines addObject:cell.online3];
    [buttons addObject:cell.tapButton1];
    [buttons addObject:cell.tapButton2];
    [buttons addObject:cell.tapButton3];
    
    for(int i = 0 ; i < 3 ; i++) {
        // Getting current image view
        UIImageView *imgView = [imageViews objectAtIndex:i];
        UILabel *label = [labels objectAtIndex:i];
        UIImageView *online = [onlines objectAtIndex:i];
        UIButton *button = [buttons objectAtIndex:i];
        
        int index = i + (int)startIndex;
        // Filling user's images
        if(_providers.count > index) {
            id<MosaicObjectProvider> provider = [_providers objectAtIndex:index];
            UIImage *thumbImage = [[provider getImage] getThumbImage];
            
            // Setting up thumb image (or default)
            if(thumbImage != nil) {
                imgView.image = thumbImage;
            } else {
                imgView.image = [CALImage getDefaultThumb];
            }
            
            // Setting up cell label
            label.text = [provider getLabel];
            
            // Setting up the online 
            if([provider isOnline]) {
                online.image = [imageService getOnlineImage:YES];
            } else {
                online.image = nil;
            }
            
            // Registering button action
            [button addTarget:self action:@selector(thumbTapped:) forControlEvents:UIControlEventTouchUpInside];
            [buttonsProvidersMap setObject:provider forKey:[self buildKey:button]];
        } else {
            imgView.image = nil;
            label.text = nil;
            online.image = nil;
        }
    }
    
    // Configure the cell...    
    return cell;
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"showDetail"]) {
        DetailViewController *controller = [segue destinationViewController];
        controller.detailItem = sender;
    }
}
-(NSString*)buildKey:(id)pointer {
    return [[NSString alloc] initWithFormat:@"%p",pointer];
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

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 107;
}

#pragma mark Button callback
-(void)thumbTapped:(id)sender {
    id<MosaicObjectProvider> provider = [buttonsProvidersMap objectForKey:[self buildKey:sender]];
    if(provider != nil) {
        [self performSegueWithIdentifier:@"showDetail" sender:[provider getObject]];
    }
}
@end
