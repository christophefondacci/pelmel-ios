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
#import "PMLImagedTitleTableViewCell.h"
#import "PMLEventTableViewCell.h"
#import "PMLSectionTitleView.h"
#import "PMLAddEventTableViewCell.h"
#import "PMLEventTableViewController.h"
#import "SpringTransitioningDelegate.h"
#import "PMLFakeViewController.h"
#import "PMLPopupActionManager.h"

#define BACKGROUND_COLOR UIColorFromRGB(0x272a2e)

#define kPMLSectionsCount 12

#define kPMLSectionSnippet 0
#define kPMLSectionGallery 1
#define kPMLSectionCounters 2
#define kPMLSectionOvSummary 3
#define kPMLSectionOvAddress 4
#define kPMLSectionOvHours 5
#define kPMLSectionOvHappyHours 6
#define kPMLSectionOvEvents 7
#define kPMLSectionOvDesc 8
#define kPMLSectionOvTags 9
#define kPMLSectionTopPlaces 10
#define kPMLSectionActivity 11

#define kPMLSnippetRows 1
#define kPMLRowSnippet 0

#define kPMLRowGallery 0

#define kPMLRowCounters 0
#define kPMLRowThumbPreview 1
#define kPMLRowSnippetId @"snippet"
#define kPMLRowGalleryId @"gallery"
#define kPMLRowCountersId @"counters"
#define kPMLRowThumbPreviewId @"thumbsPreview"
#define kPMLHeightSnippet 101
#define kPMLHeightGallery 240
#define kPMLHeightCounters 97
#define kPMLHeightThumbPreview 100
#define kPMLHeightThumbPreviewContainer 65
#define kPMLThumbSize @42


#define kPMLOvSummaryRows 3
#define kPMLRowOvSeparator 40
#define kPMLRowOvImage 0
#define kPMLRowOvTitle 1
#define kPMLRowOvPlaceType 2
#define kPMLRowOvSeparatorId @"separator"
#define kPMLRowOvImageId @"image"
#define kPMLRowOvTitleId @"text"
#define kPMLRowOvImagedTitleId @"imagedTitle"
#define kPMLRowTextId @"text"
#define kPMLHeightOvSeparator 31
#define kPMLHeightOvImage 106
#define kPMLHeightOvTitle 30
#define kPMLHeightOvImagedTitle 39


#define kPMLOvAddressRows 1
#define kPMLRowOvAddressId @"text"
#define kPMLHeightOvAddressRows 20

#define kPMLOvHoursRows 1
#define kPMLRowHoursTitleId @"hoursTitle"
#define kPMLHeightOvHoursRows 20
#define kPMLHeightOvHoursTitleRows 40
#define kPMLHeaderHeightOvHours 20

#define kPMLRowEventId @"event"
#define kPMLRowAddEventId @"addEvent"
#define kPMLHeightOvEventRows 144
#define kPMLHeightOvAddEventRow 62


#define kPMLOvDescRows 1
#define kPMLRowOvDesc 0
#define kPMLRowDescId @"description"
#define kPMLHeightOvDesc 280
#define kPMLRowDescFontSize 14
#define kPMLHeaderHeightOvDesc 25

#define kPMLOvTagsRows 1
#define kPMLRowOvTagsId @"tags"
#define kPMLHeightOvTagsRows 60
#define kPMLOvTagWidth 60
#define kPMLOvTagInnerWidth 50
#define kPMLMaxTagsPerRow 5

#define kPMLRowActivityId @"activity"
#define kPMLHeightActivityRows 60


@interface PMLSnippetTableViewController ()
@property (nonatomic, strong) SpringTransitioningDelegate *transitioningDelegate;
@end

@implementation PMLSnippetTableViewController {
    
    // Inner controller for thumb listview
    ThumbTableViewController *_thumbController;
    NSMutableDictionary *_counterThumbControllers; // map of ThumbTableViewController for likes/checkins preview
    
    // Providers
    NSObject<PMLInfoProvider> *_infoProvider;
    NSMutableArray *_observedProperties;
    PMLPopupActionManager *_actionManager;
    
    // Cells
    PMLSnippetTableViewCell *_snippetCell;
    PMLGalleryTableViewCell *_galleryCell;
    PMLCountersTableViewCell *_countersCell;
    CAGradientLayer *_countersGradient;
    NSMutableDictionary *_countersPreviewGradients; // map of CAGradientLayer for likes/checkins gradients
    NSMutableDictionary *_heightsMap;
    
    // Headers
    PMLSectionTitleView *_sectionTitleView;
    PMLSectionTitleView *_sectionSummaryTitleView;
    
    // Gallery
    BOOL _galleryFullscreen;
    CGRect _galleryFrame;
    
    
    // Services
    UIService *_uiService;
    ImageService *_imageService;
    DataService *_dataService;
    SettingsService *_settingsService;
    ConversionService *_conversionService;
    
    // Pre-computing
    NSDictionary *_hoursTypeMap;
    
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
    _actionManager = [[PMLPopupActionManager alloc] initWithObject:_snippetItem menuManager:[self parentMenuController]];
    _infoProvider = [_uiService infoProviderFor:_snippetItem];
    _thumbPreviewMode = ThumbPreviewModeNone;
    _counterThumbControllers = [[NSMutableDictionary alloc] init];
    _heightsMap = [[NSMutableDictionary alloc] init];
    _hoursTypeMap = [[NSMutableDictionary alloc] init];
    self.tableView.backgroundColor = UIColorFromRGB(0x272a2e);
    self.tableView.opaque=YES;
    self.tableView.separatorColor = UIColorFromRGB(0x272a2e);

    [self.tableView.panGestureRecognizer addTarget:self action:@selector(tableViewPanned:)];
    
    // Initializing external table view cells
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLEventTableViewCell" bundle:nil] forCellReuseIdentifier:kPMLRowEventId];
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLAddEventTableViewCell" bundle:nil] forCellReuseIdentifier:kPMLRowAddEventId];
    // Loading header views
    _sectionTitleView = (PMLSectionTitleView*)[_uiService loadView:@"PMLSectionTitleView"];
    _sectionSummaryTitleView = (PMLSectionTitleView*)[_uiService loadView:@"PMLSectionTitleView"];
    
    self.title = [_infoProvider title];
}
- (void)viewWillAppear:(BOOL)animated {
    self.parentMenuController.snippetDelegate = self;

}
- (void)viewDidAppear:(BOOL)animated {
    self.subNavigationController.delegate = self;
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
                return kPMLSnippetRows;
            case kPMLSectionGallery:
                if(_snippetItem.mainImage!=nil) {
                    return 1;
                } else {
                    return 0;
                }
                break;
            case kPMLSectionCounters:
                switch (_thumbPreviewMode) {
                    case ThumbPreviewModeCheckins:
                    case ThumbPreviewModeLikes:
                        return 1+[_infoProvider thumbsRowCountForMode:_thumbPreviewMode];
                    case ThumbPreviewModeNone:
                    default:
                        return 1;
                }
                break;
            case kPMLSectionOvSummary:
                return kPMLOvSummaryRows;
            case kPMLSectionOvAddress:
                return [[_infoProvider addressComponents] count]+1;
            case kPMLSectionOvHours: {
                NSInteger count = [[_hoursTypeMap objectForKey:SPECIAL_TYPE_OPENING] count];
                return count == 0 ? 0 : count+1;
            }
            case kPMLSectionOvHappyHours: {
                NSInteger count = [[_hoursTypeMap objectForKey:SPECIAL_TYPE_HAPPY] count];
                return count == 0 ? 0 : count+1;
            }
            case kPMLSectionOvEvents:
                if([_infoProvider respondsToSelector:@selector(events)]) {
                    return [[_infoProvider events] count]+1;
                }
                break;
            case kPMLSectionOvDesc:
                return [[_infoProvider descriptionText] length]>0 ? kPMLOvDescRows : 0;
            case kPMLSectionOvTags: {
                double rows = (double)_snippetItem.tags.count / (double)kPMLMaxTagsPerRow; //((double)tableView.bounds.size.width / (double)kPMLOvTagWidth);
                return (int)ceil(rows);
            }
        }
    } else {
        switch(section) {
            case kPMLSectionSnippet:
                return 1;
            case kPMLSectionActivity:
                return [[_infoProvider activities] count];
            case kPMLSectionTopPlaces:
                return [[_infoProvider topPlaces] count];
            case kPMLSectionOvEvents:
                if([_infoProvider respondsToSelector:@selector(events)]) {
                    return [[_infoProvider events] count]+1;
                }
                break;
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
            }
            break;
        case kPMLSectionGallery:
            return kPMLRowGalleryId;
        case kPMLSectionCounters:
            switch(indexPath.row) {
                case kPMLRowCounters:
                    return kPMLRowCountersId;
                default:
                    return kPMLRowThumbPreviewId;
            }
            break;
        case kPMLSectionOvEvents:
            if(indexPath.row<[[_infoProvider events] count]) {
                return kPMLRowEventId;
            } else {
                return kPMLRowAddEventId;
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
                case kPMLRowOvPlaceType:
                    return kPMLRowOvImagedTitleId;
                default:
                    return kPMLRowTextId;
            }
            break;
        case kPMLSectionOvAddress:
            if(indexPath.row<[[_infoProvider addressComponents] count]) {
                return kPMLRowOvAddressId;
            } else {
                return kPMLRowOvImagedTitleId;
            }
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
        case kPMLSectionTopPlaces:
            return @"topPlace";

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
            }
            break;
        case kPMLSectionGallery:
            [self configureRowGallery:(PMLGalleryTableViewCell*)cell];
            break;
        case kPMLSectionCounters:
            switch(indexPath.row) {
                case kPMLRowCounters:
                    [self configureRowCounters:(PMLCountersTableViewCell*)cell];
                    break;
                default:
                    [self configureRowThumbPreview:(PMLThumbsTableViewCell*)cell atIndex:indexPath.row];
                    break;
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
                case kPMLRowOvPlaceType:
                    [self configureRowOvPlaceType:(PMLImagedTitleTableViewCell*)cell];
                    break;
                default:
                    break;
            }
            break;
        case kPMLSectionOvAddress:
            if(indexPath.row < [[_infoProvider addressComponents] count]) {
                [self configureRowOvAddress:(PMLTextTableViewCell*)cell atIndex:indexPath.row];
            } else {
                [self configureRowOvCity:(PMLImagedTitleTableViewCell*)cell];
            }
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
        case kPMLSectionOvEvents:
            if(indexPath.row < [[_infoProvider events] count]) {
                [self configureRowOvEvents:(PMLEventTableViewCell*)cell atIndex:indexPath.row];
            } else {
                [self configureRowOvAddEvent:(PMLAddEventTableViewCell*)cell];
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
        case kPMLSectionTopPlaces:
            [self configureRowTopPlace:(PMLActivityTableViewCell*)cell atIndex:indexPath.row];
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
            }
            break;
        case kPMLSectionGallery:
            if(!_galleryFullscreen) {
                // Substract 5 for #44 little truncation
                return (tableView.bounds.size.width-5)-(48*2);
            } else {
                return tableView.bounds.size.height;
            }
            break;
        case kPMLSectionCounters:
            switch(indexPath.row) {
                case kPMLRowCounters:
                    return kPMLHeightCounters;
                default:
                    return kPMLHeightThumbPreview;
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
                case kPMLRowOvPlaceType:
                    return kPMLHeightOvImagedTitle;
                default:
                    break;
            }
            break;
        case kPMLSectionOvAddress:
            if(indexPath.row< [[_infoProvider addressComponents] count]) {
                return kPMLHeightOvAddressRows;
            } else {
                return kPMLHeightOvImagedTitle;
            }
        case kPMLSectionOvHours:
            return indexPath.row == 0 ? kPMLHeightOvHoursTitleRows : kPMLHeightOvHoursRows;
        case kPMLSectionOvHappyHours:
            return indexPath.row == 0 ? kPMLHeightOvHoursTitleRows : kPMLHeightOvHoursRows;
        case kPMLSectionOvEvents:
            if(indexPath.row<[[_infoProvider events] count]) {
                return kPMLHeightOvEventRows;
            } else {
                return kPMLHeightOvAddEventRow;
            }
        case kPMLSectionOvDesc: {
            if(_readMoreSize == 0) {
                PMLDescriptionTableViewCell *descriptionCell = [self.tableView dequeueReusableCellWithIdentifier:kPMLRowDescId];
                descriptionCell.descriptionLabel.text = _infoProvider.descriptionText;
                
                CGSize expectedSize = [descriptionCell.descriptionLabel sizeThatFits:CGSizeMake(descriptionCell.descriptionLabel.bounds.size.width, MAXFLOAT)];
                _readMoreSize = expectedSize.height+1;
            }

            _descHeight = MAX(_readMoreSize,30);
            _descHeight = 26+_descHeight+26;

            return _descHeight;
        }
        case kPMLSectionOvTags:
            return kPMLHeightOvTagsRows;
        case kPMLSectionActivity: {
            Activity *activity = [_infoProvider.activities objectAtIndex:indexPath.row];
            NSString *key = [NSString stringWithFormat:@"%p",activity];
            NSNumber *height = [_heightsMap objectForKey:key];
            if(height == nil) {
                PMLActivityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[self rowIdForIndexPath:indexPath]];
                
                // Auto-height
                cell.activityTitleLabel.text = [self stringByStrippingHTML:activity.message];
                CGSize size = [cell.activityTitleLabel sizeThatFits:CGSizeMake(cell.activityTitleLabel.frame.size.width,FLT_MAX)];
                height = [NSNumber numberWithFloat:size.height+1+41];
                [_heightsMap setObject:height forKey:key];
                
            }
            return height.intValue;
            // +41
        }
            break;
        case kPMLSectionTopPlaces:
            return 80; //kPMLHeightActivityRows;
    }
    return 44;

}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section) {
        case kPMLSectionTopPlaces:
            return NSLocalizedString(@"snippet.header.topPlaces", @"Popular places");
            break;
        case kPMLSectionActivity:
            return NSLocalizedString(@"snippet.header.activities", @"Recent activity");
            break;
    }
    return nil;
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch(section) {
        case kPMLSectionOvEvents:
            // If provider provides a section name for events, we use the section header view
            if([_infoProvider respondsToSelector:@selector(eventsSectionTitle)]) {
                
                // Getting the section title from provider
                NSString *sectionTitle = [_infoProvider eventsSectionTitle];
                if(sectionTitle!=nil) {
                    [_sectionTitleView setTitle:sectionTitle];
                    return _sectionTitleView;
                }
            }
            return nil;
        case kPMLSectionOvSummary:
            [_sectionSummaryTitleView setTitleLocalized:@"snippet.title.summary"];
            return _sectionSummaryTitleView;
    }
    if(section != kPMLSectionOvDesc) {
        return [super tableView:tableView viewForHeaderInSection:section];
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(_snippetItem != nil) {
        switch (section) {
            case kPMLSectionOvDesc:
                return kPMLHeaderHeightOvDesc;
//            case kPMLSectionOvHours:
//                return kPMLHeaderHeightOvHours;
            case kPMLSectionOvEvents:
                if([_infoProvider respondsToSelector:@selector(eventsSectionTitle)]) {
                    if([_infoProvider eventsSectionTitle]!=nil) {
                        return _sectionTitleView.bounds.size.height;
                    }
                }
                return 0;
            case kPMLSectionOvSummary:
                return _sectionSummaryTitleView.bounds.size.height;
            default:
                break;
        }
    } else {
        switch(section) {
            case kPMLSectionTopPlaces:
            case kPMLSectionActivity:
                return 20;
            case kPMLSectionOvEvents:
                if([_infoProvider respondsToSelector:@selector(eventsSectionTitle)]) {
                    if([_infoProvider eventsSectionTitle]!=nil) {
                        return _sectionTitleView.bounds.size.height;
                    }
                }
                return 0;
        }
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    switch(section) {
        case kPMLSectionOvDesc:
            for(UIView *childView in view.subviews) {
                childView.backgroundColor = UIColorFromRGB(0x272a2e);
            }
            break;
        case kPMLSectionActivity:
        case kPMLSectionTopPlaces: {
            UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView*)view;
            headerView.textLabel.textColor = [UIColor whiteColor];
            headerView.textLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:15];
            //                headerView.backgroundView.backgroundColor = UIColorFromRGB(0x2d2f31);
        }
            break;
    }
}
-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == kPMLSectionOvEvents) {
        if([_infoProvider respondsToSelector:@selector(events)]) {
            return YES;
        }
    }
    return indexPath.section == kPMLSectionTopPlaces || indexPath.section == kPMLSectionActivity;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kPMLSectionTopPlaces:
            [self topPlaceTapped:indexPath.row];
            break;
        case kPMLSectionActivity:
            [self activityTapped:indexPath.row];
            break;
        case kPMLSectionOvEvents:
            if(indexPath.row == [[_infoProvider events] count]) {
                [self addEventTapped];
            } else {
                Event *event = [[_infoProvider events] objectAtIndex:indexPath.row];
                [self pushSnippetFor:event];
            }
            break;
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

    if(_infoProvider.title == nil) {
        cell.titleLabel.text = NSLocalizedString(@"snippet.title.notitle", @"Tap to enter a name");
    } else {
        cell.titleLabel.text = _infoProvider.title;
    }
    cell.titleDecorationImage.image = _infoProvider.titleIcon;
    
    // Tappable label for name edition
    if(_snippetItem.key == nil) {
        cell.titleLabel.userInteractionEnabled=YES;
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelTapped:)];
        [cell.titleLabel addGestureRecognizer:tapRecognizer];
    }
    
    // Loading thumb
    CALImage *img = [_infoProvider snippetImage];
    cell.thumbView.contentMode = UIViewContentModeScaleAspectFit;
    [_imageService load:img to:cell.thumbView thumb:YES];
    
    // Configuring thumb subtitle
    cell.thumbSubtitleLabel.text = _infoProvider.thumbSubtitleText;
    cell.thumbSubtitleLabel.textColor = _infoProvider.thumbSubtitleColor;
    cell.thumbSubtitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:11];

    
    // Image touch events, only allowing photo addition if item is defined and has a valid key id
    if(_snippetItem.key != nil) {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
        [cell.thumbView addGestureRecognizer:tapRecognizer];
        cell.thumbView.userInteractionEnabled=YES;
    }
    
    // No subtitle
    cell.subtitleLabel.text = nil;
    
    // Observing address
    if([_snippetItem isKindOfClass:[Place class]]) {
        Place *place = (Place*)_snippetItem;
        if(place.address != nil) {
            cell.subtitleLabel.text = place.address;
        }
        [self.snippetItem addObserver:self forKeyPath:@"address" options:   NSKeyValueObservingOptionNew context:NULL];
        [self.snippetItem addObserver:self forKeyPath:@"mainImage" options:   NSKeyValueObservingOptionNew context:NULL];
        [_observedProperties addObject:@"address"];
        [_observedProperties addObject:@"mainImage"];
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
        
        // If no subtitle, right title will fill all height so it will be centered vertically
        if([_infoProvider snippetRightTitleText]!=nil && [_infoProvider snippetRightSubtitleText] == nil) {
            cell.rightLabelHeight.constant = cell.rightIconHeight.constant;
        }
    } else {
        cell.hoursBadgeView.hidden = YES;
    }
    if(cell.hoursBadgeTitleLabel.text == nil && cell.hoursBadgeSubtitleLabel.text == nil) {
        cell.hoursBadgeImageView.frame = cell.hoursBadgeView.bounds;
    }
    
    // Setting colored line
    UIColor *color = _infoProvider.color;
    cell.colorLineView.backgroundColor = [UIColor clearColor]; // color; // Removing color for grip
    // Thumb border
    cell.thumbView.layer.borderColor = color.CGColor;
    // Subtitle
    cell.subtitleLabel.textColor = color;
    
    // Fonts
    cell.hoursBadgeTitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:10];
    cell.hoursBadgeSubtitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:8];
    cell.titleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:16];
    

    // If custom view then configuring it
    if([_infoProvider respondsToSelector:@selector(configureCustomViewIn:forController:)]) {
        [_infoProvider configureCustomViewIn:cell.peopleView forController:self];
    } else {
        // Configuring thumb controller
        if(cell.peopleView.subviews.count == 0) {
            // Initializing thumb controller
            _thumbController = (ThumbTableViewController*)[_uiService instantiateViewController:SB_ID_THUMBS_CONTROLLER];
            [self addChildViewController:_thumbController];
            [cell.peopleView addSubview:_thumbController.view];
            [_thumbController didMoveToParentViewController:self];
        }
        // Building provider
        _thumbController.thumbProvider = _infoProvider.thumbsProvider;
        [self configureThumbController];
        //    [self.tableView reloadData];
        [_thumbController.tableView reloadData];
    }
    
    // If edit mode we activate it
    if(_snippetItem.editing) {
        [self updateTitleEdition];
    }
    
    // Wiring like action
    if([_infoProvider respondsToSelector:@selector(likeTapped:callback:)]) {
        cell.likeButton.hidden=NO;
        cell.likeButtonSubtitle.hidden=NO;
        PopupAction *action = [_actionManager actionForType:PMLActionTypeLike];
        cell.likeButton.tag=PMLActionTypeLike;
        cell.likeButton.layer.borderColor = [action.color CGColor];
        [cell.likeButton addTarget:self action:@selector(actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        if(_snippetItem.isLiked) {
            cell.likeButtonSubtitle.text=NSLocalizedString(@"action.unlike",@"Unlike");
        } else {
            cell.likeButtonSubtitle.text=NSLocalizedString(@"action.like",@"Like");
        }
    } else {
        cell.likeButton.hidden=YES;
        cell.likeButtonSubtitle.hidden=YES;
    }
    
    
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
    if([_infoProvider respondsToSelector:@selector(commentsCounterTitle)]) {
        cell.commentsTitleLabel.text = [_infoProvider commentsCounterTitle];
    } else {
        cell.commentsTitleLabel.text = NSLocalizedString(@"counters.comments", @"Comments");
    }
    if([_infoProvider respondsToSelector:@selector(checkinsCounterTitle)]) {
        cell.checkinsTitleLabel.text = [_infoProvider checkinsCounterTitle];
    } else {
        cell.checkinsTitleLabel.text = NSLocalizedString(@"counters.checkins", @"Check-ins");
    }
    if([_infoProvider respondsToSelector:@selector(likesCounterTitle)]) {
        cell.likesTitleLabel.text = [_infoProvider likesCounterTitle];
    } else {
        cell.likesTitleLabel.text = NSLocalizedString(@"counters.likes", @"Likes");
    }
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
-(void)configureRowThumbPreview:(PMLThumbsTableViewCell*)cell atIndex:(NSInteger)index {
    NSObject<ThumbsPreviewProvider> *provider = [_infoProvider thumbsProviderFor:_thumbPreviewMode atIndex:index];
    // Setting intro label
    if([provider respondsToSelector:@selector(getLabel)]) {
        cell.introLabel.text = [provider getLabel];
    } else {
        cell.introLabel.text = nil;
    }
    
    // Numeric row key
    NSNumber *key = [NSNumber numberWithInt:(int)index];
    
    // Purging any previous gradient
    CAGradientLayer *countersPreviewGradient = [_countersPreviewGradients objectForKey:key];
    if(countersPreviewGradient != nil) {
        [countersPreviewGradient removeFromSuperlayer];
    }
    // Registering a new one
    countersPreviewGradient = [CAGradientLayer layer];
    [_countersPreviewGradients setObject:countersPreviewGradient forKey:key];
    
    // Setting up
    countersPreviewGradient.colors = [NSArray arrayWithObjects:(id)UIColorFromRGB(0x4b4d53).CGColor, (id)UIColorFromRGB(0x33363e).CGColor, nil];
    [cell.tabView.layer insertSublayer:countersPreviewGradient atIndex:0];
    cell.tabView.layer.masksToBounds=YES;
    [cell.tabView layoutIfNeeded];
    CGRect frame = cell.tabView.bounds;
    countersPreviewGradient.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, kPMLHeightThumbPreview);

    // Thumb controller
    if(provider != nil) {
        ThumbTableViewController *counterThumbController = [_counterThumbControllers objectForKey:key];
        if(counterThumbController != nil) {
            [counterThumbController willMoveToParentViewController:nil];
            [counterThumbController.view removeFromSuperview];
            [counterThumbController removeFromParentViewController];
        } else {
            counterThumbController = (ThumbTableViewController*)[_uiService instantiateViewController:SB_ID_THUMBS_CONTROLLER];
            [_counterThumbControllers setObject:counterThumbController forKey:key];
        }
        [self addChildViewController:counterThumbController];
        [cell.thumbsContainer addSubview:counterThumbController.view];
        [counterThumbController didMoveToParentViewController:self];
        counterThumbController.size = kPMLThumbSize;

        counterThumbController.view.frame = cell.thumbsContainer.bounds;
        counterThumbController.actionDelegate=self;
        [counterThumbController setThumbProvider:provider];
    }
    
}

-(void)configureRowGallery:(PMLGalleryTableViewCell*)cell {
    _galleryCell = cell;
    cell.galleryView.delegate=self;
    cell.galleryView.dataSource=self;
    
    // Wiring add photo action
    PopupAction *action = [_actionManager actionForType:PMLActionTypeAddPhoto];
    cell.addPhotoButton.tag=PMLActionTypeAddPhoto;
    cell.addPhotoButton.layer.borderColor = [action.color CGColor];
    [cell.addPhotoButton addTarget:self action:@selector(actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}
-(void)actionButtonTapped:(UIButton*)source {
    PopupAction *action = [_actionManager actionForType:source.tag];
    if(action.actionCommand!=nil) {
        action.actionCommand();
    }
}
-(void)configureRowOvImage:(PMLImageTableViewCell*)cell {
    CALImage *image = [_imageService imageOrPlaceholderFor:_snippetItem allowAdditions:YES];
    [_imageService load:image to:cell.cellImageView thumb:NO];
    cell.cellImageView.layer.borderColor = [[_uiService colorForObject:_snippetItem] CGColor];
    if(_snippetItem.key!=nil) {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
        [cell.cellImageView addGestureRecognizer:tapRecognizer];
        cell.cellImageView.userInteractionEnabled=YES;
    }
    
}
-(void)configureRowOvTitle:(PMLTextTableViewCell*)cell {
    cell.cellTextLabel.text = [[_infoProvider title] uppercaseString];
    cell.cellTextLabel.font = [UIFont fontWithName:PML_FONT_SARI_EXTRABOLD size:17];
    cell.cellTextLabel.textColor = [UIColor whiteColor]; //[_uiService colorForObject:_snippetItem];
}
-(void)configureRowOvPlaceType:(PMLImagedTitleTableViewCell*)cell {
    cell.titleLabel.text = [_infoProvider itemTypeLabel];
    cell.titleImage.image = [_infoProvider titleIcon];
    CGSize size = [cell.titleLabel sizeThatFits:CGSizeZero];
    cell.widthTitleConstraint.constant = size.width;
    cell.titleLabel.textColor = [_infoProvider color];
}
-(void)configureRowOvAddress:(PMLTextTableViewCell*)cell atIndex:(NSInteger)row {
    NSArray *components = [_infoProvider addressComponents];

    cell.cellTextLabel.text = (NSString*)[components objectAtIndex:row];
    cell.cellTextLabel.font = [UIFont fontWithName:PML_FONT_SARI_MEDIUM size:16];
    cell.cellTextLabel.textColor = [UIColor whiteColor];
}
-(void)configureRowOvCity:(PMLImagedTitleTableViewCell*)cell {
    cell.titleLabel.text = [_infoProvider city];
    cell.titleImage.image = [UIImage imageNamed:@"snpIconCity"];
    CGSize size = [cell.titleLabel sizeThatFits:CGSizeZero];
    cell.widthTitleConstraint.constant = size.width;

}
-(void)configureRowOvHours:(PMLTextTableViewCell*)cell atIndex:(NSInteger)row forType:(NSString*)specialType {
    // Getting the corresponding calendar for specialType / row
    NSArray *calendars = [_hoursTypeMap objectForKey:specialType];
    PMLCalendar *cal = [calendars objectAtIndex:row];
    
    if(cal != nil) {
        // Generating the label
        NSString *calLabel = [_conversionService stringFromCalendar:cal];
    
        cell.cellTextLabel.text = calLabel;
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
-(void)configureRowOvEvents:(PMLEventTableViewCell*)cell atIndex:(NSInteger)row {
    Event *event = [[_infoProvider events] objectAtIndex:row];
    cell.image.image = nil;
    CALImage *calImage = [[TogaytherService imageService] imageOrPlaceholderFor:event allowAdditions:YES];
    [_imageService load:calImage to:cell.image thumb:NO];
    
    cell.titleLabel.text = [event.name uppercaseString];
    cell.dateLabel.text = [_conversionService eventDateLabel:event isStart:YES];
    cell.locationIcon.image = [UIImage imageNamed:@"snpIconMarker"];
    cell.locationLabel.text = [NSString stringWithFormat:@"%@, %@",event.place.title,event.place.cityName];
    if(event.likeCount>0) {
        cell.countLabel.text = [NSString stringWithFormat:NSLocalizedString(@"snippet.event.inUsers","# guys are in"),event.likeCount];
        cell.countIcon.image=[UIImage imageNamed:@"snpIconEvent"];
    } else {
        cell.countIcon.image = nil;
        cell.countLabel.text = nil;
    }
//    cell.backgroundColor = UIColorFromRGB(0x31363a);
}
-(void)configureRowOvAddEvent:(PMLAddEventTableViewCell*)cell {
    cell.addEventLabel.text = NSLocalizedString(@"events.addButton", @"Create and promote an event");
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
    
    cell.activityTitleLabel.text = [self stringByStrippingHTML:activity.message];
    cell.activitySubtitleLabel.text = [_uiService delayStringFrom:activity.activityDate];
    cell.activityThumbImageView.image = [CALImage getDefaultUserThumb];
    if(activity.user.mainImage!=nil) {
        [_imageService load:activity.user.mainImage to:cell.activityThumbImageView thumb:YES];
    } else {
        [_imageService load:activity.activityObject.mainImage to:cell.activityThumbImageView thumb:YES];
    }
    cell.activityThumbImageView.layer.borderColor = [[_uiService colorForObject:activity.user] CGColor];
    
    // Auto-height
    CGSize size = [cell.activityTitleLabel sizeThatFits:CGSizeMake(cell.activityTitleLabel.frame.size.width,FLT_MAX)];
    cell.heightTitleConstraint.constant=size.height;
    // +41
    
    // Fonts
    cell.activityTitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:14];
    cell.activitySubtitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:12];
}
-(void)configureRowTopPlace:(PMLActivityTableViewCell*)cell atIndex:(NSInteger)row {
    Place *place = [[_infoProvider topPlaces] objectAtIndex:row];
    cell.activityTitleLabel.text = place.title;
    
    // Subtitle (like count)
    NSString *likeTemplate = NSLocalizedString(@"snippet.likes",@"snippet.likes");
    cell.activitySubtitleLabel.text = [NSString stringWithFormat:likeTemplate,place.likeCount];
    CGSize size = [cell.activitySubtitleLabel sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
    cell.widthSubtitleLabelConstraint.constant = size.width;
    
    // Setting city
    cell.cityLabel.text = place.cityName;
    size = [cell.cityLabel sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
    cell.widthCityLabelConstraint.constant = size.width;
    
    // Setting distance
    NSString *distance = [_conversionService distanceTo:place];
    cell.distanceLabel.text = distance;
    size = [cell.distanceLabel sizeThatFits:CGSizeZero];
    cell.widthDistanceLabelConstraint.constant = size.width;
    
    
    cell.activityThumbImageView.image = [CALImage getDefaultThumb];
    // Resetting height that might have been changed by an activity row
    cell.heightTitleConstraint.constant = 21;
    [_imageService load:place.mainImage to:cell.activityThumbImageView thumb:YES];
    cell.activityThumbImageView.layer.borderColor = [[_uiService colorForObject:place] CGColor];
    cell.activityTitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:14];
    cell.activitySubtitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:12];
    for(UIGestureRecognizer *recognizer in cell.activityThumbImageView.gestureRecognizers) {
        [cell.activityThumbImageView removeGestureRecognizer:recognizer];
    }
}

-(void) configureRowTags:(PMLTagsTableViewCell*)cell atIndex:(NSInteger)index {
    NSInteger tagsPerRow = kPMLMaxTagsPerRow; // (int) (self.tableView.bounds.size.width / kPMLOvTagWidth);
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
            [cell.tagsContainerView addSubview:imageView];
            [cell.tagViews addObject:imageView];
        }
    }

    // Computing margins
//    int margin = (cell.tagsContainerView.bounds.size.width-tagsCount*kPMLOvTagInnerWidth)/(tagsCount*2);
    NSInteger startX=0;
    for(NSInteger i = startTagIndex ; i < endTagIndex ; i++) {
        NSString *tagStr = [_snippetItem.tags objectAtIndex:i];
        UIImage *tagIcon = [_imageService getTagImage:tagStr];
        if(tagIcon != nil) {
            UIImageView *tagImageView = [cell.tagViews objectAtIndex:i-startTagIndex];
            tagImageView.image = tagIcon;
            tagImageView.frame = CGRectMake(startX, 0, kPMLOvTagInnerWidth, kPMLOvTagInnerWidth);
            cell.tagsContainerWidthConstraint.constant = startX+kPMLOvTagInnerWidth;
            startX += kPMLOvTagInnerWidth + 5;
        }
//        tagImageView.frame = CGRectMake((i-startTagIndex)*(kPMLOvTagInnerWidth+2*margin)+margin, 0, kPMLOvTagInnerWidth, kPMLOvTagInnerWidth);
    }
    [cell layoutIfNeeded];
    
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
    if([_infoProvider respondsToSelector:@selector(thumbTapped:)]) {
        [_infoProvider thumbTapped:self.parentMenuController];
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

-(NSArray*)indexPathArrayForMode:(ThumbPreviewMode)mode {
    
    // Building array of index path (to insert or delete)
    NSMutableArray *paths = [[NSMutableArray alloc] init];
    for(int i = kPMLRowThumbPreview ; i < kPMLRowThumbPreview + [_infoProvider thumbsRowCountForMode:mode] ; i++) {
        [paths addObject:[NSIndexPath indexPathForRow:i inSection:kPMLSectionCounters]];
    }
    return paths;
}

-(void)counterTappedForMode:(ThumbPreviewMode)mode {
    BOOL insert = _thumbPreviewMode == ThumbPreviewModeNone;
    ThumbPreviewMode currentMode = _thumbPreviewMode;
    _thumbPreviewMode = (_thumbPreviewMode == mode) ? ThumbPreviewModeNone : mode;
    
    
    // if new mode is empty then we consider no mode
    if(_thumbPreviewMode!=ThumbPreviewModeNone && [_infoProvider thumbsRowCountForMode:_thumbPreviewMode] == 0) {
        _thumbPreviewMode = ThumbPreviewModeNone;
    }

    
    // Unallocating thumbs preview resources
    // Getting number of rows previously displayed
//    NSInteger previousRows = [_infoProvider thumbsRowCountForMode:currentMode];
    for(int i = 0 ; i < 5 ; i++) {
        NSNumber *key = [NSNumber numberWithInt:i];
        ThumbTableViewController *counterThumbController = [_counterThumbControllers objectForKey:key];
        if(counterThumbController != nil) {
            [counterThumbController willMoveToParentViewController:nil];
            [counterThumbController.view removeFromSuperview];
            [counterThumbController removeFromParentViewController];
        }
        [_counterThumbControllers removeObjectForKey:key];
    }
    
    
    if(insert && _thumbPreviewMode == mode) {
        NSArray *paths = [self indexPathArrayForMode:_thumbPreviewMode];
        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (_thumbPreviewMode == ThumbPreviewModeNone) {
        NSArray *paths = [self indexPathArrayForMode:currentMode];
        [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        NSInteger currentRows = [_infoProvider thumbsRowCountForMode:currentMode];
        NSInteger newRows = [_infoProvider thumbsRowCountForMode:_thumbPreviewMode];

        NSMutableArray *oldPaths = [[NSMutableArray alloc] init];
        for(int i = kPMLRowThumbPreview ; i < kPMLRowThumbPreview + currentRows ; i++) {
            [oldPaths addObject:[NSIndexPath indexPathForRow:i inSection:kPMLSectionCounters]];
        }
        NSMutableArray *newPaths = [[NSMutableArray alloc] init];
        for(int i = kPMLRowThumbPreview ; i < kPMLRowThumbPreview + newRows ; i++) {
            [newPaths addObject:[NSIndexPath indexPathForRow:i inSection:kPMLSectionCounters]];
        }
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:oldPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView insertRowsAtIndexPaths:newPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
//        if(currentRows>newRows) {
//            [paths removeAllObjects];
//            for(int i = (int)newRows ; i < currentRows ; i++) {
//                [paths addObject:[NSIndexPath indexPathForRow:i inSection:kPMLSectionCounters]];
//            }
//            [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
//        } else if(newRows > currentRows) {
//            [paths removeAllObjects];
//            for(int i = (int)currentRows ; i < newRows ; i++) {
//                [paths addObject:[NSIndexPath indexPathForRow:i inSection:kPMLSectionCounters]];
//            }
//            [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
//        } else {
//            [self.tableView reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
//        }
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
-(void)topPlaceTapped:(NSInteger)index {
     CALObject *item = [[_infoProvider topPlaces] objectAtIndex:index];
    [self pushSnippetFor:item];
}
-(void)activityTapped:(NSInteger)index {
    Activity *activity = [[_infoProvider activities] objectAtIndex:index];
    [self pushSnippetFor:activity.user];
}
-(void)pushSnippetFor:(CALObject*)item {
    PMLSnippetTableViewController *childSnippet = (PMLSnippetTableViewController*)[TogaytherService.uiService instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
    childSnippet.snippetItem = item;
    if(self.subNavigationController != nil) {
        [self.subNavigationController pushViewController:childSnippet animated:YES];
        [self.parentMenuController openCurrentSnippet];
    } else {
        [self.navigationController pushViewController:childSnippet animated:YES];
    }
}
-(void)addEventTapped {
        PMLEventTableViewController *eventController = (PMLEventTableViewController*)[_uiService instantiateViewController:@"eventEditor"];
        eventController.event = [[Event alloc] initWithPlace:(Place*)self.snippetItem];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:eventController];
        
        // Preparing transition
        self.transitioningDelegate = [[SpringTransitioningDelegate alloc] initWithDelegate:self];
        self.transitioningDelegate.transitioningDirection = TransitioningDirectionDown;
        [self.transitioningDelegate presentViewController:navController];
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
    
    NSIndexPath *galleryPath = [NSIndexPath indexPathForRow:kPMLRowGallery inSection:kPMLSectionGallery];
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
        [self pushSnippetFor:(CALObject*)selectedItem];
    }
}

#pragma mark - PMLDataListener
- (void)didLoadOverviewData:(CALObject *)object {
    if([_snippetItem.key isEqualToString:object.key]) {
        // Building provider
        _thumbController.thumbProvider = _infoProvider.thumbsProvider;
        _hoursTypeMap = [_conversionService hashHoursByType:object];
        [self configureThumbController];
        [self.tableView reloadData];
        
        // Updating gallery
        [_galleryCell.galleryView reloadData];
        
        // Resetting description size
        _readMoreSize = 0;
        
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
    _hoursTypeMap = [_conversionService hashHoursByType:snippetItem];
    
    
    // Listening to edit mode
    [self.snippetItem addObserver:self forKeyPath:@"editing" options:NSKeyValueObservingOptionNew context:NULL];
    [_observedProperties addObject:@"editing"];
    [self.snippetItem addObserver:self forKeyPath:@"editingDesc" options:NSKeyValueObservingOptionNew context:NULL];
    [_observedProperties addObject:@"editingDesc"];
}
- (void)didLike:(CALObject *)likedObject newLikes:(int)likeCount newDislikes:(int)dislikesCount liked:(BOOL)liked {
    [self.tableView reloadData];
}
#pragma mark - UITextFieldDelegate
- (void)titleTextChanged:(UITextField*) textField {
    if([_snippetItem isKindOfClass:[Place class]]) {
        ((Place*)_snippetItem).title = textField.text;
    }
}
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
            ((Place*)_snippetItem).title = inputText;
            _snippetCell.titleLabel.text = inputText;
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
        
//        self.editing=NO;
    }
    [_snippetCell.titleTextField resignFirstResponder];
    [self.tableView reloadData];

}
#pragma mark - KVO Observing implementation
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([@"address" isEqualToString:keyPath]) {
//        if([object isKindOfClass:[Place class]]) {
//            _snippetCell.subtitleLabel.text = ((Place*)object).address;
//        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData]; //reloadSections:[NSIndexSet indexSetWithIndex:kPMLSectionOvAddress] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    } else if([@"editing" isEqualToString:keyPath] || [@"editingDesc" isEqualToString:keyPath]) {
        [self updateTitleEdition];
        // If place is already created we show the keyboard, otherwise it stays hidden
        if(_snippetItem.key != nil && _snippetItem.editing) {
            [_snippetCell.titleTextField becomeFirstResponder];
        }
    } else if([keyPath isEqualToString:@"mainImage"]) {
        [self.tableView reloadData]; 
    }
}
-(void)updateTitleEdition {
    if(_snippetItem.editing) {
        _snippetCell.titleTextField.delegate = self;
        _snippetCell.titleTextField.hidden=NO;
        _snippetCell.titleTextField.text = _infoProvider.title;
        _snippetCell.titleTextField.placeholder = NSLocalizedString(@"snippet.edit.titlePlaceholder", @"Enter a name");
        [_snippetCell.titleTextField addTarget:self
                           action:@selector(titleTextChanged:)
                 forControlEvents:UIControlEventEditingChanged];
//        [_snippetCell.titleTextField becomeFirstResponder];
        
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
        // Building placeholder
//        NSString *langCode = _snippetItem.miniDescLang;
//        if(langCode == nil) {
//            langCode = [TogaytherService getLanguageIso6391Code];
//        }
//        NSString *template = [NSString stringWithFormat:@"language.%@",langCode];
//        NSString *langLabel = NSLocalizedString(template, @"language name");
//        NSString *descPlaceholderTemplate = NSLocalizedString(@"description.placeholder", @"description placeholder");
//        NSString *descPlaceholder = [NSString stringWithFormat:descPlaceholderTemplate,langLabel];
//        

    } else {
        _snippetCell.titleTextField.hidden=YES;
        _snippetCell.titleLabel.text = _infoProvider.title;
        
        // Restoring thumbs provider
        _thumbController.thumbProvider = _infoProvider.thumbsProvider;
    }
}
#pragma mark - Dragging control & scroll view
- (void)tableViewPanned:(UIPanGestureRecognizer*)recognizer {
    NSArray *childControllers = self.navigationController.childViewControllers;
    if(childControllers.count>1 && !(childControllers.count==2 && [[childControllers objectAtIndex:0] isKindOfClass:[PMLFakeViewController class]])) {
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

#pragma  mark - PMLSnippetDelegate
- (void)snippetOpened {
    // Removing the thumb visibility when opened because it would overflow on the visible part
    PMLSnippetTableViewCell *cell = (PMLSnippetTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kPMLRowSnippet inSection:kPMLSectionSnippet]];
    [UIView animateWithDuration:0.5 animations:^{
        cell.thumbView.alpha=0;
        cell.backContainer.alpha=0;
    }];
}

-(void)snippetMinimized {
    // Restoring the thumb visibility when minimized
    PMLSnippetTableViewCell *cell = (PMLSnippetTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kPMLRowSnippet inSection:kPMLSectionSnippet]];
    [UIView animateWithDuration:0.5 animations:^{
        cell.thumbView.alpha=1;
        cell.backContainer.alpha=1;
    }];
}

#pragma mark - PMLSubNavigationDelegate
- (UIView *)subNavigationBackButtonContainer {
    PMLSnippetTableViewCell *cell = (PMLSnippetTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kPMLRowSnippet inSection:kPMLSectionSnippet]];
    return cell.backContainer;
}
@end
