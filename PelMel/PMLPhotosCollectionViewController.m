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
@property (retain,nonatomic) NSArray *objects;
@property (nonatomic) BOOL loading;
@property (nonatomic) NSInteger widthFit;
@end

@implementation PMLPhotosCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [TogaytherService applyCommonLookAndFeel:self];
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mnuIconClose"] style:UIBarButtonItemStylePlain target:self action:@selector(closeMenu:)];
    self.title = NSLocalizedString(@"activity.title.photoGrid", @"activity.title.photoGrid");
    self.collectionView.backgroundColor = UIColorFromRGB(0x272a2e);
    self.collectionView.opaque=YES;
    
    // Service initialization
    _imageService   = [TogaytherService imageService];
    _messageService = [TogaytherService getMessageService];
    _uiService      = [TogaytherService uiService];
    
    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:@"PMLPhotoView" bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"PMLPhotoLoadingView" bundle:nil] forCellWithReuseIdentifier:kCellIdLoading];
    
    // Starting load
    _loading = YES;
    [self.provider photoControllerStartContentLoad:self];
    
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
    self.navigationController.navigationBar.translucent=NO;
    [self.collectionView reloadData];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return kSectionsCount;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch(section) {
        case kSectionPhotos:
            return _objects.count;
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
    NSObject *activity = [self.objects objectAtIndex:row];
    CALImage *image = [self.provider photoController:self imageForObject:activity];//activity.extraImage;
    if(image.fullImage != nil) {
        cell.photoImageView.image = image.fullImage;
    } else {
        cell.photoImageView.image = [CALImage getDefaultThumb];
        //[_imageService imageOrPlaceholderFor:activity.activityObject allowAdditions:NO];
        
        // Resetting thumb image if not HD
        [_imageService load:image to:cell.photoImageView thumb:!self.loadFullImage];
    }
    cell.subtitleLabel.text = [self.provider photoController:self labelForObject:activity]; //[_uiService delayStringFrom:activity.activityDate];
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
        NSObject *activity = [_objects objectAtIndex:indexPath.row];
        [self.provider photoController:self objectTapped:activity];
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
- (void)updateData {
    _loading = NO;
    self.objects = [self.provider allObjects];
    [self.collectionView reloadData];
}

#pragma mark - Action callback
-(void)closeMenu:(id)sender {
    if([self.provider respondsToSelector:@selector(photoControllerDidTapCloseMenu:)]) {
        [self.provider photoControllerDidTapCloseMenu:self];
    }

}

@end
