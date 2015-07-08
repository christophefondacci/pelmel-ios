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
#import "PMLThumbHeaderView.h"

#define kSectionsCount 1
#define kSectionLoading 0
#define kCellIdLoading @"loading"

@interface PMLPhotosCollectionViewController ()
@property (weak,nonatomic) ImageService *imageService;
@property (weak,nonatomic) MessageService *messageService;
@property (weak,nonatomic) UIService *uiService;
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
    self.title = [self.provider title];
    self.collectionView.backgroundColor = UIColorFromRGB(0x272a2e);
    self.collectionView.opaque=YES;
    
    // Service initialization
    _imageService   = [TogaytherService imageService];
    _messageService = [TogaytherService getMessageService];
    _uiService      = [TogaytherService uiService];
    
    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:@"PMLPhotoView" bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"PMLPhotoLoadingView" bundle:nil] forCellWithReuseIdentifier:kCellIdLoading];
    [self.collectionView registerNib:[UINib nibWithNibName:@"PMLThumbHeaderView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    
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
    
    // Collection view layout
//    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
//    layout.scrollDirection=UICollectionViewScrollDirectionVertical;
//    layout.itemSize = CGSizeMake(_widthFit, _widthFit);
//    layout.minimumInteritemSpacing = 0;
//    layout.minimumLineSpacing=0;
//    
//    [self.collectionView setCollectionViewLayout:layout];
//    self.collectionView.alwaysBounceVertical = YES;
    

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
- (void)dealloc {
    if([self.provider respondsToSelector:@selector(controllerWillDealloc:)]) {
        [self.provider controllerWillDealloc:self];
    }
}
#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return kSectionsCount + [self.provider sectionsCount];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch(section) {
        case kSectionLoading:
            return _loading ? 1 : 0;
        default: {
            NSArray *objects = [self.provider objectsForSection:section-1];
            return objects.count;
        }
            
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:(indexPath.section == kSectionLoading ? kCellIdLoading : reuseIdentifier) forIndexPath:indexPath];
    
    switch(indexPath.section) {
        case kSectionLoading:
            break;
        default:
            [self configureCellPhoto:(PMLPhotoView*)cell forRow:indexPath.row inSection:indexPath.section-1];
            break;

    }

    // Configure the cell
    
    return cell;
}

-(void)configureCellPhoto:(PMLPhotoView*)cell forRow:(NSInteger)row inSection:(NSInteger)section {
    NSObject *activity = [[self.provider objectsForSection:section] objectAtIndex:row];
    CALImage *image = [self.provider photoController:self imageForObject:activity inSection:section];//activity.extraImage;
    if(image.fullImage != nil) {
        cell.photoImageView.image = image.fullImage;
    } else {
        cell.photoImageView.image = [CALImage getDefaultThumb];
        
        // If provider defines a default image we use it
        if([self.provider respondsToSelector:@selector(defaultImageFor:)]) {
            
            // Getting image
            UIImage *defaultImage=[self.provider defaultImageFor:activity];
            
            // Only using it if not null (so that returning nil from provider will use defaultThumb)
            if(defaultImage != nil) {
                cell.photoImageView.image = defaultImage;
            }
        }
        
        
        // Resetting thumb image if not HD
        [_imageService load:image to:cell.photoImageView thumb:!self.loadFullImage];
    }
    cell.subtitleLabel.text = [self.provider photoController:self labelForObject:activity inSection:section];
    cell.photoImageView.layer.borderWidth=0;
    if([self.provider respondsToSelector:@selector(borderColorFor:)]) {
        UIColor *color = [self.provider borderColorFor:activity];
        if(color!=nil) {
            cell.photoImageView.layer.borderWidth=1;
            cell.photoImageView.layer.borderColor = color.CGColor;
        }
    }
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
    if(indexPath.section != kSectionLoading) {
        NSObject *activity = [[self.provider objectsForSection:indexPath.section-1] objectAtIndex:indexPath.row];
        [self.provider photoController:self objectTapped:activity inSection:indexPath.section-1];
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
-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    NSAssert([kind isEqualToString:UICollectionElementKindSectionHeader], @"Unexpected supplementary element kind");
    UICollectionReusableView* cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                        withReuseIdentifier:@"header"
                                                                               forIndexPath:indexPath];
    
    NSAssert([cell isKindOfClass:[PMLThumbHeaderView class]], @"Unexpected class for header cell");
    
    PMLThumbHeaderView* headerView = (PMLThumbHeaderView*) cell;
    
    
    
    headerView.titleLabel.text = [self.provider labelForSection:indexPath.section-1];
    headerView.titleIcon.image = [self.provider iconForSection:indexPath.section-1];//[UIImage imageNamed:@"chatButtonAddPhoto"];
    //            headerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    headerView.backgroundColor = [UIColor clearColor]; //[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    // custom content
    
    return cell;

}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(_widthFit, _widthFit);
}
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if(section != kSectionLoading && [self numberOfSectionsInCollectionView:collectionView]>2) {
        
        BOOL canAddToSection = NO;
        if([self.provider respondsToSelector:@selector(canAddToSection:)])      {
            canAddToSection = [self.provider canAddToSection:section-1];
        }
        if(([self collectionView:self.collectionView numberOfItemsInSection:section]>0 || canAddToSection) && [self.provider respondsToSelector:@selector(labelForSection:)]) {
            if([self.provider labelForSection:section-1]!=nil) {
                return CGSizeMake(self.collectionView.bounds.size.width, 39);
            }
        }
    }
    return CGSizeMake(0, 0);
}
- (void)updateData {
    _loading = NO;
    [self.collectionView reloadData];
}

#pragma mark - Action callback
-(void)closeMenu:(id)sender {
    if([self.provider respondsToSelector:@selector(photoControllerDidTapCloseMenu:)]) {
        [self.provider photoControllerDidTapCloseMenu:self];
    }

}

@end
