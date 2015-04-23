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
#import "PMLThumbCollectionViewController.h"
#import "PMLSnippetTableViewCell.h"
#import "PMLSnippetDescTableViewCell.h"
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
#import "PMLButtonTableViewCell.h"
#import "PMLEventTableViewController.h"
#import "SpringTransitioningDelegate.h"
#import "PMLFakeViewController.h"
#import "PMLPopupActionManager.h"
#import "PMLCountersView.h"
#import "UIImage+IPImageUtils.h"
#import "UITouchBehavior.h"
#import "PMLSnippetEditTableViewCell.h"
#import "PMLPropertyTableViewCell.h"
#import "PMLWebViewController.h"
#import <MBProgressHUD.h>
#import <PBWebViewController.h>



#define BACKGROUND_COLOR UIColorFromRGB(0x272a2e)

#define kPMLSectionsCount 15

#define kPMLSectionGallery 0
#define kPMLSectionSnippet 1
#define kPMLSectionCounters 2
#define kPMLSectionLocalization 3
#define kPMLSectionOvSummary 4
#define kPMLSectionOvAddress 5
#define kPMLSectionOvProperties 6
#define kPMLSectionOvHours 7
#define kPMLSectionOvHappyHours 8
#define kPMLSectionOvEvents 9
#define kPMLSectionOvDesc 10
#define kPMLSectionOvTags 11
#define kPMLSectionTopPlaces 12
#define kPMLSectionActivity 13
#define kPMLSectionReport 14

#define kPMLSnippetRows 1
#define kPMLRowSnippet 0

#define kPMLRowGallery 0

#define kPMLRowCounters 0
#define kPMLRowThumbPreview 1
#define kPMLRowSnippetId @"snippet"
#define kPMLRowSnippetEditorId @"snippetEditor"
#define kPMLRowSnippetDescEditorId @"snippetDescEditor"
#define kPMLRowGalleryId @"gallery"
#define kPMLRowCountersId @"counters"
#define kPMLRowThumbPreviewId @"thumbsPreview"
#define kPMLHeightSnippet 110
#define kPMLHeightSnippetEditor 150
#define kPMLHeightGallery 180
#define kPMLHeightCounters 97
#define kPMLHeightThumbPreview 75
#define kPMLHeightThumbPreviewContainer 65
#define kPMLThumbSize @62
#define kPMLThumbTypesSize @45


#define kPMLOvSummaryRows 0
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

#define kPMLRowOvPropertyId @"propertyCell"
#define kPMLHeightOvPropertyRows 33;

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
#define kPMLHeightActivityHeader 30

#define kPMLReportRows 1
#define kPMLRowReportButton 0
#define kPMLHeightReportButton 62
#define kPMLRowReportButtonId @"reportButton"

#define kPMLHeightTopPlacesHeader 30


typedef enum {
    PMLVisibityStateTransitioning,
    PMLVisibityStateVisible,
    PMLVisibityStateInvisible
} PMLVisibityState;
@interface PMLSnippetTableViewController ()

@end

@implementation PMLSnippetTableViewController {
    
    // Inner controller for thumb listview
    PMLThumbCollectionViewController *_thumbController;
    PMLThumbCollectionViewController *_typesThumbController;
    PMLCountersView *_countersView;
    
    // Providers
    NSObject<PMLInfoProvider> *_infoProvider;
    NSMutableArray *_observedProperties;
    PMLPopupActionManager *_actionManager;
    
    // Cells
    PMLSnippetDescTableViewCell *_snippetDescCell;
    PMLGalleryTableViewCell *_galleryCell;
    PMLCountersTableViewCell *_countersCell;
    CAGradientLayer *_countersGradient;
    NSMutableDictionary *_countersPreviewGradients; // map of CAGradientLayer for likes/checkins gradients
    NSMutableDictionary *_heightsMap;
    PMLSnippetEditTableViewCell *_snippetEditCell;
    
    // Headers
    PMLSectionTitleView *_sectionTitleView;
    PMLSectionTitleView *_sectionLocalizationTitleView;
    PMLSectionTitleView *_sectionSummaryTitleView;
    PMLSectionTitleView *_sectionTopPlacesTitleView;
    PMLSectionTitleView *_sectionActivityTitleView;
    
    // Gallery
    BOOL _galleryFullscreen;
    CGRect _galleryFrame;
    float _galleryPctHeight;
    BOOL _hasGallery;
    
    
    // Services
    UIService *_uiService;
    ImageService *_imageService;
    DataService *_dataService;
    SettingsService *_settingsService;
    ConversionService *_conversionService;
    
    // Pre-computing
    NSDictionary *_hoursTypeMap;
    
    // Animations
    UIDynamicAnimator *_animator;
    
    // Dragging
    BOOL _parentDragging;
    CGPoint _dragStartPoint;
    CGFloat _descHeight;
    
    // Actions states
    BOOL _readMore;
    NSInteger _readMoreSize;
    ThumbPreviewMode _thumbPreviewMode;
    BOOL _opened;
    BOOL _didOpened;
    PMLVisibityState _editVisible;

    
    PBWebViewController *_webviewController;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    _descHeight = 0;
    _uiService = TogaytherService.uiService;
    _imageService = TogaytherService.imageService;
    _dataService = TogaytherService.dataService;
    _settingsService = [TogaytherService settingsService];
    _conversionService = [TogaytherService getConversionService];
    _actionManager = [[PMLPopupActionManager alloc] initWithObject:_snippetItem];
    _infoProvider = [_uiService infoProviderFor:_snippetItem];
    _thumbPreviewMode = ThumbPreviewModeNone;
    _countersView = (PMLCountersView*)[_uiService loadView:@"PMLCountersView"];
    _heightsMap = [[NSMutableDictionary alloc] init];
    _hoursTypeMap = [[NSMutableDictionary alloc] init];
    _galleryPctHeight = 0;
    
    self.tableView.backgroundColor = UIColorFromRGB(0x272a2e);
    self.tableView.opaque=YES;
    self.tableView.separatorColor = UIColorFromRGB(0x272a2e);
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    // Navigation
    [self.navigationController setNavigationBarHidden:YES];
    
    [self.tableView.panGestureRecognizer addTarget:self action:@selector(tableViewPanned:)];
    
    // Initializing external table view cells
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLEventTableViewCell" bundle:nil] forCellReuseIdentifier:kPMLRowEventId];
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLButtonTableViewCell" bundle:nil] forCellReuseIdentifier:kPMLRowAddEventId];
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLButtonTableViewCell" bundle:nil] forCellReuseIdentifier:kPMLRowReportButtonId];
    // Loading header views
    _sectionTitleView = (PMLSectionTitleView*)[_uiService loadView:@"PMLSectionTitleView"];
    _sectionLocalizationTitleView = (PMLSectionTitleView*)[_uiService loadView:@"PMLSectionTitleView"];
    _sectionSummaryTitleView = (PMLSectionTitleView*)[_uiService loadView:@"PMLSectionTitleView"];
    _sectionTopPlacesTitleView = (PMLSectionTitleView*)[_uiService loadView:@"PMLSectionTitleView"];
    _sectionActivityTitleView = (PMLSectionTitleView*)[_uiService loadView:@"PMLSectionTitleView"];
    
    // Animation init
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.tableView];
    
}
- (void)viewWillAppear:(BOOL)animated {
    self.actionManager.menuManagerController = self.parentMenuController;
    self.parentMenuController.snippetDelegate = self;
    [TogaytherService applyCommonLookAndFeel:self];
    self.navigationController.edgesForExtendedLayout=UIRectEdgeAll;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    
    // Edit visibility
    self.navigationItem.rightBarButtonItem=nil;
    _editVisible = PMLVisibityStateInvisible;
    
    if(_opened) {
        [self.parentMenuController.navigationController setNavigationBarHidden:YES];
    }

}
- (void)viewDidAppear:(BOOL)animated {
    _actionManager.menuManagerController = [self parentMenuController];

    // Getting data
    [_dataService registerDataListener:self];
    [[TogaytherService userService] registerListener:self];
    if(_snippetItem != nil) {
        [_dataService getOverviewData:_snippetItem];
    } else {
        [self.tableView reloadData];
    }
    
    // Map location
    if([_infoProvider respondsToSelector:@selector(mapObjectForLocalization)]) {
        CALObject *mapObject = [_infoProvider mapObjectForLocalization];
        if(mapObject!=nil) {
            [((MapViewController*)self.parentMenuController.rootViewController) selectCALObject:mapObject];
        }
    }
}
-(void)viewDidDisappear:(BOOL)animated {
    [_dataService unregisterDataListener:self];
    [[TogaytherService userService] unregisterListener:self];
}
- (void)dealloc {
    [self clearObservers];
}
- (void)willMoveToParentViewController:(UIViewController *)parent {
    if(parent == nil) {
        // Unregistering data listener
        [_dataService unregisterDataListener:self];
        
        [self clearObservers];
        // No more editing
//        if([_snippetItem respondsToSelector:@selector(editing)]) {
//            _snippetItem.editing=NO;
//        }
        

    }
}
- (void)clearObservers {
    // Unregistering any observed property
    for(NSString *observedProperty in _observedProperties) {
        NSLog(@"De-Observing '%@' from %p",observedProperty,self);
        // Removing us as observer
        [_snippetItem removeObserver:self forKeyPath:observedProperty];
    }
    // Purging props
    _observedProperties = [[NSMutableArray alloc] init];
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
                return _hasGallery ? 1 : 0;
            case kPMLSectionCounters:
                return [_infoProvider thumbsRowCountForMode:ThumbPreviewModeLikes]+[_infoProvider thumbsRowCountForMode:ThumbPreviewModeCheckins] >0 ? 1 : 0;
            case kPMLSectionLocalization: {
                if([_infoProvider respondsToSelector:@selector(mapObjectForLocalization)]) {
                    CALObject *locationObject = [_infoProvider mapObjectForLocalization];
                    if(locationObject != _snippetItem && locationObject != nil) {
                        return 1;
                    } else {
                        return 0;
                    }
                }
                break;
            }
            case kPMLSectionOvSummary:
                return kPMLOvSummaryRows;
            case kPMLSectionOvAddress:
                return [[_infoProvider addressComponents] count]+([_infoProvider city] == nil ? 0 : 1);
            case kPMLSectionOvProperties:
                return 0;
//                if([_infoProvider respondsToSelector:@selector(properties)]) {
//                    return [[_infoProvider properties] count];
//                }
//                return 0;
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
                    NSInteger addEventRowCount = 0;
                    if([_infoProvider respondsToSelector:@selector(canAddEvent)]) {
                        if([_infoProvider canAddEvent]) {
                            addEventRowCount = 1;
                        }
                    }
                    return [[_infoProvider events] count]+addEventRowCount;
                }
                break;
            case kPMLSectionOvDesc:
                return [[_infoProvider descriptionText] length]>0 ? kPMLOvDescRows : 0;
            case kPMLSectionOvTags: {
                double rows = (double)_snippetItem.tags.count / (double)kPMLMaxTagsPerRow; //((double)tableView.bounds.size.width / (double)kPMLOvTagWidth);
                return (int)ceil(rows);
            }
            case kPMLSectionReport:
                if([_infoProvider respondsToSelector:@selector(reportActionType)]) {
                    return [_infoProvider reportActionType] == PMLActionTypeNoAction? 0 : kPMLReportRows;
                }
                return 0;

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
                    return [[_infoProvider events] count];
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
                    if(_snippetItem.editing) {
                        return kPMLRowSnippetEditorId;
                    } else if(_snippetItem.editingDesc) {
                        return kPMLRowSnippetDescEditorId;
                    }
                    return kPMLRowSnippetId;
            }
            break;
        case kPMLSectionGallery:
            return kPMLRowGalleryId;
        case kPMLSectionCounters:
//            switch(indexPath.row) {
//                case kPMLRowCounters:
//                    return kPMLRowCountersId;
//                default:
                    return kPMLRowThumbPreviewId;
//            }
            break;
        case kPMLSectionLocalization:
            return kPMLRowEventId;
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
        case kPMLSectionOvProperties:
            return kPMLRowOvPropertyId;
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
        case kPMLSectionReport:
            return kPMLRowReportButtonId;

    }
    return nil;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseCellId = [self rowIdForIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseCellId forIndexPath:indexPath];
    cell.backgroundColor = BACKGROUND_COLOR;
    cell.opaque=YES;
    // Configure the cell...
    switch(indexPath.section) {
        case kPMLSectionSnippet:
            switch(indexPath.row) {
                case kPMLRowSnippet:
                    if(_snippetItem.editing) {
                        [self configureRowSnippetEditor:(PMLSnippetEditTableViewCell*)cell];
                    } else if(_snippetItem.editingDesc) {
                        [self configureRowSnippetDescriptionEditor:(PMLSnippetDescTableViewCell*)cell];
                    } else {
                        [self configureRowSnippet:(PMLSnippetTableViewCell*)cell];
                    }
                    break;
            }
            break;
        case kPMLSectionGallery:
            [self configureRowGallery:(PMLGalleryTableViewCell*)cell];
            break;
        case kPMLSectionCounters:
            [self configureRowThumbPreview:(PMLThumbsTableViewCell*)cell atIndex:indexPath.row];
            break;
        case kPMLSectionLocalization:
            [self configureRowLocalization:(PMLEventTableViewCell*)cell];
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
            if(indexPath.row < [[_infoProvider addressComponents] count] && [cell isKindOfClass:[PMLTextTableViewCell class]]) {
                [self configureRowOvAddress:(PMLTextTableViewCell*)cell atIndex:indexPath.row];
            } else {
                [self configureRowOvCity:(PMLImagedTitleTableViewCell*)cell];
            }
            break;
        case kPMLSectionOvProperties:
            [self configureRowProperty:(PMLPropertyTableViewCell*)cell atIndex:indexPath.row];
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
                [self configureRowOvAddEvent:(PMLButtonTableViewCell*)cell];
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
        case kPMLSectionReport:
            [self configureRowReport:(PMLButtonTableViewCell*)cell];
            break;
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kPMLSectionSnippet:
            switch(indexPath.row) {
                case kPMLRowSnippet:
                    if(!_snippetItem.editing) {
                        return kPMLHeightSnippet;
                    } else {
                        return kPMLHeightSnippetEditor;
                    }
            }
            break;
        case kPMLSectionGallery:
            if(!_galleryFullscreen) {
                // Substract 5 for #44 little truncation
                return kPMLHeightGallery; //(tableView.bounds.size.width-5)-(48*2);
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
        case kPMLSectionLocalization:
            return kPMLHeightOvEventRows;
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
        case kPMLSectionOvProperties:
            return kPMLHeightOvPropertyRows;
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
        case kPMLSectionReport:
            return kPMLHeightReportButton;
    }
    return 44;

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
        case kPMLSectionLocalization:
            if([_infoProvider respondsToSelector:@selector(mapObjectForLocalization)] && [_infoProvider respondsToSelector:@selector(localizationSectionTitle)]) {
                CALObject *obj = [_infoProvider mapObjectForLocalization];
                if(obj !=nil) {
                    [_sectionLocalizationTitleView setTitle:[_infoProvider localizationSectionTitle]];
                    return _sectionLocalizationTitleView;
                }
            }
            return nil;
        case kPMLSectionOvSummary: {
            [_sectionSummaryTitleView setTitleLocalized:@"snippet.title.summary"];
            NSMutableArray *actionsArray = [[NSMutableArray alloc] init];
            
            // Do we have a phone property?
            PMLProperty *phoneProperty = [_uiService propertyFrom:_infoProvider forCode:PML_PROPERTY_CODE_PHONE];
            if(phoneProperty !=nil) {
                // If yes we install the phone action
                [actionsArray addObject:[self.actionManager actionForType:PMLActionTypePhoneCall]];
            }
            // Do we have a website property?
            PMLProperty *websiteProperty = [_uiService propertyFrom:_infoProvider forCode:PML_PROPERTY_CODE_WEBSITE];
            if(websiteProperty !=nil) {
                // If yes we install the website action
                [actionsArray addObject:[self.actionManager actionForType:PMLActionTypeWebsite]];
            }
            if(actionsArray.count>0) {
                [_sectionSummaryTitleView installPopupActions:actionsArray];
            }
            
            return _sectionSummaryTitleView;
        }
        case kPMLSectionTopPlaces:
            [_sectionTopPlacesTitleView setTitleLocalized:@"snippet.header.topPlaces"];
            return _sectionTopPlacesTitleView;
        case kPMLSectionActivity:
            [_sectionActivityTitleView setTitleLocalized:@"snippet.header.activities"];
            return _sectionActivityTitleView;

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
            case kPMLSectionLocalization:
                if([_infoProvider respondsToSelector:@selector(mapObjectForLocalization)] && [_infoProvider respondsToSelector:@selector(localizationSectionTitle)]) {
                    CALObject *obj = [_infoProvider mapObjectForLocalization];
                    if(obj !=nil && [_infoProvider localizationSectionTitle]!=nil) {
                        return _sectionLocalizationTitleView.bounds.size.height;
                    }
                }
                return 0;
            case kPMLSectionOvSummary: {
                NSInteger rows = [[_infoProvider addressComponents] count]+([_infoProvider city] == nil ? 0 : 1);
                NSInteger height =38;
                
                // Increasing height if we have phone / website controls
                PMLProperty *phoneProperty = [_uiService propertyFrom:_infoProvider forCode:PML_PROPERTY_CODE_PHONE];
                PMLProperty *websiteProperty = [_uiService propertyFrom:_infoProvider forCode:PML_PROPERTY_CODE_WEBSITE];
                if(phoneProperty != nil || websiteProperty != nil) {
                    height+=10;
                }
                return rows>0 ? height : 0;
            }
            case kPMLSectionCounters:
                return 5;
            default:
                break;
        }
    } else {
        switch(section) {
            case kPMLSectionActivity:
                return [[_infoProvider activities] count ]>0 ? kPMLHeightActivityHeader : 0;
            case kPMLSectionTopPlaces:
                if([[_infoProvider topPlaces] count ]>0) {
                    return kPMLHeightTopPlacesHeader;
                } else {
                    return 0;
                }
            case kPMLSectionOvEvents:
                if([_infoProvider respondsToSelector:@selector(eventsSectionTitle)]) {
                    if([_infoProvider eventsSectionTitle]!=nil && [[_infoProvider events] count]>0) {
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
        case kPMLSectionCounters:
            for(UIView *childView in view.subviews) {
                childView.backgroundColor = UIColorFromRGB(0x272a2e);
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
    switch(indexPath.section) {
        case kPMLSectionTopPlaces:
        case kPMLSectionActivity:
        case kPMLSectionLocalization:
        case kPMLSectionReport:
            return YES;
        case kPMLSectionOvProperties: {
            PMLProperty *p = [[_infoProvider properties] objectAtIndex:indexPath.row];
            return [p.propertyCode isEqualToString:@"website"];
        }
        case kPMLSectionOvAddress:
            if([_infoProvider city] !=nil) {
                NSInteger rows = [self.tableView numberOfRowsInSection:indexPath.section];
                if(rows -1 == indexPath.row) {
                    return NO;
                }
            }
            // Address lines are selectable only if we have something to display on the map
            return [_infoProvider respondsToSelector:@selector(mapObjectForLocalization)];
    }
    return NO;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kPMLSectionTopPlaces:
            [self topPlaceTapped:indexPath.row];
            break;
        case kPMLSectionActivity:
            [self activityTapped:indexPath.row];
            break;
        case kPMLSectionOvAddress:
            self.tableView.contentOffset = CGPointMake(0,0);
            if([_infoProvider respondsToSelector:@selector(mapObjectForLocalization)]) {
                CALObject *localizationObj = [_infoProvider mapObjectForLocalization];
                if(localizationObj!=nil) {
                    [self.parentMenuController minimizeCurrentSnippet:YES];
                    [self.parentMenuController.rootViewController selectCALObject:localizationObj];
                }
            }
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        case kPMLSectionOvProperties: {
            PMLProperty *p = [[_infoProvider properties] objectAtIndex:indexPath.row];
            if([p.propertyCode isEqualToString:@"website"]) {
//                PMLWebViewController *webviewController = (PMLWebViewController*)[_uiService instantiateViewController:SB_ID_WEBVIEW];
//                [webviewController setUrl:p.propertyValue];
                _webviewController= [[PBWebViewController alloc] init];
                _webviewController.URL = [[NSURL alloc] initWithString:p.propertyValue];
                [TogaytherService applyCommonLookAndFeel:self];
                self.navigationController.navigationBar.translucent=NO;
                [self.navigationController pushViewController:_webviewController animated:YES];

            }
            break;
        }
        case kPMLSectionLocalization: {
            CALObject *locationObject = [_infoProvider mapObjectForLocalization];
            [_uiService presentSnippetFor:locationObject opened:YES];
            break;
        }
        case kPMLSectionOvEvents:
            if(indexPath.row == [[_infoProvider events] count]) {
                [self addEventTapped];
            } else {
                Event *event = [[_infoProvider events] objectAtIndex:indexPath.row];
                [self pushSnippetFor:event];
            }
            break;
        case kPMLSectionReport: {
            PopupAction *action = [_actionManager actionForType:[_infoProvider reportActionType]];
            action.actionCommand();
            break;
        }
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Cell configuration

- (void)configureRowSnippetEditor:(PMLSnippetEditTableViewCell*)cell {
    _snippetEditCell = cell;
    cell.titleTextField.delegate = self;
    cell.titleTextField.hidden=NO;
    cell.titleTextField.text = _infoProvider.title;
    cell.titleTextField.placeholder = NSLocalizedString(@"snippet.edit.titlePlaceholder", @"Enter a name");
    [cell.titleTextField addTarget:self
                                    action:@selector(titleTextChanged:)
                          forControlEvents:UIControlEventEditingChanged];

    

    // Toggling place type selection
    if([_snippetItem isKindOfClass:[Place class]]) {
        Place *place = (Place*)_snippetItem;
        
        // Initializing default type
        PlaceType *selectedPlaceType = [_settingsService defaultPlaceType];
        // Getting place type for current place
        NSString *typeCode =place.placeType;
        if(typeCode != nil) {
            selectedPlaceType = [_settingsService getPlaceType:typeCode];
        }
        // Initilizing with this selection
        PMLPlaceTypesThumbProvider *provider = [[PMLPlaceTypesThumbProvider alloc] initWithPlace:place];
        [cell layoutIfNeeded];
        _typesThumbController = [self thumbControllerIn:cell.peopleView provider:provider using:_typesThumbController size:kPMLThumbTypesSize];
        
        // Address update
        cell.addressTextField.text = place.address;
        cell.addressTextField.delegate = self;
    }
    cell.subtitleLabel.text = NSLocalizedString(@"snippet.edit.placeType",@"Select the kind of venue:");
    [cell.okButton addTarget:self  action:@selector(editOkTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.cancelButton addTarget:self  action:@selector(editCancelTapped:) forControlEvents:UIControlEventTouchUpInside];
}
-(void)configureRowSnippetDescriptionEditor:(PMLSnippetDescTableViewCell*)cell {
    _snippetDescCell = cell;
    cell.descriptionTextView.delegate = self;
    cell.descriptionTextView.text = _infoProvider.descriptionText;
    cell.descriptionLanguageLabel.text = [_snippetItem.miniDescLang uppercaseString];
    [cell.descriptionTextViewButton addTarget:self action:@selector(descriptionDone:) forControlEvents:UIControlEventTouchUpInside];
    [cell.descriptionTextViewCancelButton addTarget:self action:@selector(editCancelTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.descriptionTextView becomeFirstResponder];
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
}
- (void)configureRowSnippet:(PMLSnippetTableViewCell*)cell {
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

    if([_infoProvider respondsToSelector:@selector(subtitleIntro)]) {
        cell.distanceIntroLabel.hidden=NO;
        cell.distanceIntroLabel.text = [_infoProvider subtitleIntro];
    } else {
        cell.distanceIntroLabel.hidden=YES;
        cell.distanceIntroLabel.text =nil;
    }
    
    // Image touch events, only allowing photo addition if item is defined and has a valid key id
    if(_snippetItem.key != nil) {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
        [cell.thumbView addGestureRecognizer:tapRecognizer];
        cell.thumbView.userInteractionEnabled=YES;
    }
    
    // Subtitle
    cell.subtitleLabel.text = [_infoProvider subtitle];
    cell.subtitleIcon.image = [_infoProvider subtitleIcon];
    if([_infoProvider subtitle] == nil) {
        cell.subtitleIcon.hidden = YES;
    } else {
        cell.subtitleIcon.hidden = NO;
    }
    CGSize subtitleSize = [cell.subtitleLabel sizeThatFits:CGSizeMake(MAXFLOAT, cell.subtitleLabel.bounds.size.height)];
    cell.subtitleWidthConstraint.constant = subtitleSize.width;
    
    // Observing address
    if([_snippetItem isKindOfClass:[Place class]]) {
//        [self.snippetItem addObserver:self forKeyPath:@"address" options:   NSKeyValueObservingOptionNew context:NULL];
//        [_observedProperties addObject:@"address"];
    }
    [self.snippetItem addObserver:self forKeyPath:@"mainImage" options:   NSKeyValueObservingOptionNew context:NULL];
    [_observedProperties addObject:@"mainImage"];
    // Setting opening hours badge
    if([_infoProvider respondsToSelector:@selector(hasSnippetRightSection)] && [_infoProvider hasSnippetRightSection]) {
        cell.hoursBadgeView.hidden=NO;
        cell.hoursBadgeTitleLabel.text = [_infoProvider snippetRightTitleText];
        cell.hoursBadgeSubtitleLabel.text = [_infoProvider snippetRightSubtitleText];
        cell.hoursBadgeTitleLabel.textColor = [_infoProvider snippetRightColor];
        cell.hoursBadgeSubtitleLabel.textColor = [_infoProvider snippetRightColor];
        cell.hoursBadgeImageView.image = [_infoProvider snippetRightIcon];
        cell.hoursBadgeImageView.hidden=YES;

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

    
    // Fonts
    cell.hoursBadgeTitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:10];
    cell.hoursBadgeSubtitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:8];
    cell.titleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:16];
    

    // If custom view then configuring it
    if([_infoProvider respondsToSelector:@selector(configureCustomViewIn:forController:)]) {
        [_infoProvider configureCustomViewIn:cell.peopleView forController:self];
    } else {
        if(_countersView.superview != cell.peopleView) {
            if(_countersView.superview) {
                [_countersView removeFromSuperview];
            }
            [cell layoutIfNeeded];
            CGRect frame = cell.peopleView.bounds;
            _countersView.frame = CGRectMake(frame.origin.x,frame.origin.y,frame.size.width-15,frame.size.height);
            [cell.peopleView addSubview:_countersView];
        }
        _countersView.backgroundColor=BACKGROUND_COLOR;
        id<PMLCountersDatasource> datasource = [_infoProvider countersDatasource:self.actionManager];
        _countersView.datasource = datasource;
        [_countersView reloadData];
    }
    
    // If edit mode we activate it
    if(_snippetItem.editing) {
        [self updateTitleEdition];
    }
}
-(void)configureRowThumbPreview:(PMLThumbsTableViewCell*)cell atIndex:(NSInteger)index {
    NSObject<PMLThumbsPreviewProvider> *provider = [_infoProvider thumbsProvider];
    
    // Numeric row key
    cell.backgroundColor = BACKGROUND_COLOR; //[UIColor clearColor];

    // Thumb controller
    [cell layoutIfNeeded];
    _thumbController = [self thumbControllerIn:cell.thumbsContainer provider:provider using:_thumbController size:kPMLThumbSize];
}
/**
 * Instantiates a new controller or readjusts the current controller using given providers and parent views
 */
-(PMLThumbCollectionViewController*)thumbControllerIn:(UIView*)parentView provider:(NSObject<PMLThumbsPreviewProvider>*)provider using:(PMLThumbCollectionViewController*)sourceController size:(NSNumber*)thumbSize {
    
    PMLThumbCollectionViewController *controller = sourceController;
    if(provider != nil) {
        if(controller != nil) {
            [controller willMoveToParentViewController:nil];
            [controller.view removeFromSuperview];
            [controller removeFromParentViewController];
        } else {
            controller = (PMLThumbCollectionViewController*)[_uiService instantiateViewController:@"thumbCollectionCtrl"];
        }
        [self addChildViewController:controller];
        controller.actionDelegate=self;
        controller.size = thumbSize;
        [controller setThumbProvider:provider];
        controller.view.frame = parentView.bounds;
        [parentView addSubview:controller.view];
        [controller didMoveToParentViewController:self];
    }
    return controller;
}
-(void)configureRowGallery:(PMLGalleryTableViewCell*)cell {
    _galleryCell = cell;
    cell.galleryView.delegate=self;
    cell.galleryView.dataSource=self;
    
    // Wiring add photo action (default is YES if not implemented)
    BOOL canAddPhoto = YES;
    if([_infoProvider respondsToSelector:@selector(canAddPhoto)]) {
        canAddPhoto = [_infoProvider canAddPhoto];
    }
    if(canAddPhoto) {
        PopupAction *action = [_actionManager actionForType:PMLActionTypeAddPhoto];
        cell.addPhotoButton.hidden=NO;
        cell.addPhotoButton.tag=PMLActionTypeAddPhoto;
        cell.addPhotoButton.layer.borderColor = [action.color CGColor];
        [cell.addPhotoButton addTarget:self action:@selector(actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        cell.addPhotoButton.hidden=YES;
    }
    
//    // Wiring secondary action
//    if([_infoProvider respondsToSelector:@selector(secondaryActionType)]) {
//        PMLActionType actionType = [_infoProvider secondaryActionType];
//        PopupAction *action = [_actionManager actionForType:actionType];
//        if(action != nil) {
//            cell.secondaryButton.hidden=NO;
//            cell.secondaryButtonTitle.hidden=NO;
//            
//            cell.secondaryButtonTitle.text = [_infoProvider actionSubtitleFor:actionType];
//            [cell.secondaryButton setImage:action.icon forState:UIControlStateNormal];
//            cell.secondaryButton.layer.borderColor = [action.color CGColor];
//            cell.secondaryButton.tag = actionType;
//            [cell.secondaryButton addTarget:self action:@selector(actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//        } else {
//            cell.secondaryButton.hidden=YES;
//            cell.secondaryButtonTitle.hidden=YES;
//        }
//    } else {
        cell.secondaryButton.hidden=YES;
        cell.secondaryButtonTitle.hidden=YES;
//    }
}
-(void)actionButtonTapped:(UIButton*)source {
    PopupAction *action = [_actionManager actionForType:(PMLActionType)source.tag];
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
-(void)configureRowProperty:(PMLPropertyTableViewCell*)cell atIndex:(NSInteger)row {
    PMLProperty *property = [[_infoProvider properties] objectAtIndex:row];
    
    // Decoding property code
    NSString *labelCode = [NSString stringWithFormat:@"property.label.%@",property.propertyCode];
    NSString *label = NSLocalizedString(labelCode, labelCode);
    if([label isEqualToString:labelCode]) {
        label = property.defaultLabel;
    }
    if([@"phone" isEqualToString:property.propertyCode]) {
        cell.propertyTextView.hidden=NO;
        cell.propertyLabel.hidden=YES;
        cell.propertyIcon.hidden=NO;
        cell.propertyTextView.text = property.propertyValue;
        cell.propertyTextView.textContainerInset = UIEdgeInsetsMake(3, 0, 3, 0);
        cell.propertyTextView.textColor = UIColorFromRGB(0xababac);
        cell.propertyTextView.tintColor = [UIColor whiteColor];
        CGSize fitSize =  [cell.propertyTextView sizeThatFits:CGSizeMake(cell.bounds.size.width, cell.propertyTextView.bounds.size.height)];
        cell.propertyLabelWidthConstraint.constant = fitSize.width;
        cell.propertyIcon.image = [UIImage imageNamed:@"snpIconPhone"];
    } else {
        cell.propertyLabel.hidden=NO;
        cell.propertyIcon.hidden=NO;
        cell.propertyTextView.hidden=YES;
        if([@"website" isEqualToString:property.propertyCode]) {
            cell.propertyLabel.text = property.propertyValue;
            cell.propertyLabel.textColor = UIColorFromRGB(0xababac);
            CGSize fitSize =  [cell.propertyLabel sizeThatFits:CGSizeMake(cell.bounds.size.width, cell.propertyTextView.bounds.size.height)];
            cell.propertyLabelWidthConstraint.constant=fitSize.width;
            cell.propertyIcon.image = nil; //[UIImage imageNamed:@"snpIconWeb"];
        } else {
            cell.propertyLabel.text = [NSString stringWithFormat:@"%@ - %@",label,property.propertyValue];
        }


    }
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
    
    CALImage *calEventImage;
    if([_infoProvider respondsToSelector:@selector(imageForEvent:)]) {
        calEventImage = [_infoProvider imageForEvent:event];
    } else {
        calEventImage = [[TogaytherService imageService] imageOrPlaceholderFor:event allowAdditions:YES];
    }
    [_imageService load:calEventImage to:cell.image thumb:NO];
    
    cell.titleLabel.text = [_uiService nameForEvent:event];
    cell.dateLabel.text = [_conversionService eventDateLabel:event isStart:YES];
    cell.locationIcon.image = [UIImage imageNamed:@"snpIconMarker"];
    if(event.place.cityName != nil) {
        cell.locationLabel.text = [NSString stringWithFormat:@"%@, %@",event.place.title,event.place.cityName];
    } else {
        cell.locationLabel.text = event.place.title;
    }
    if(event.likeCount>0) {
        cell.countLabel.text = [_uiService localizedString:@"snippet.event.inUsers" forCount:event.likeCount];
        cell.countIcon.image=[UIImage imageNamed:@"snpIconEvent"];
    } else {
        cell.countIcon.image = nil;
        cell.countLabel.text = nil;
    }
//    cell.backgroundColor = UIColorFromRGB(0x31363a);
}
-(void)configureRowOvAddEvent:(PMLButtonTableViewCell*)cell {
    cell.buttonLabel.text = NSLocalizedString(@"events.addButton", @"Create and promote an event");
    cell.buttonImageView.image = [UIImage imageNamed:@"evtButtonAdd"];
}
-(void)configureRowLocalization:(PMLEventTableViewCell*)cell {

    // Getting provider of location object
    CALObject *mapObject = [_infoProvider mapObjectForLocalization];
    id<PMLInfoProvider> provider = [_uiService infoProviderFor:mapObject];
    
    // Image
//    cell.image.image = nil;
    CALImage *calImage = [[TogaytherService imageService] imageOrPlaceholderFor:mapObject allowAdditions:NO];
    [_imageService load:calImage to:cell.image thumb:NO];
    
    cell.dateLabel.text = [@"@ " stringByAppendingString:[[provider title] uppercaseString]];
    if([[provider addressComponents] count]>0) {
        cell.titleLabel.text = [[provider addressComponents] objectAtIndex:0];
    } else {
        cell.titleLabel.text = nil;
    }
    cell.locationIcon.image = [provider subtitleIcon];
    cell.locationLabel.text = [provider subtitle];
    if([provider checkinsCount]>0) {
        cell.countLabel.text = [_uiService localizedString:@"counters.arehere" forCount:[provider checkinsCount]];
        cell.countIcon.image=[UIImage imageNamed:@"snpIconEvent"];
    } else if([provider likesCount]>0) {
        cell.countLabel.text = [_uiService localizedString:@"counters.likes" forCount:[provider likesCount]];
        cell.countIcon.image=[UIImage imageNamed:@"snpIconLike"];
    } else {
        cell.countIcon.image = nil;
        cell.countLabel.text = nil;
    }
    
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
    cell.activitySubtitleLabel.text = [_uiService localizedString:@"counters.likes" forCount:place.likeCount];
    CGSize size = [cell.activitySubtitleLabel sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
    cell.widthSubtitleLabelConstraint.constant = size.width;
    
    // Checkins count
    if(place.inUserCount>0) {
        cell.checkinLabel.text = [_uiService localizedString:@"counters.arehere" forCount:place.inUserCount];
        cell.checkinImageView.image = [UIImage imageNamed:@"snpIconMarker"];
    } else {
        cell.checkinImageView.image = nil;
        cell.checkinLabel.text = nil;
    }
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
    cell.activityThumbImageView.layer.borderColor = [[UIColor whiteColor] CGColor]; //[[_uiService colorForObject:place] CGColor];
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
-(void) configureRowReport:(PMLButtonTableViewCell*)cell {
    cell.buttonImageView.image = [UIImage imageNamed:@"snpButtonReport"];
    cell.buttonLabel.text = [_infoProvider reportText];
    cell.buttonContainer.backgroundColor = UIColorFromRGBAlpha(0xc50000,0.2);
}

-(NSString *) stringByStrippingHTML:(NSString*)html {
    NSRange r;
    NSString *s = [NSString stringWithString:html];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
}

#pragma mark - InfoProvider helpers
-(PMLActionType)checkinAction {
    PMLActionType type = PMLActionTypeCheckin;
    if([_infoProvider respondsToSelector:@selector(checkinActionType)]) {
        type = [_infoProvider checkinActionType];
    }
    return type;
}
-(PMLActionType)likeAction {
    PMLActionType type = PMLActionTypeLike;
    if([_infoProvider respondsToSelector:@selector(likeActionType)]) {
        type = [_infoProvider likeActionType];
    }
    return type;
}
-(PMLActionType)commentAction {
    PMLActionType type = PMLActionTypeComment;
    if([_infoProvider respondsToSelector:@selector(commentActionType)]) {
        type = [_infoProvider commentActionType];
    }
    return type;
}

#pragma mark - Actions callback
- (void) labelTapped:(UIGestureRecognizer*)sender {
    _snippetItem.editing = YES;
    [self updateTitleEdition];
    
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

-(void)likeTapped {
    PMLActionType type = [self likeAction];
    if(type != PMLActionTypeNoAction) {
        PopupAction *action = [self.actionManager actionForType:type];
        UITouchBehavior *touch = [[UITouchBehavior alloc] initWithTarget:_countersView.likeIcon];
        [touch setMagnitude:0.5];
        [_animator removeAllBehaviors];
        [_animator addBehavior:touch];
        
        action.actionCommand();
    }
}
-(void)checkinTapped {
    PMLActionType type = [self checkinAction];
    if(type != PMLActionTypeNoAction) {
        PopupAction *action = [self.actionManager actionForType:type];
        UITouchBehavior *touch = [[UITouchBehavior alloc] initWithTarget:_countersView.checkinIcon];
        [touch setMagnitude:0.5];
        [_animator removeAllBehaviors];
        [_animator addBehavior:touch];
        
        action.actionCommand();
    }
}
-(void)commentTapped {
    PMLActionType type = [self commentAction];
    if(type != PMLActionTypeNoAction) {
        PopupAction *action = [self.actionManager actionForType:type];
        UITouchBehavior *touch = [[UITouchBehavior alloc] initWithTarget:_countersView.commentsIcon];
        [touch setMagnitude:0.5];
        [_animator removeAllBehaviors];
        [_animator addBehavior:touch];
        
        action.actionCommand();
    }
}
-(NSArray*)indexPathArrayForMode:(ThumbPreviewMode)mode {
    
    // Building array of index path (to insert or delete)
    NSMutableArray *paths = [[NSMutableArray alloc] init];
    for(int i = kPMLRowThumbPreview ; i < kPMLRowThumbPreview + [_infoProvider thumbsRowCountForMode:mode] ; i++) {
        [paths addObject:[NSIndexPath indexPathForRow:i inSection:kPMLSectionCounters]];
    }
    return paths;
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
    // Instantiating controller
    PMLSnippetTableViewController *childSnippet = (PMLSnippetTableViewController*)[TogaytherService.uiService instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
    
    // Injecting item to display
    childSnippet.snippetItem = item;
    
    // Registering parent menu view controller to present the relationship
    [childSnippet setParentMenuController:self.parentMenuController];

    // Pushing new view controller
    [self.navigationController pushViewController:childSnippet animated:YES];
}
-(void)addEventTapped {
    // Getting edit event action
    PopupAction *action = [_actionManager actionForType:PMLActionTypeEditEvent];
    action.actionCommand();
//    
//    PMLEventTableViewController *eventController = (PMLEventTableViewController*)[_uiService instantiateViewController:@"eventEditor"];
//    eventController.event = [[Event alloc] initWithPlace:(Place*)self.snippetItem];
//    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:eventController];
//    
//    // Preparing transition
//    [self.parentMenuController presentModal:navController];
}

-(void)descriptionDone:(id)sender {
    UITextView *textView = _snippetDescCell.descriptionTextView;
    NSString *inputText = textView.text;
    
    // Removing current input
    textView.text = nil;
    
    [_snippetDescCell.descriptionTextViewButton removeTarget:self action:@selector(descriptionDone:) forControlEvents:UIControlEventTouchUpInside];
    
    // Only doing something if we have a valid text
    NSString *desc = [inputText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if(desc.length>0) {
        _snippetItem.editingDesc=NO;
        _snippetItem.miniDesc = inputText;
        
        // Commiting changes
        PopupAction *action = [self.actionManager actionForType:PMLActionTypeConfirm];
        action.actionCommand();
    }
    [self.tableView reloadData];
    
}
-(void)editOkTapped:(id)sender {
    if(![_snippetEditCell.addressTextField.text isEqualToString:((Place*)_snippetItem).address]) {
        [self updateAddress:_snippetEditCell.addressTextField.text];
    } else {
        PopupAction *okAction = [_actionManager actionForType:PMLActionTypeConfirm];
        okAction.actionCommand();
    }
}
-(void)editCancelTapped:(id)sender {
    PopupAction *cancelAction = [_actionManager actionForType:PMLActionTypeCancel];
    cancelAction.actionCommand();
}
#pragma mark - PMLImageGalleryDelegate
- (void)imageTappedAtIndex:(int)index image:(CALImage *)image {
    [self toggleFullscreenGallery];
}
-(void)toggleFullscreenGallery {

    _galleryFullscreen = !_galleryFullscreen;
    
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
//    return  UIViewContentModeScaleAspectFill;
//        return  _galleryFullscreen ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
    return  UIViewContentModeScaleAspectFit;
    
}
- (BOOL)alignTop {
    return !_galleryFullscreen;
}
-(UIImage *)placeHolderImageForImagePager {
    return [[_imageService imageOrPlaceholderFor:_snippetItem allowAdditions:[_infoProvider canAddPhoto]] fullImage];

}
- (void)imagePager:(KIImagePager *)imagePager didSelectImageAtIndex:(NSUInteger)index {
    // If no photo
    if(index == -1) {
        if([_infoProvider canAddPhoto]) {
            // Offering to upload one
            PopupAction *uploadAction = [_actionManager actionForType:PMLActionTypeAddPhoto];
            uploadAction.actionCommand();
        }
    } else {
        [self imageTappedAtIndex:(int)index image:nil];
    }
}
#pragma mark - ThumbPreviewActionDelegate
- (void)thumbsTableView:(PMLThumbCollectionViewController*)controller thumbTapped:(int)thumbIndex forThumbType:(PMLThumbType)type {
    id selectedItem = [[controller.thumbProvider itemsForType:type] objectAtIndex:thumbIndex];
    if(_snippetItem.editing) {
        if([selectedItem isKindOfClass:[PlaceType class]]) {
            // Assigning new place
            ((Place*)_snippetItem).placeType = ((PlaceType*)selectedItem).code;
            // Refreshing table
            [controller.collectionView reloadData];
        }
    } else {
        [self pushSnippetFor:(CALObject*)selectedItem];
    }
}

#pragma mark - PMLDataListener
- (void)didLoadOverviewData:(CALObject *)object {
    if([_snippetItem.key isEqualToString:object.key]) {
        _infoProvider = [_uiService infoProviderFor:object];
        // Building provider
        _thumbController.thumbProvider = _infoProvider.thumbsProvider;
        _hoursTypeMap = [_conversionService hashHoursByType:object];
        [self.tableView reloadData];
        
        // Updating gallery
        [_galleryCell.galleryView reloadData];
        
        // Resetting description size
        _readMoreSize = 0;
        
        // Selecting on map
        if([object isKindOfClass:[Place class]] && object.lat!=0 && object.lng!=0) {
            [((MapViewController*)self.parentMenuController.rootViewController) selectCALObject:_snippetItem];
        }
    } else {
        // If something else, we reload everything
        NSLog(@"Reloading table view for external overview data: %@",object.key);
        [self.tableView reloadData];
    }
}

- (void)setSnippetItem:(CALObject *)snippetItem {
    [self clearObservers];
    _snippetItem = snippetItem;
    _infoProvider = [TogaytherService.uiService infoProviderFor:_snippetItem];
    _hoursTypeMap = [_conversionService hashHoursByType:snippetItem];
    if(_snippetItem != nil) {
        [_dataService getOverviewData:_snippetItem];
    }

    // Listening to edit mode
    NSLog(@"Observing 'editing' from %p",self);
    [self.snippetItem addObserver:self forKeyPath:@"editing" options:NSKeyValueObservingOptionNew context:NULL];
    [_observedProperties addObject:@"editing"];
    [self.snippetItem addObserver:self forKeyPath:@"editingDesc" options:NSKeyValueObservingOptionNew context:NULL];
    [_observedProperties addObject:@"editingDesc"];
    [self.snippetItem addObserver:self forKeyPath:@"address" options:NSKeyValueObservingOptionNew context:NULL];
    [_observedProperties addObject:@"address"];
}
- (void)didLike:(CALObject *)likedObject newLikes:(int)likeCount newDislikes:(int)dislikesCount liked:(BOOL)liked {
    [self.tableView reloadData];
}

#pragma mark PMLUserCallback
- (void)user:(CurrentUser *)user didCheckInTo:(CALObject *)object previousLocation:(Place *)previousLocation {
    [self.tableView reloadData];
}
- (void)user:(CurrentUser *)user didCheckOutFrom:(Place *)object {
    [self.tableView reloadData];
}

#pragma mark - UITextFieldDelegate
- (void)titleTextChanged:(UITextField*) textField {
    if([_snippetItem isKindOfClass:[Place class]]) {
        ((Place*)_snippetItem).title = textField.text;
    }
}
-(void)updateAddress:(NSString*)newAddress {
    // Geolocating
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[[[TogaytherService uiService] menuManagerController] view] animated:NO];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"action.edit.address.geocoding", @"Geocoding address");
    [_conversionService geocodeAddress:newAddress intoObject:(Place*)_snippetItem completion:^(CALObject *calObject, CGFloat lat, CGFloat lng, BOOL success) {
        // Done
        [hud hide:YES];
    }];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == _snippetEditCell.addressTextField) {
        [self updateAddress:textField.text];
        return YES;
    } else {
        // Retrieving text
        NSString *inputText = textField.text;
        
        // Removing current input
        textField.text = nil;
        
        // Calling back
        if([_snippetItem isKindOfClass:[Place class]]) {
            // Only doing something if we have a valid text
            NSString *title = [inputText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if(title.length>0) {
                ((Place*)_snippetItem).title = inputText;
                PopupAction *action = [self.actionManager actionForType:PMLActionTypeConfirm];
                action.actionCommand();
            }
        }
        [self.tableView reloadData];
        return YES;
    }

}
#pragma mark - UITextViewDelegate
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if(_snippetItem.editingDesc) {
        _snippetItem.miniDesc = textView.text;
    }
    return YES;
}
#pragma mark - KVO Observing implementation
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([@"address" isEqualToString:keyPath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } else if([@"editing" isEqualToString:keyPath] || [@"editingDesc" isEqualToString:keyPath]) {
        NSLog(@"VALUE CHANGE: '%@' change catched from %p",keyPath,self);
//        dispatch_async(dispatch_get_main_queue(), ^{
            if(_snippetItem.editing || _snippetItem.editingDesc) {
                [self.tableView setContentOffset:CGPointMake(0, 0)];
                [self.parentMenuController minimizeCurrentSnippet:YES];
                [self installNavBarCommitCancel];
            } else if(!_snippetItem.editing && !_snippetItem.editingDesc && self.navigationItem.leftBarButtonItem!=self.navigationItem.backBarButtonItem) {
                [self uninstallNavBarCommitCancel];
            }
            [self.tableView reloadData];
//        });
    } else if([keyPath isEqualToString:@"mainImage"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_galleryCell.galleryView reloadData];
        });
    }
}
-(void)updateTitleEdition {

}
#pragma mark - Dragging control & scroll view
- (void)tableViewPanned:(UIPanGestureRecognizer*)recognizer {

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
                CGFloat delta = location.y - _dragStartPoint.y;
                if(_dragStartPoint.x == MAXFLOAT) {

                    BOOL snippetOpened = self.parentMenuController.snippetFullyOpened;
                    if(delta>0 && !snippetOpened) {
//                        [self.parentMenuController dismissControllerSnippet];
//                        return;
                    } else if(delta < 0 && snippetOpened) {
                        _parentDragging = NO;
//                        [self.parentMenuController dragSnippet:_dragStartPoint velocity:CGPointMake(0, 0) state:UIGestureRecognizerStateEnded];
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
- (void)adjustEditVisibility {
    // TODO Avoid the class test here
    if([_snippetItem isKindOfClass:[User class]] && ![_snippetItem.key isEqualToString:[[[TogaytherService userService] getCurrentUser] key]]) {
        return;
    }
    // Computing if we are at the bottom of the scroll view
    CGPoint offset = self.tableView.contentOffset;
    CGRect bounds = self.tableView.bounds;
    CGSize size = self.tableView.contentSize;
    UIEdgeInsets inset = self.tableView.contentInset;
    CGRect snippetFrame = self.parentMenuController.bottomView.frame;
    float y = offset.y + bounds.size.height - inset.bottom - snippetFrame.origin.y;
    float h = size.height;
    
    float reload_distance = 50;
    BOOL bottom = NO;
    if(y > (h - reload_distance)) {
        bottom = YES;
    }
    // Showing edit button if scrolled beyond gallery OR if already at the bottom of the screen
    if(_editVisible == PMLVisibityStateInvisible && (self.tableView.contentOffset.y >kPMLHeightGallery || bottom) && _opened) {
        _editVisible = PMLVisibityStateTransitioning;
        if(self.navigationItem.rightBarButtonItem==nil) {
            [self installNavBarEdit];
        }
        [UIView animateWithDuration:0.3 animations:^{
            self.navigationItem.rightBarButtonItem.customView.alpha=1;
        } completion:^(BOOL finished) {
            _editVisible = PMLVisibityStateVisible;
            
            // Showing help if needed
            if(_didOpened && [_snippetItem isKindOfClass:[Place class]]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:PML_HELP_EDIT object:self];
            }
        }];
    } else if(_editVisible == PMLVisibityStateVisible && self.tableView.contentOffset.y < kPMLHeightGallery && !bottom && _opened) {
        _editVisible = PMLVisibityStateTransitioning;

        [UIView animateWithDuration:0.3 animations:^{
            self.navigationItem.rightBarButtonItem.customView.alpha=0;
        } completion:^(BOOL finished) {
            _editVisible = PMLVisibityStateInvisible;
        }];
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
    // Setting edit button to appear / disappear
    [self adjustEditVisibility];

}
#pragma mark - NavBar management
- (void)installNavBarEdit {
    
    // Info provider informs us whether edit is supported or not by providing the actual edit implementation
    if([_infoProvider respondsToSelector:@selector(editActionType)]) {
        PMLActionType editType = [_infoProvider editActionType];
        if(editType!=PMLActionTypeNoAction) {
            UIBarButtonItem *barItem = [self barButtonItemFromAction:[_infoProvider editActionType] selector:@selector(navbarActionTapped:)];
            self.navigationItem.rightBarButtonItem = barItem;
            barItem.customView.alpha=0;
        } else {
            self.navigationItem.rightBarButtonItem=nil;
        }
    } else {
        if([_snippetItem.key isEqualToString:[[[TogaytherService userService] getCurrentUser] key]]) {
            UIBarButtonItem *barItem = [self barButtonItemFromAction:PMLActionTypeMyProfile selector:@selector(navbarActionTapped:)];
            //            _navbarEdit = YES;
            self.navigationItem.rightBarButtonItem = barItem;
            barItem.customView.alpha=0;
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
    }
    
    // Installing help
    if(self.navigationItem.rightBarButtonItem != nil && _opened) {
        CGRect rect = [self.navigationController.view convertRect:self.navigationItem.rightBarButtonItem.customView.frame toView:[self parentMenuController].view];
        // Help
        [[TogaytherService helpService] registerBubbleHint:[[PMLHelpBubble alloc] initWithRect:rect cornerRadius:15 helpText:NSLocalizedString(@"hint.edit",@"hint.edit") textPosition:PMLTextPositionLeft whenSnippetOpened:YES ] forNotification:PML_HELP_EDIT];
    }

}
-(void) installNavBarCommitCancel {
    UIBarButtonItem *commitItem = [self barButtonItemFromAction:PMLActionTypeConfirm selector:@selector(navbarActionTapped:)];
    self.navigationItem.rightBarButtonItem = commitItem;
    UIBarButtonItem *cancelItem = [self barButtonItemFromAction:PMLActionTypeCancel selector:@selector(navbarActionTapped:)];
    self.navigationItem.leftBarButtonItem = cancelItem;
    self.navigationController.navigationBar.alpha=1;
}
-(void)uninstallNavBarCommitCancel {
//    if(_navbarEdit) {
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;;
    [self installNavBarEdit];
//        self.navigationItem.rightBarButtonItem = nil;
        //        [self installNavBarEdit:_menuManagerController];
//    }
}
-(UIBarButtonItem*)barButtonItemFromAction:(PMLActionType)actionType selector:(SEL)selector {
    PopupAction *action = [_actionManager actionForType:actionType];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    button.layer.masksToBounds = YES;
    button.layer.borderWidth=1;
    button.layer.borderColor = [action.color CGColor];
    button.layer.cornerRadius = 15;
    button.alpha=1;
    [button setImage:action.icon forState:UIControlStateNormal];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    button.tag = actionType;
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return barItem;
}
- (void)uninstallNavBarEdit {
    UINavigationItem *navItem = self.navigationItem;
    navItem.rightBarButtonItem = nil;
    navItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
}
-(void)navbarActionTapped:(UIButton*)source {
    PopupAction *action = [_actionManager actionForType:(PMLActionType)source.tag];
    action.actionCommand();
}
#pragma  mark - PMLSnippetDelegate
- (void)menuManager:(PMLMenuManagerController *)menuManager snippetWillOpen:(BOOL)animated {
    _opened = YES;
    
    // Gallery management
    BOOL shouldAddGallery = !_hasGallery && _snippetItem!=nil;
    _hasGallery = YES;
    if(shouldAddGallery) {
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kPMLRowGallery inSection:kPMLSectionGallery]] withRowAnimation:UITableViewRowAnimationMiddle];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        if(animated) {
            // Setting edit button to appear / disappear
            [self adjustEditVisibility];
        }
    }
}
- (void)menuManagerSnippetDidOpen:(PMLMenuManagerController *)menuManager {
    _didOpened = YES;
}

-(void)menuManager:(PMLMenuManagerController *)menuManager snippetMinimized:(BOOL)animated {
    _opened = NO;
    _didOpened=NO;
    
    // Hiding NAV BAR
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    if(animated) {
        self.navigationItem.rightBarButtonItem=nil;
    }
    // Gallery management
    BOOL shouldRemoveGallery = _hasGallery && _snippetItem!=nil;
    _hasGallery = NO;
    if(shouldRemoveGallery) {
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kPMLRowGallery inSection:kPMLSectionGallery]] withRowAnimation:UITableViewRowAnimationTop];
    }
}
- (void)menuManager:(PMLMenuManagerController *)menuManager snippetPanned:(float)pctOpened {
    _galleryPctHeight = pctOpened;
}
- (PMLPopupActionManager *)actionManager {
    return _actionManager;
}

@end
