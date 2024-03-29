//
//  PMLThumbCollectionViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 03/03/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLThumbCollectionViewController.h"
#import "PMLThumbView.h"
#import "TogaytherService.h"
#import "PMLHorizontalFlowLayout.h"
#import "StickyHeaderFlowLayout.h"
#import "PMLThumbsPreviewProvider.h"
#import "PMLThumbHeaderView.h"

#define kSectionsCount 1

@interface PMLThumbCollectionViewController ()

@end

@implementation PMLThumbCollectionViewController {
    ImageService *_imageService;
}

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Service init
    _imageService = [TogaytherService imageService];
    
    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:@"PMLThumbView" bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"PMLThumbHeaderView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    
    // Do any additional setup after loading the view.
    if(_size==nil) {
        _size = [NSNumber numberWithInt:49];
    }

    // Preparing layout
    UICollectionViewFlowLayout *layout = nil;
    if([self.thumbProvider respondsToSelector:@selector(labelForType:)]) {
        layout = [[StickyHeaderFlowLayout alloc] init];
        layout.headerReferenceSize = CGSizeMake(150, 19);
        layout.sectionInset = UIEdgeInsetsMake(24,-150+15,0, 0);
    } else {
        layout = [[UICollectionViewFlowLayout alloc] init];
        layout.headerReferenceSize = CGSizeMake(0, 0);
    }
    layout.scrollDirection=UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(_size.floatValue, _size.floatValue);
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing=0;

    [self.collectionView setCollectionViewLayout:layout];
    self.collectionView.alwaysBounceHorizontal = YES;
    
    
    // Appearance
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    
    // Bounce
    if(self.hasShowMore) {
        self.collectionView.bounces = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [self.collectionView.collectionViewLayout invalidateLayout];
    return [[self.thumbProvider thumbTypes] count];
}

- (NSInteger)maxItems {
    if(!self.hasShowMore) {
        return MAXFLOAT;
    } else {
        // TODO: Check on iPad / 6Plus if more is at the right position
//        [self.view layoutIfNeeded];
        CGRect bounds = self.view.bounds;
        return (bounds.size.width / self.size.intValue);
    }
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    PMLThumbType type = [self.thumbProvider thumbTypeAtIndex:section];
    NSInteger count = [[self.thumbProvider itemsForType:type] count ];
//    NSInteger itemsCount = count>0 ? MAX(count,2) : count;
    NSInteger itemsCount = MIN(count,[self maxItems]);
    return _hasShowMore ? itemsCount : count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PMLThumbView *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    

    // Configure the cell...
    cell.backgroundColor = [UIColor clearColor];
    PMLThumbType type = [self.thumbProvider thumbTypeAtIndex:indexPath.section];
    cell.backgroundColor = [UIColor clearColor];
    
    // Checking dummy cell
    if([self.thumbProvider respondsToSelector:@selector(objectAtIndex:forType:)]) {
        CALObject *obj = [self.thumbProvider objectAtIndex:indexPath.row forType:type];
        if(obj == nil) {
            cell.hidden=YES;
            cell.thumbImage.image = nil;
            cell.thumbImage.layer.borderWidth=0;
            cell.titleLabel.text = nil;
            // Just in case, passing through image service to make sure everything cancelled
            [_imageService checkCurrentImageViewTask:cell.thumbImage url:nil];
//            [_imageService load:nil to:cell.thumbImage thumb:YES];
            return cell;
        }
    }
    cell.hidden=NO;
    cell.thumbImage.layer.borderWidth=1;
    // Configuring background for selected cells
    if([self.thumbProvider respondsToSelector:@selector(isSelected:forType:)]) {
        if([self.thumbProvider isSelected:indexPath.row forType:type]) {
            cell.backgroundColor = UIColorFromRGB(0xf48020);
            cell.layer.cornerRadius =4;
            cell.clipsToBounds = YES;
        }
    }
    

    // Configuring image
    BOOL isShowMore = self.hasShowMore && (indexPath.row == [self maxItems]-1);

    // Setting rounded corners (or not)
    BOOL rounded= YES;
    if([self.thumbProvider respondsToSelector:@selector(rounded)]) {
        rounded= [self.thumbProvider rounded];
    }
    if(rounded) {
        [cell layoutIfNeeded];
        cell.thumbImage.layer.cornerRadius = 0;
        if([self.thumbProvider respondsToSelector:@selector(objectAtIndex:forType:)]) {
            CALObject *obj = [self.thumbProvider objectAtIndex:indexPath.row forType:type];
            if([obj isKindOfClass:[User class]]) {
                cell.thumbImage.layer.cornerRadius = cell.thumbImage.bounds.size.width/2;
            }
        }

    } else {
        cell.thumbImage.layer.cornerRadius = 0;
        cell.thumbImage.layer.borderWidth=0;
    }
    

    
    // Configuring bottom right decorator
    if(!isShowMore) {
        cell.titleLabel.text = [self.thumbProvider titleAtIndex:indexPath.row forType:type];
        cell.showMoreLabel.text = nil;
        // Configuring decorator
        if([self.thumbProvider respondsToSelector:@selector(colorFor:forType:)]) {
            cell.thumbImage.layer.borderColor = [self.thumbProvider colorFor:indexPath.row forType:type].CGColor;
        } else {
            cell.thumbImage.layer.borderColor = [UIColor whiteColor] .CGColor;
        }
        cell.thumbImage.image= [CALImage getDefaultThumb]; //image.thumbImage;
        CALImage *image = [self.thumbProvider imageAtIndex:indexPath.row forType:type];
        [_imageService load:image to:cell.thumbImage thumb:YES];
    } else {
        cell.titleLabel.text = nil;
        cell.showMoreLabel.text = NSLocalizedString(@"snippet.showMore", @"Show more");
        cell.thumbImage.image=nil;
        [_imageService checkCurrentImageViewTask:cell.thumbImage url:nil];
        cell.thumbImage.backgroundColor = BACKGROUND_COLOR;
        cell.thumbImage.layer.borderColor = [[UIColor whiteColor ] colorWithAlphaComponent:0.5f].CGColor; //FromRGB(0x70ff01).CGColor;
        cell.showMoreLabel.textColor =[UIColor whiteColor];
    }
    
    // Custom font size if supported
    if([self.thumbProvider respondsToSelector:@selector(fontSize)]) {
        NSInteger fontSize = [self.thumbProvider fontSize];
        cell.titleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:fontSize];
    }
    cell.titleLabel.minimumScaleFactor=0.8;

    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    PMLThumbType type = [self.thumbProvider thumbTypeAtIndex:indexPath.section];
    if([self.thumbProvider respondsToSelector:@selector(labelForType:)]) {
        NSString *label = [self.thumbProvider labelForType:type];
        UIImage *image = [self.thumbProvider imageForType:type];
//        if(label != nil) {
            NSAssert([kind isEqualToString:UICollectionElementKindSectionHeader], @"Unexpected supplementary element kind");
            UICollectionReusableView* cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                                withReuseIdentifier:@"header"
                                                                                       forIndexPath:indexPath];
            
            NSAssert([cell isKindOfClass:[PMLThumbHeaderView class]], @"Unexpected class for header cell");
            
            PMLThumbHeaderView* headerView = (PMLThumbHeaderView*) cell;
            
            
            
            headerView.titleLabel.text = label;
            headerView.titleIcon.image = image;
//            headerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
            headerView.backgroundColor = [UIColor clearColor]; //[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
            // custom content
            
            return cell;
//        }
    }
    return nil;
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
    if(self.actionDelegate != nil) {
        PMLThumbType type = [self.thumbProvider thumbTypeAtIndex:indexPath.section];
        NSArray *items = [self.thumbProvider itemsForType:type];
        // We check that user did not tap our "extra spacing cell"
        if(items.count>indexPath.row) {
            // Firing action
            if(self.hasShowMore && (indexPath.row == [self maxItems]-1)) {
                type = PMLThumbShowMore;
            }
            [self.actionDelegate thumbsTableView:self thumbTapped:(int)indexPath.row forThumbType:type];
        }
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
- (void)setThumbProvider:(id<PMLThumbsPreviewProvider>)thumbProvider {
    BOOL changed = _thumbProvider != nil;
    _thumbProvider = thumbProvider;
    if(changed && _thumbProvider != nil) {
        [self.collectionView reloadData];
    }
}
@end
