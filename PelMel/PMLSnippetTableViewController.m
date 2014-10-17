//
//  PMLSnippetTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 30/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLSnippetTableViewController.h"
#import "PMLInfoProvider.h"
#import "TogaytherService.h"
#import "PMLDataManager.h"
#import "KIImagePager.h"
#import "ThumbTableViewController.h"
#import "PMLSubNavigationController.h"
#import "PMLSnippetTableViewCell.h"
#import "PMLGalleryTableViewCell.h"
#import "PMLCountersTableViewCell.h"
#import "PMLImageTableViewCell.h"
#import "PMLTextTableViewCell.h"
#import "PMLDescriptionTableViewCell.h"
#import "PMLActivityTableViewCell.h"
#import "PMLPlaceTypesThumbProvider.h"
#import "PMLTagsTableViewCell.h"
#import "PMLThumbsTableViewCell.h"
#import "MessageViewController.h"


#define BACKGROUND_COLOR UIColorFromRGB(0x272a2e)

#define kPMLSectionsCount 8

#define kPMLSectionSnippet 0
#define kPMLSectionOvSummary 1
#define kPMLSectionOvAddress 2
#define kPMLSectionOvHours 3
#define kPMLSectionOvHappyHours 4
#define kPMLSectionOvDesc 5
#define kPMLSectionOvTags 6
#define kPMLSectionActivity 7

#define kPMLSnippetRows 3
#define kPMLRowSnippet 0
#define kPMLRowGallery 1
#define kPMLRowCounters 2
#define kPMLRowThumbPreview 3
#define kPMLRowSnippetId @"snippet"
#define kPMLRowGalleryId @"gallery"
#define kPMLRowCountersId @"counters"
#define kPMLRowThumbPreviewId @"thumbsPreview"
#define kPMLHeightSnippet 101
#define kPMLHeightGallery 240
#define kPMLHeightCounters 97
#define kPMLHeightThumbPreview 60
#define kPMLThumbSize @42


#define kPMLOvSummaryRows 3
#define kPMLRowOvSeparator 0
#define kPMLRowOvImage 1
#define kPMLRowOvTitle 2
#define kPMLRowOvSeparatorId @"separator"
#define kPMLRowOvImageId @"image"
#define kPMLRowOvTitleId @"text"
#define kPMLRowTextId @"text"
#define kPMLHeightOvSeparator 31
#define kPMLHeightOvImage 106
#define kPMLHeightOvTitle 30


#define kPMLOvAddressRows 1
#define kPMLRowOvAddressId @"text"
#define kPMLHeightOvAddressRows 20

#define kPMLOvHoursRows 1
#define kPMLRowHoursTitleId @"hoursTitle"
#define kPMLHeightOvHoursRows 20
#define kPMLHeightOvHoursTitleRows 40
#define kPMLHeaderHeightOvHours 20

#define kPMLOvDescRows 1
#define kPMLRowOvDesc 0
#define kPMLRowDescId @"description"
#define kPMLHeightOvDesc 280
#define kPMLRowDescFontSize 14
#define kPMLHeaderHeightOvDesc 25

#define kPMLOvTagsRows 1
#define kPMLRowOvTagsId @"tags"
#define kPMLHeightOvTagsRows 44
#define kPMLOvTagWidth 60
#define kPMLOvTagInnerWidth 44

#define kPMLRowActivityId @"activity"
#define kPMLHeightActivityRows 60

typedef enum {
    ThumbPreviewModeNone,
    ThumbPreviewModeLikes,
    ThumbPreviewModeCheckins
} ThumbPreviewMode;
@interface PMLSnippetTableViewController ()

@end

@implementation PMLSnippetTableViewController {
    
    // Inner controller for thumb listview
    ThumbTableViewController *_thumbController;
    ThumbTableViewController *_counterThumbController;
    
    // Providers
    NSObject<PMLInfoProvider> *_infoProvider;
    NSObject<MasterProvider> *_masterProvider;
    NSMutableArray *_observedProperties;
    
    // Cells
    PMLSnippetTableViewCell *_snippetCell;
    PMLGalleryTableViewCell *_galleryCell;
    PMLCountersTableViewCell *_countersCell;
    CAGradientLayer *_countersGradient;
    CAGradientLayer *_countersPreviewGradient;
    
    // Gallery
    BOOL _galleryFullscreen;
    CGRect _galleryFrame;
    
    
    // Services
    UIService *_uiService;
    ImageService *_imageService;
    DataService *_dataService;
    SettingsService *_settingsService;
    ConversionService *_conversionService;
    
    // Dragging
    BOOL _parentDragging;
    CGPoint _dragStartPoint;
    CGFloat _descHeight;
    
    // Actions states
    BOOL _readMore;
    NSInteger _readMoreSize;
    ThumbPreviewMode _thumbPreviewMode;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    _descHeight = 0;
    _uiService = TogaytherService.uiService;
    _imageService = TogaytherService.imageService;
    _dataService = TogaytherService.dataService;
    _settingsService = [TogaytherService settingsService];
    _conversionService = [TogaytherService getConversionService];
    _observedProperties = [[NSMutableArray alloc] init];
    _infoProvider = [_uiService infoProviderFor:_snippetItem];
    _thumbPreviewMode = ThumbPreviewModeNone;
    
    self.tableView.backgroundColor = UIColorFromRGB(0x272a2e);
    self.tableView.opaque=YES;
    self.tableView.separatorColor = UIColorFromRGB(0x272a2e);

    [self.tableView.panGestureRecognizer addTarget:self action:@selector(tableViewPanned:)];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    // Getting data
    [_dataService registerDataListener:self];
    if(_snippetItem != nil) {
        [_dataService getOverviewData:_snippetItem];
    }
    if([_snippetItem isKindOfClass:[Place class]]) {
        if(_snippetItem.lat!=0 && _snippetItem.lng!=0 && _snippetItem.key!=nil) {
            [((MapViewController*)self.parentMenuController.rootViewController) selectCALObject:_snippetItem];
        }
    }
}
-(void)viewDidDisappear:(BOOL)animated {
    [_dataService unregisterDataListener:self];
}
- (void)willMoveToParentViewController:(UIViewController *)parent {
    if(parent == nil) {
        // Unregistering data listener
        [_dataService unregisterDataListener:self];
        
        [self clearObservers];
        // No more editing
        _snippetItem.editing=NO;
        

    }
}
- (void)clearObservers {
    // Unregistering any observed property
    for(NSString *observedProperty in _observedProperties) {
        // Removing us as observer
        [_snippetItem removeObserver:self forKeyPath:observedProperty];
    }
    // Purging props
    [_observedProperties removeAllObjects];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kPMLSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(_snippetItem != nil) {
        switch(section) {
            case kPMLSectionSnippet:
                return kPMLSnippetRows + (_thumbPreviewMode == ThumbPreviewModeNone ? 0 : 1);
            case kPMLSectionOvSummary:
                return kPMLOvSummaryRows;
            case kPMLSectionOvAddress:
                return [_infoProvider addressLine1] != nil ? kPMLOvAddressRows : 0;
            case kPMLSectionOvHours:
                if([_infoProvider respondsToSelector:@selector(specialFor:ofType:)]) {
                    Special *special = [_conversionService specialFor:_snippetItem ofType:SPECIAL_TYPE_OPENING];
                    if(special != nil) {
                        return 1+[[special.descriptionText componentsSeparatedByString:@"/"] count];
                    }
                }
                return 0;
            case kPMLSectionOvHappyHours:
                if([_infoProvider respondsToSelector:@selector(specialFor:ofType:)]) {
                    Special *special = [_conversionService specialFor:_snippetItem ofType:SPECIAL_TYPE_HAPPY];
                    if(special != nil) {
                        return 1+[[special.descriptionText componentsSeparatedByString:@"/"] count];
                    }
                }
                return 0;
            case kPMLSectionOvDesc:
                return _snippetItem.miniDesc.length > 0 ? kPMLOvDescRows : 0;
            case kPMLSectionOvTags: {
                double rows = (double)_snippetItem.tags.count / ((double)tableView.bounds.size.width / (double)kPMLOvTagWidth);
                return (int)ceil(rows);
            }
        }
    } else {
        switch(section) {
            case kPMLSectionSnippet:
                return 1;
            case kPMLSectionActivity:
                return [[_infoProvider activities] count];
        }
        
    }
    return 0;
}

-(NSString*)rowIdForIndexPath:(NSIndexPath*)indexPath {
    switch(indexPath.section) {
        case kPMLSectionSnippet:
            switch(indexPath.row) {
                case kPMLRowSnippet:
                    return kPMLRowSnippetId;
                case kPMLRowGallery:
                    return kPMLRowGalleryId;
                case kPMLRowCounters:
                    return kPMLRowCountersId;
                case kPMLRowThumbPreview:
                    return kPMLRowThumbPreviewId;
                default:
                    return nil;
            }
            break;
        case kPMLSectionOvSummary:
            switch(indexPath.row) {
                case kPMLRowOvSeparator:
                    return kPMLRowOvSeparatorId;
                case kPMLRowOvImage:
                    return kPMLRowOvImageId;
                case kPMLRowOvTitle:
                    return kPMLRowOvTitleId;
                default:
                    return kPMLRowTextId;
            }
            break;
        case kPMLSectionOvAddress:
            return kPMLRowOvAddressId;
        case kPMLSectionOvHours:
            return indexPath.row == 0 ? kPMLRowHoursTitleId : kPMLRowTextId;
        case kPMLSectionOvHappyHours:
            return indexPath.row == 0 ? kPMLRowHoursTitleId : kPMLRowTextId;
        case kPMLSectionOvDesc:
            return kPMLRowDescId;
        case kPMLSectionOvTags:
            return kPMLRowOvTagsId;
        case kPMLSectionActivity:
            return kPMLRowActivityId;
    }
    return nil;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseCellId = [self rowIdForIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseCellId forIndexPath:indexPath];
    cell.backgroundColor = BACKGROUND_COLOR;
    // Configure the cell...
    switch(indexPath.section) {
        case kPMLSectionSnippet:
            switch(indexPath.row) {
                case kPMLRowSnippet:
                    [self configureRowSnippet:(PMLSnippetTableViewCell*)cell];
                    break;
                case kPMLRowGallery:
                    [self configureRowGallery:(PMLGalleryTableViewCell*)cell];
                    break;
                case kPMLRowCounters:
                    [self configureRowCounters:(PMLCountersTableViewCell*)cell];
                    break;
                case kPMLRowThumbPreview:
                    [self configureRowThumbPreview:(PMLThumbsTableViewCell*)cell];
                    break;
                default:
                    return nil;
            }
            break;
        case kPMLSectionOvSummary:
            switch(indexPath.row) {
                case kPMLRowOvImage:
                    [self configureRowOvImage:(PMLImageTableViewCell*)cell];
                    break;
                case kPMLRowOvTitle:
                    [self configureRowOvTitle:(PMLTextTableViewCell*)cell];
                    break;
                default:
                    break;
            }
            break;
        case kPMLSectionOvAddress:
            [self configureRowOvAddress:(PMLTextTableViewCell*)cell atIndex:indexPath.row];
            break;
        case kPMLSectionOvHours:
            if(indexPath.row==0) {
                [self configureRowOvHoursTitle:(PMLTextTableViewCell*)cell];
            } else {
                [self configureRowOvHours:(PMLTextTableViewCell*)cell atIndex:indexPath.row-1 forType:SPECIAL_TYPE_OPENING];
            }
            break;
        case kPMLSectionOvHappyHours:
            if(indexPath.row==0) {
                [self configureRowOvHappyHoursTitle:(PMLTextTableViewCell*)cell];
            } else {
                [self configureRowOvHours:(PMLTextTableViewCell*)cell atIndex:indexPath.row-1 forType:SPECIAL_TYPE_HAPPY];
            }
            break;
        case kPMLSectionOvDesc:
            [self configureRowOvDesc:(PMLDescriptionTableViewCell*)cell];
            break;
        case kPMLSectionOvTags:
            [self configureRowTags:(PMLTagsTableViewCell*)cell atIndex:indexPath.row];
            break;
        case kPMLSectionActivity:
            [self configureRowActivity:(PMLActivityTableViewCell*)cell atIndex:indexPath.row];
            break;
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kPMLSectionSnippet:
            switch(indexPath.row) {
                case kPMLRowSnippet:
                    return kPMLHeightSnippet;
                case kPMLRowGallery:
                    if(!_galleryFullscreen) {
                        return tableView.bounds.size.width-(48*2);
                    } else {
                        return tableView.bounds.size.height;
                    }
                case kPMLRowCounters:
                    return kPMLHeightCounters;
                case kPMLRowThumbPreview:
                    return kPMLHeightThumbPreview+10;
                default:
                    break;
            }
            break;
        case kPMLSectionOvSummary:
            switch(indexPath.row) {
                case kPMLRowOvSeparator:
                    return kPMLHeightOvSeparator;
                case kPMLRowOvImage:
                    return kPMLHeightOvImage;
                case kPMLRowOvTitle:
                    return kPMLHeightOvTitle;
                default:
                    break;
            }
            break;
        case kPMLSectionOvAddress:
            return kPMLHeightOvAddressRows;
        case kPMLSectionOvHours:
            return indexPath.row == 0 ? kPMLHeightOvHoursTitleRows : kPMLHeightOvHoursRows;
        case kPMLSectionOvHappyHours:
            return indexPath.row == 0 ? kPMLHeightOvHoursTitleRows : kPMLHeightOvHoursRows;
        case kPMLSectionOvDesc: {
            if(_readMoreSize == 0) {
                UIFont *font = [UIFont fontWithName:PML_FONT_DEFAULT size:kPMLRowDescFontSize];
                UILabel *label = [[UILabel alloc] init];
                label.font = font;
                label.text = _infoProvider.descriptionText;
                label.numberOfLines = 0;
                label.lineBreakMode = NSLineBreakByWordWrapping;
                CGSize maxSize = CGSizeMake(tableView.frame.size.width-40, MAXFLOAT);
                CGSize expectedSize = [label sizeThatFits:maxSize];
                _readMoreSize = expectedSize.height;
            }

            _descHeight = MAX(_readMoreSize,30);
            if(!_readMore) {
                _descHeight = MIN(_descHeight,kPMLHeightOvDesc);
            }
            _descHeight = 25+_descHeight+30+25;

            return _descHeight;
        }
        case kPMLSectionOvTags:
            return 44;
        case kPMLSectionActivity:
            return kPMLHeightActivityRows;
    }
    return 44;

}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(_snippetItem != nil) {
        switch (section) {
            case kPMLSectionOvDesc:
                return kPMLHeaderHeightOvDesc;
            case kPMLSectionOvHours:
                return kPMLHeaderHeightOvHours;
            default:
                break;
        }
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    for(UIView *childView in view.subviews) {
        childView.backgroundColor = UIColorFromRGB(0x272a2e);
    }
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Cell configuration
- (void)configureRowSnippet:(PMLSnippetTableViewCell*)cell {
    _snippetCell = cell;
    // Title
//    NSLog(@"%d places",(int)_dataService.modelHolder.places.count);
//    for(Place *p in _dataService.modelHolder.places) {
//        NSLog(@" -> %@", p.key );
//    }
    cell.titleLabel.text = _infoProvider.title;
    cell.titleDecorationImage.image = _infoProvider.titleIcon;
    
    // Tappable label for name edition
    if(_snippetItem.key == nil) {
        cell.titleLabel.userInteractionEnabled=YES;
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelTapped:)];
        [cell.titleLabel addGestureRecognizer:tapRecognizer];
    }
    
    // Loading thumb
    [_imageService load:_snippetItem.mainImage to:cell.thumbView thumb:YES];
    
    // Configuring thumb subtitle
    cell.thumbSubtitleLabel.text = _infoProvider.thumbSubtitleText;
    cell.thumbSubtitleLabel.textColor = _infoProvider.thumbSubtitleColor;
    cell.thumbSubtitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:11];

    
    // Image touch events
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [cell.thumbView addGestureRecognizer:tapRecognizer];
    cell.thumbView.userInteractionEnabled=YES;
    
    // No subtitle
    cell.subtitleLabel.text = nil;
    
    // Observing address
    if([_snippetItem isKindOfClass:[Place class]]) {
        Place *place = (Place*)_snippetItem;
        if(place.address != nil) {
            cell.subtitleLabel.text = place.address;
        }
        [self.snippetItem addObserver:self forKeyPath:@"address" options:   NSKeyValueObservingOptionNew context:NULL];
        [_observedProperties addObject:@"address"];
    }
    
    // Setting opening hours badge
    if([_infoProvider respondsToSelector:@selector(hasSnippetRightSection)] && [_infoProvider hasSnippetRightSection]) {
        cell.hoursBadgeView.hidden=NO;
        cell.hoursBadgeTitleLabel.text = [_infoProvider snippetRightTitleText];
        cell.hoursBadgeSubtitleLabel.text = [_infoProvider snippetRightSubtitleText];
        cell.hoursBadgeTitleLabel.textColor = [_infoProvider snippetRightColor];
        cell.hoursBadgeSubtitleLabel.textColor = [_infoProvider snippetRightColor];
        cell.hoursBadgeImageView.image = [_infoProvider snippetRightIcon];

        if([_infoProvider respondsToSelector:@selector(snippetRightActionTapped:)]) {
            UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rightSnippetTapped:)];
            [cell.hoursBadgeView addGestureRecognizer:recognizer];
            cell.hoursBadgeView.userInteractionEnabled=YES;
        }
    } else {
        cell.hoursBadgeView.hidden = YES;
    }
    if(cell.hoursBadgeTitleLabel.text == nil && cell.hoursBadgeSubtitleLabel.text == nil) {
        cell.hoursBadgeImageView.frame = cell.hoursBadgeView.bounds;
    }
    
    // Setting colored line
    UIColor *color = _infoProvider.color;
    cell.colorLineView.backgroundColor = color;
    // Thumb border
    cell.thumbView.layer.borderColor = color.CGColor;
    // Subtitle
    cell.subtitleLabel.textColor = color;
    
    // Fonts
    cell.hoursBadgeTitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:10];
    cell.hoursBadgeSubtitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:8];
    cell.titleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:16];
    
    // Configuring thumb controller
    if(cell.peopleView.subviews.count == 0) {
        // Initializing thumb controller
        _thumbController = (ThumbTableViewController*)[_uiService instantiateViewController:SB_ID_THUMBS_CONTROLLER];
        [self addChildViewController:_thumbController];
        [cell.peopleView addSubview:_thumbController.view];
        [_thumbController didMoveToParentViewController:self];
    }
    [_thumbController.tableView reloadData];
    
    
}

-(void)configureRowCounters:(PMLCountersTableViewCell*)cell {
    _countersCell = cell;
    // Counters
    cell.likesCounterLabel.text = [NSString stringWithFormat:@"%d",_infoProvider.likesCount];
    cell.checkinsCounterLabel.text = [NSString stringWithFormat:@"%d",_infoProvider.checkinsCount];
    cell.commentsCounterLabel.text = [NSString stringWithFormat:@"%d",_infoProvider.reviewsCount];
    // Adding tap gestures
    UITapGestureRecognizer *likesTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(likesCounterTapped:)];
    [cell.likesContainerView addGestureRecognizer:likesTapRecognizer];
    cell.likesContainerView.userInteractionEnabled=YES;

    UITapGestureRecognizer *checkinsTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(checkinsCounterTapped:)];
    [cell.checkinsContainerView addGestureRecognizer:checkinsTapRecognizer];
    cell.checkinsContainerView.userInteractionEnabled=YES;
    
    UITapGestureRecognizer *commentsTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(commentsCounterTapped:)];
    [cell.commentsContainerView addGestureRecognizer:commentsTapRecognizer];
    cell.commentsContainerView.userInteractionEnabled=YES;
    
    // Gradient on counters view
    if(_countersGradient == nil) {
        _countersGradient = [CAGradientLayer layer];
        
        [cell.countersView.layer insertSublayer:_countersGradient atIndex:0];
        cell.countersView.layer.masksToBounds=YES;
    }
    
    // Setting gradient length base on selected tab (if any)
    [self updateGradient:cell];
    
    // Setting up fonts
    cell.likesCounterLabel.font = [UIFont fontWithName:PML_FONT_SARI_MEDIUM size:22];
    cell.checkinsCounterLabel.font = [UIFont fontWithName:PML_FONT_SARI_MEDIUM size:22];
    cell.commentsCounterLabel.font = [UIFont fontWithName:PML_FONT_SARI_MEDIUM size:22];
    cell.likesTitleLabel.font = [UIFont fontWithName:PML_FONT_SARI_MEDIUM size:17];
    cell.checkinsTitleLabel.font = [UIFont fontWithName:PML_FONT_SARI_MEDIUM size:17];
    cell.commentsTitleLabel.font = [UIFont fontWithName:PML_FONT_SARI_MEDIUM size:17];
}
/**
 * Updates the gradient of the counters view based on the selected tab
 */
-(void)updateGradient:(PMLCountersTableViewCell*)cell {
    CGRect countersFrame = cell.countersView.bounds;
    CGRect likeFrame = cell.likesContainerView.frame;
    CGRect checkinFrame = cell.checkinsContainerView.frame;
    switch(_thumbPreviewMode) {
        case ThumbPreviewModeLikes:
            _countersGradient.colors = [NSArray arrayWithObjects:(id)UIColorFromRGB(0x6c6d71).CGColor, (id)UIColorFromRGB(0x33363e).CGColor, nil];
            _countersGradient.frame = CGRectMake(likeFrame.origin.x, countersFrame.origin.y, likeFrame.size.width, countersFrame.size.height+kPMLHeightThumbPreview);
            cell.likesContainerView.alpha=1;
            cell.checkinsContainerView.alpha=0.4;
            cell.commentsContainerView.alpha=0.4;
            cell.bottomMargin.constant=-5;
            break;
        case ThumbPreviewModeCheckins:
            _countersGradient.colors = [NSArray arrayWithObjects:(id)UIColorFromRGB(0x6c6d71).CGColor, (id)UIColorFromRGB(0x33363e).CGColor, nil];
            _countersGradient.frame = CGRectMake(checkinFrame.origin.x, countersFrame.origin.y, checkinFrame.size.width, countersFrame.size.height+kPMLHeightThumbPreview);
            cell.likesContainerView.alpha=0.4;
            cell.checkinsContainerView.alpha=1;
            cell.commentsContainerView.alpha=0.4;
            cell.bottomMargin.constant=-5;
            break;
        default:
            _countersGradient.colors = [NSArray arrayWithObjects:(id)UIColorFromRGB(0x636466).CGColor, (id)UIColorFromRGB(0x2c2d2f).CGColor, nil];
            _countersGradient.frame = cell.countersView.bounds;
            cell.likesContainerView.alpha=1;
            cell.checkinsContainerView.alpha=1;
            cell.commentsContainerView.alpha=1;
            cell.bottomMargin.constant=0;
            break;
    }

}
-(void)configureRowThumbPreview:(PMLThumbsTableViewCell*)cell {
    NSObject<ThumbsPreviewProvider> *provider = nil;
    switch(_thumbPreviewMode) {
        case ThumbPreviewModeLikes: {
            provider = [_infoProvider likesThumbsProvider];
            break;
        }
        case ThumbPreviewModeCheckins: {
            provider = [_infoProvider checkinsThumbsProvider];
            break;
        }
        default:
            break;
    }
//    if(_countersPreviewGradient == nil) {
        _countersPreviewGradient = [CAGradientLayer layer];
        _countersPreviewGradient.colors = [NSArray arrayWithObjects:(id)UIColorFromRGB(0x4b4d53).CGColor, (id)UIColorFromRGB(0x33363e).CGColor, nil];
        [cell.thumbsContainer.layer insertSublayer:_countersPreviewGradient atIndex:0];
        cell.thumbsContainer.layer.masksToBounds=YES;
        CGRect frame = cell.thumbsContainer.bounds;
        _countersPreviewGradient.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
//    }
    if(provider != nil) {
        if(_counterThumbController != nil) {
            [_counterThumbController willMoveToParentViewController:nil];
            [_counterThumbController.view removeFromSuperview];
            [_counterThumbController removeFromParentViewController];
        } else {
            _counterThumbController = (ThumbTableViewController*)[_uiService instantiateViewController:SB_ID_THUMBS_CONTROLLER];
        }
            [self addChildViewController:_counterThumbController];
            [cell.thumbsContainer addSubview:_counterThumbController.view];
            [_counterThumbController didMoveToParentViewController:self];
            _counterThumbController.size = kPMLThumbSize;
//        } else {
//            //        }
        _counterThumbController.view.frame = cell.thumbsContainer.bounds;
        [_counterThumbController setThumbProvider:provider];
    }
    
}

-(void)configureRowGallery:(PMLGalleryTableViewCell*)cell {
    _galleryCell = cell;
    cell.galleryView.delegate=self;
    cell.galleryView.dataSource=self;
}
-(void)configureRowOvImage:(PMLImageTableViewCell*)cell {
    [_imageService load:_snippetItem.mainImage to:cell.cellImageView thumb:NO];
    cell.cellImageView.layer.borderColor = [[_uiService colorForObject:_snippetItem] CGColor];
}
-(void)configureRowOvTitle:(PMLTextTableViewCell*)cell {
    cell.cellTextLabel.text = [[_infoProvider title] uppercaseString];
    cell.cellTextLabel.font = [UIFont fontWithName:PML_FONT_SARI_EXTRABOLD size:17];
    cell.cellTextLabel.textColor = [_uiService colorForObject:_snippetItem];
}
-(void)configureRowOvAddress:(PMLTextTableViewCell*)cell atIndex:(NSInteger)row {
    cell.cellTextLabel.text = [_infoProvider addressLine1];
    cell.cellTextLabel.font = [UIFont fontWithName:PML_FONT_SARI_MEDIUM size:16];
    cell.cellTextLabel.textColor = [UIColor whiteColor];
}
-(void)configureRowOvHours:(PMLTextTableViewCell*)cell atIndex:(NSInteger)row forType:(NSString*)specialType {
    
    Special *special = [_conversionService specialFor:_snippetItem ofType:specialType];
    if(special != nil) {
        cell.cellTextLabel.text = [[special.descriptionText componentsSeparatedByString:@"/"] objectAtIndex:row];
        cell.cellTextLabel.font = [UIFont fontWithName:PML_FONT_SARI_MEDIUM size:16];
        cell.cellTextLabel.textColor = UIColorFromRGB(0xababac);
    } else {
        cell.cellTextLabel.text = nil;
    }
}
-(void)configureRowOvHoursTitle:(PMLTextTableViewCell*)cell {
    cell.cellTextLabel.font = [UIFont fontWithName:PML_FONT_SARI_MEDIUM size:18];
    cell.cellTextLabel.textColor = UIColorFromRGB(0x72ff00);
    cell.cellTextLabel.text = NSLocalizedString(@"snippet.title.hours", @"Opening hours");
}
-(void)configureRowOvHappyHoursTitle:(PMLTextTableViewCell*)cell {
    cell.cellTextLabel.font = [UIFont fontWithName:PML_FONT_SARI_MEDIUM size:18];
    cell.cellTextLabel.textColor = UIColorFromRGB(0xfff600);
    cell.cellTextLabel.text = NSLocalizedString(@"snippet.title.happyhours", @"Happy hours");
}

-(void)configureRowOvDesc:(PMLDescriptionTableViewCell*)cell {
    cell.descriptionLabel.text = [_infoProvider descriptionText];
    cell.descriptionLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:kPMLRowDescFontSize];
    CGFloat rowHeight = [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:kPMLRowOvDesc inSection:kPMLSectionOvDesc]];
    cell.descriptionLabel.numberOfLines = rowHeight/kPMLRowDescFontSize;
    [cell.readMoreButton addTarget:self action:@selector(readMoreTapped:) forControlEvents:UIControlEventTouchUpInside];
//    cell.descriptionLabel.backgroundColor = [UIColor redColor];
}
-(void)configureRowActivity:(PMLActivityTableViewCell*)cell atIndex:(NSInteger)row {
    Activity *activity = [[_infoProvider activities] objectAtIndex:row];
//    NSError *error;
//    NSAttributedString *attributedStr = [[NSAttributedString alloc] initWithData:[[activity.message stringByAppendingString:@"\n" ] dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)} documentAttributes:nil error:&error];
    
    
    cell.activityTitleLabel.text = [self stringByStrippingHTML:activity.message];
    cell.activitySubtitleLabel.text = [_uiService delayStringFrom:activity.activityDate];
    if(activity.user.mainImage!=nil) {
        [_imageService load:activity.user.mainImage to:cell.activityThumbImageView thumb:YES];
    } else {
        [_imageService load:activity.activityObject.mainImage to:cell.activityThumbImageView thumb:YES];
    }
    cell.activityThumbImageView.layer.borderColor = [[_uiService colorForObject:activity.user] CGColor];
    
    // Fonts
    cell.activityTitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:14];
    cell.activitySubtitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:12];
}
-(void) configureRowTags:(PMLTagsTableViewCell*)cell atIndex:(NSInteger)index {
    NSInteger tagsPerRow = (int) (self.tableView.bounds.size.width / kPMLOvTagWidth);
    NSInteger startTagIndex = index*tagsPerRow;
    NSInteger endTagIndex = MIN(_snippetItem.tags.count,startTagIndex+tagsPerRow);
    
    // Clearing every pre-existing image view
    for(UIImageView *view in cell.tagViews) {
        view.image = nil;
    }
    // Creating all required image views if needed
    NSInteger tagsCount = endTagIndex - startTagIndex;
    if(cell.tagViews.count < tagsCount) {
        for(NSInteger i = cell.tagViews.count ; i < tagsCount ; i++ ) {
            UIImageView *imageView = [[UIImageView alloc] init];
            [cell addSubview:imageView];
            [cell.tagViews addObject:imageView];
        }
    }

    // Computing margins
    int margin = (self.tableView.bounds.size.width-tagsCount*kPMLOvTagInnerWidth)/(tagsCount*2);
    for(NSInteger i = startTagIndex ; i < endTagIndex ; i++) {
        NSString *tagStr = [_snippetItem.tags objectAtIndex:i];
        UIImage *tagIcon = [_imageService getTagImage:tagStr];
        UIImageView *tagImageView = [cell.tagViews objectAtIndex:i-startTagIndex];
        tagImageView.image = tagIcon;
        tagImageView.frame = CGRectMake((i-startTagIndex)*(kPMLOvTagInnerWidth+2*margin)+margin, 0, kPMLOvTagInnerWidth, kPMLOvTagInnerWidth);
    }
    
}
-(NSString *) stringByStrippingHTML:(NSString*)html {
    NSRange r;
    NSString *s = [NSString stringWithString:html];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
}
#pragma mark - Actions callback
- (void) labelTapped:(UIGestureRecognizer*)sender {
    _snippetItem.editing = YES;
    [self updateTitleEdition];
//    self.titleTextField.placeholder = NSLocalizedString(@"edit.title",@"Enter a name");
//    self.titleTextField.hidden=NO;
//    self.titleTextField.delegate = self;
//    [self.titleTextField becomeFirstResponder];
    
}
-(void)imageTapped:(UITapGestureRecognizer*)sender {
    if(_snippetItem.mainImage==nil) {
        // Prompting for upload
        [self.parentMenuController.dataManager promptUserForPhotoUploadOn:_snippetItem];
    } else {
        [self.parentMenuController openCurrentSnippet];
        [self toggleFullscreenGallery];
    }
}
-(void)readMoreTapped:(id)sender {
    _readMore = !_readMore;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kPMLRowOvDesc inSection:kPMLSectionOvDesc]] withRowAnimation:UITableViewRowAnimationAutomatic];
}
-(void)rightSnippetTapped:(UIGestureRecognizer*)sender {
    if([_infoProvider respondsToSelector:@selector(snippetRightActionTapped:)]) {
        [_infoProvider snippetRightActionTapped:self];
    }
}

-(void)likesCounterTapped:(UIGestureRecognizer*)sender {
    [self counterTappedForMode:ThumbPreviewModeLikes];
}
-(void)checkinsCounterTapped:(UIGestureRecognizer*)sender {
    [self counterTappedForMode:ThumbPreviewModeCheckins];
}

-(void)counterTappedForMode:(ThumbPreviewMode)mode {
    BOOL insert = _thumbPreviewMode == ThumbPreviewModeNone;
    _thumbPreviewMode = (_thumbPreviewMode == mode) ? ThumbPreviewModeNone : mode;
    if(insert && _thumbPreviewMode == mode) {
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kPMLRowThumbPreview inSection:kPMLSectionSnippet]] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (_thumbPreviewMode == ThumbPreviewModeNone) {
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kPMLRowThumbPreview inSection:kPMLSectionSnippet]] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kPMLRowThumbPreview inSection:kPMLSectionSnippet]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self updateGradient:_countersCell];
    
}
-(void)commentsCounterTapped:(UIGestureRecognizer*)sender {
    MessageViewController *msgController = (MessageViewController*)[_uiService instantiateViewController:SB_ID_MESSAGES];
    msgController.withObject = _snippetItem;
//    if(self.subNavigationController) {
//        [self.subNavigationController pushViewController:msgController animated:YES];
//    } else {
    [self.navigationController pushViewController:msgController animated:YES];
//    }
}
#pragma mark - PMLImageGalleryDelegate
- (void)imageTappedAtIndex:(int)index image:(CALImage *)image {
    [self toggleFullscreenGallery];
}
-(void)toggleFullscreenGallery {

    _galleryFullscreen = !_galleryFullscreen;
    NSLog(@"Animating Fullscreen = %@",_galleryFullscreen ? @"FULLSCREEN" : @"normal");

    if(_galleryCell.leftConstraint.constant == 0) {
        _galleryCell.leftConstraint.constant = 48;
        _galleryCell.rightConstraint.constant = 48;
    } else {
        _galleryCell.leftConstraint.constant = 0;
        _galleryCell.rightConstraint.constant = 0;
    }
    
    NSIndexPath *galleryPath = [NSIndexPath indexPathForRow:kPMLRowGallery inSection:kPMLSectionSnippet];
    [self.tableView scrollToRowAtIndexPath:galleryPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    [_galleryCell.galleryView updateFrames];
}
#pragma mark - KIImagePagerDatasource
- (NSArray *)arrayWithImages {
    NSMutableArray *_images = [[NSMutableArray alloc] init ];
    if(_snippetItem.mainImage!=nil) {
        [_images addObject:_snippetItem.mainImage];
        for(CALImage *img in _snippetItem.otherImages) {
            [_images addObject:img];
        }
    }
    return _images;
}
- (UIViewContentMode)contentModeForImage:(NSUInteger)image {
    return UIViewContentModeScaleAspectFit;
}
-(UIImage *)placeHolderImageForImagePager {
    return [CALImage getDefaultImage];
}
- (void)imagePager:(KIImagePager *)imagePager didSelectImageAtIndex:(NSUInteger)index {
    [self imageTappedAtIndex:(int)index image:nil];
}
#pragma mark - ThumbPreviewActionDelegate
- (void)thumbsTableView:(ThumbTableViewController*)controller thumbTapped:(int)thumbIndex {
    id selectedItem = [[controller.thumbProvider items] objectAtIndex:thumbIndex];
    if(_snippetItem.editing) {
        if([selectedItem isKindOfClass:[PlaceType class]]) {
            // Assigning new place
            ((Place*)_snippetItem).placeType = ((PlaceType*)selectedItem).code;
            // Refreshing table
            [controller.tableView reloadData];
        }
    } else {
        PMLSnippetTableViewController *childSnippet = (PMLSnippetTableViewController*)[TogaytherService.uiService instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
        childSnippet.snippetItem = selectedItem;
        if(self.subNavigationController != nil) {
            [self.subNavigationController pushViewController:childSnippet animated:YES];
        } else {
            [self.navigationController pushViewController:childSnippet animated:YES];
        }
    }
}

#pragma mark - PMLDataListener
- (void)didLoadOverviewData:(CALObject *)object {
    if([_snippetItem.key isEqualToString:object.key]) {
        // Building provider
        _thumbController.thumbProvider = _infoProvider.thumbsProvider;
        [self configureThumbController];
        [self.tableView reloadData];
        
        // Updating gallery
        [_galleryCell.galleryView reloadData];
        
        // Selecting on map
        if([object isKindOfClass:[Place class]] && object.lat!=0 && object.lng!=0) {
            [((MapViewController*)self.parentMenuController.rootViewController) selectCALObject:_snippetItem];
        }
    }
}
- (void) configureThumbController {
    _thumbController.actionDelegate = self;
    _thumbController.view.frame = _snippetCell.peopleView.bounds;
    _thumbController.size = @30;
}
- (void)setSnippetItem:(CALObject *)snippetItem {
    [self clearObservers];
    _snippetItem = snippetItem;
    _infoProvider = [TogaytherService.uiService infoProviderFor:_snippetItem];
    _masterProvider = [TogaytherService.uiService masterProviderFor:_snippetItem];
    
    
    // Listening to edit mode
    [self.snippetItem addObserver:self forKeyPath:@"editing" options:NSKeyValueObservingOptionNew context:NULL];
    [_observedProperties addObject:@"editing"];
    [self.snippetItem addObserver:self forKeyPath:@"editingDesc" options:NSKeyValueObservingOptionNew context:NULL];
    [_observedProperties addObject:@"editingDesc"];
}
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // Retrieving text
    NSString *inputText = textField.text;
    
    // Removing current input
    textField.hidden=YES;
    textField.text = nil;
    
    // Calling back
    if([_snippetItem isKindOfClass:[Place class]]) {
        // Only doing something if we have a valid text
        NSString *title = [inputText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if(title.length>0) {
            _snippetItem.editing=NO;
            ((Place*)_snippetItem).title = inputText;
            _snippetCell.titleLabel.text = inputText;

            self.editing=NO;
        }
    }
    [_snippetCell.titleTextField resignFirstResponder];
    [self.tableView reloadData];
    return YES;
}
#pragma mark - UITextViewDelegate
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    [self descriptionDone:textView];
    return YES;
}
-(void)descriptionDone:(id)sender {
    UITextView *textView = _snippetCell.descriptionTextView;
    NSString *inputText = textView.text;
    
    // Removing current input
    textView.hidden=YES;
    _snippetCell.peopleView.hidden=NO;
    _snippetCell.hoursBadgeView.hidden=NO;
    _snippetCell.descriptionTextViewButton.hidden=YES;
    textView.text = nil;

    [_snippetCell.descriptionTextViewButton removeTarget:self action:@selector(descriptionDone:) forControlEvents:UIControlEventTouchUpInside];
    
    // Only doing something if we have a valid text
    NSString *desc = [inputText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if(desc.length>0) {
        _snippetItem.editingDesc=NO;
        _snippetItem.miniDesc = inputText;
        
        self.editing=NO;
    }
    [_snippetCell.titleTextField resignFirstResponder];
    [self.tableView reloadData];

}
#pragma mark - KVO Observing implementation
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([@"addess" isEqualToString:keyPath]) {
        if([object isKindOfClass:[Place class]]) {
            _snippetCell.subtitleLabel.text = ((Place*)object).address;
        }
    } else if([@"editing" isEqualToString:keyPath] || [@"editingDesc" isEqualToString:keyPath]) {
        [self updateTitleEdition];
    }
}
-(void)updateTitleEdition {
    if(_snippetItem.editing) {
        _snippetCell.titleTextField.delegate = self;
        _snippetCell.titleTextField.hidden=NO;
        _snippetCell.titleTextField.text = _infoProvider.title;
        _snippetCell.titleTextField.placeholder = NSLocalizedString(@"snippet.edit.titlePlaceholder", @"Enter a name");
        [_snippetCell.titleTextField becomeFirstResponder];
        
        // Toggling place type selection
        if([_snippetItem isKindOfClass:[Place class]]) {
            // Initializing default type
            PlaceType *selectedPlaceType = [_settingsService defaultPlaceType];
            // Getting place type for current place
            NSString *typeCode =((Place*)_snippetItem).placeType;
            if(typeCode != nil) {
                selectedPlaceType = [_settingsService getPlaceType:typeCode];
            }
            // Initilizing with this selection
            PMLPlaceTypesThumbProvider *provider = [[PMLPlaceTypesThumbProvider alloc] initWithPlace:(Place*)_snippetItem];
            // Registering new provider
            _thumbController.thumbProvider = provider;
            [self configureThumbController];
        }
    } else if(_snippetItem.editingDesc) {
        _snippetCell.descriptionTextView.delegate = self;
        _snippetCell.descriptionTextView.hidden=NO;
        _snippetCell.descriptionTextView.font = [UIFont fontWithName:PML_FONT_DEFAULT size:14];
        _snippetCell.descriptionTextView.text = _infoProvider.descriptionText;
        _snippetCell.descriptionTextViewButton.hidden=NO;
        _snippetCell.descriptionTextViewButton.titleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:17];
        _snippetCell.peopleView.hidden=YES;
        _snippetCell.hoursBadgeView.hidden=YES;
        [_snippetCell.descriptionTextViewButton addTarget:self action:@selector(descriptionDone:) forControlEvents:UIControlEventTouchUpInside];
        [_snippetCell.descriptionTextView becomeFirstResponder];

    } else {
        _snippetCell.titleTextField.hidden=YES;
        _snippetCell.titleLabel.text = _infoProvider.title;
        
        // Restoring thumbs provider
        _thumbController.thumbProvider = _infoProvider.thumbsProvider;
    }
}
#pragma mark - Dragging control & scroll view
- (void)tableViewPanned:(UIPanGestureRecognizer*)recognizer {
    if(self.navigationController.childViewControllers.count>1) {
        return;
    }
    switch(recognizer.state) {
        case UIGestureRecognizerStateBegan:
            if (abs(self.tableView.contentOffset.y) < kPMLHeightSnippet) {
                CGPoint location = [recognizer locationInView:self.parentMenuController.view];
                location.x = CGRectGetMidX(self.parentMenuController.view.bounds);
                _dragStartPoint=location;
                _dragStartPoint.x = MAXFLOAT;
                [self.parentMenuController dragSnippet:location velocity:CGPointMake(0, 0) state:UIGestureRecognizerStateBegan];
                _parentDragging = YES;

            } else {
                NSLog(@"Top=%d",(int)self.tableView.contentOffset.y);
            }
            break;
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
            if(_parentDragging) {
                CGPoint scrollVelocity = [recognizer velocityInView:self.parentMenuController.view];
                CGPoint location = [recognizer locationInView:self.parentMenuController.view];
                
                // Flag to check drag direction
                if(_dragStartPoint.x == MAXFLOAT) {
                    CGFloat delta = location.y - _dragStartPoint.y;
                    BOOL snippetOpened = self.parentMenuController.snippetFullyOpened;
                    if((delta>0 && !snippetOpened) || (delta < 0 && snippetOpened)) {
                        _parentDragging = NO;
                        [self.parentMenuController dragSnippet:_dragStartPoint velocity:CGPointMake(0, 0) state:UIGestureRecognizerStateEnded];
                    }
                    _dragStartPoint.x=0;
                }
                if(_parentDragging) {
                    [self.parentMenuController dragSnippet:location velocity:scrollVelocity state:recognizer.state];
                    self.tableView.contentOffset = CGPointMake(0,0);
                }
            }
            break;
        default:
            break;
    }
    if(recognizer.state == UIGestureRecognizerStateEnded) {
        _parentDragging = NO;
    }
}
-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if(_parentDragging) {
        *targetContentOffset = CGPointMake(0,0);
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(_snippetItem.editing) {
        self.tableView.contentOffset = CGPointMake(0, 0);
    }
}

@end
