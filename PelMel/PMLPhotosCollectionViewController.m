//
//  PMLPhotosCollectionViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 06/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLPhotosCollectionViewController.h"
#import "PMLPhotoView.h"
#import "TogaytherService.h"
#import "PMLSnippetTableViewController.h"

#define kSectionsCount 2
#define kSectionPhotos 0
#define kSectionLoading 1
#define kCellIdLoading @"loading"

@interface PMLPhotosCollectionViewController ()
@property (weak,nonatomic) ImageService *imageService;
@property (weak,nonatomic) MessageService *messageService;
@property (weak,nonatomic) UIService *uiService;
@property (retain,nonatomic) NSArray *activities;
@property (nonatomic) BOOL loading;
@property (nonatomic) NSInteger widthFit;
@end

@implementation PMLPhotosCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [TogaytherService applyCommonLookAndFeel:self];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mnuIconClose"] style:UIBarButtonItemStylePlain target:self action:@selector(closeMenu:)];
    self.title = NSLocalizedString(@"activity.title.photoGrid", @"activity.title.photoGrid");
    self.collectionView.backgroundColor = UIColorFromRGB(0x272a2e);
    self.collectionView.opaque=YES;
    
    // Service initialization
    _imageService   = [TogaytherService imageService];
    _messageService = [TogaytherService getMessageService];
    _uiService      = [TogaytherService uiService];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
//    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"PMLPhotoView" bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"PMLPhotoLoadingView" bundle:nil] forCellWithReuseIdentifier:kCellIdLoading];
    
    _loading = YES;
    [_messageService getNearbyActivitiesFor:self.activityStat.activityType hd:YES callback:self];
    
    // Computing fit width for cells no larger than 130px
    float width = MAXFLOAT;
    int i = 1;
    while(width>130) {
        width = ((float)self.view.bounds.size.width-(i+1)*2) / (float)i;
        i++;
    }
    _widthFit = (NSInteger)width;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillAppear:(BOOL)animated {
    [TogaytherService applyCommonLookAndFeel:self];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return kSectionsCount;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch(section) {
        case kSectionPhotos:
            return _activities.count;
        case kSectionLoading:
            return _loading ? 1 : 0;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:(indexPath.section == kSectionLoading ? kCellIdLoading : reuseIdentifier) forIndexPath:indexPath];
    
    switch(indexPath.section) {
        case kSectionPhotos:
            [self configureCellPhoto:(PMLPhotoView*)cell forRow:indexPath.row];
            break;
        case kSectionLoading:
            break;
    }

    // Configure the cell
    
    return cell;
}

-(void)configureCellPhoto:(PMLPhotoView*)cell forRow:(NSInteger)row {
    Activity *activity = [self.activities objectAtIndex:row];
    CALImage *image = activity.extraImage;
    if(image.fullImage != nil) {
        cell.photoImageView.image = image.fullImage;
    } else {
        cell.photoImageView.image = [CALImage getDefaultThumb];
        //[_imageService imageOrPlaceholderFor:activity.activityObject allowAdditions:NO];
        
        // Resetting thumb image if not HD
        [_imageService load:image to:cell.photoImageView thumb:YES];
    }
    cell.subtitleLabel.text = [_uiService delayStringFrom:activity.activityDate];
}
#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == kSectionPhotos) {
        Activity *activity = [_activities objectAtIndex:indexPath.row];
        PMLSnippetTableViewController *snippetController = (PMLSnippetTableViewController*)[_uiService instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
        snippetController.snippetItem = activity.activityObject;
//        [snippetController menuManager:self.parentMenuController snippetWillOpen:YES];
        [self.navigationController pushViewController:snippetController animated:YES];
//        [_uiService presentController:snippetController];
    }
}
/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(_widthFit, _widthFit);
}
#pragma mark - ActivitiesCallback

-(void)activityFetched:(NSArray *)activities {
    self.activities = activities;
    _loading = NO;
    [self.collectionView reloadData];
}
-(void)activityFetchFailed:(NSString *)errorMessage {
    [_uiService alertError];
}

#pragma mark - Action callback
-(void)closeMenu:(id)sender {
    [self.parentMenuController dismissControllerSnippet];
}

@end
