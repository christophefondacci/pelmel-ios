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
#import "PMLActionManager.h"
#import "PMLCountersView.h"
#import "UIImage+IPImageUtils.h"
#import "UITouchBehavior.h"
#import "PMLSnippetEditTableViewCell.h"
#import "PMLPropertyTableViewCell.h"
#import "PMLWebViewController.h"
#import "PMLEventPlaceTabsTitleView.h"
#import <MBProgressHUD.h>
#import <PBWebViewController.h>
#import "PMLCalObjectPhotoProvider.h"
#import "PMLCalendarTableViewController.h"
#import "PMLActivateDealTableViewCell.h"
#import "PMLDealTableViewCell.h"
#import "PMLReportingTableViewController.h"
#import "PMLDealDisplayTableViewCell.h"
#import "PMLUseDealViewController.h"


#define kPMLSettingActiveTab @"pmlActiveSnippetTab"

#define kPMLSectionsCount 19

#define kPMLSectionGallery 0
#define kPMLSectionSnippet 1
#define kPMLSectionCounters 4
#define kPMLSectionDeals 2
#define kPMLSectionDealsAdmin 3
#define kPMLSectionLocalization 5
#define kPMLSectionOvSummary 6
#define kPMLSectionOvAddress 7
#define kPMLSectionOvHours 8
#define kPMLSectionOvHappyHours 9
#define kPMLSectionOvProperties 10
#define kPMLSectionOvClaim 11
#define kPMLSectionOvEvents 12
#define kPMLSectionOvAdvertising 13
#define kPMLSectionOvDesc 14
#define kPMLSectionOvTags 15
#define kPMLSectionTopPlaces 16
#define kPMLSectionActivity 17
#define kPMLSectionButtons 18

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

#define kPMLRowDealActivateId @"dealActivate"
#define kPMLRowDealInfoId @"dealInfo"
#define kPMLRowDealDisplayId @"dealDisplay"
#define kPMLRowDealStatsButtonId @"dealStats"

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
#define kPMLHeightOvHoursTitleRows 30
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

#define kPMLReportRows 2
#define kPMLRowClaimButton 0
#define kPMLRowReportButton 1
#define kPMLHeightButton 62
#define kPMLRowButtonId @"buttonRow"
#define kPMLRowClaimButtonId @"claim"


#define kPMLHeightTopPlacesHeader 30


typedef enum {
    PMLVisibityStateTransitioning,
    PMLVisibityStateVisible,
    PMLVisibityStateInvisible
} PMLVisibityState;
@interface PMLSnippetTableViewController ()
@property (nonatomic,retain) NSDateFormatter *dateFormatter;
@property (nonatomic,retain) NSObject<PMLInfoProvider> *infoProvider;
@property (nonatomic,retain) NSMutableArray *deals;
@property (nonatomic,retain) UILabel *templateDescLabel;
@end

@implementation PMLSnippetTableViewController {
    
    // Inner controller for thumb listview
    PMLThumbCollectionViewController *_thumbController;
    PMLThumbCollectionViewController *_typesThumbController;
    PMLCountersView *_countersView;
    
    // Providers
    NSMutableArray *_observedProperties;
    PMLActionManager *_actionManager;
    
    // Cells
    PMLSnippetDescTableViewCell *_snippetDescCell;
    PMLGalleryTableViewCell *_galleryCell;
    PMLCountersTableViewCell *_countersCell;
    CAGradientLayer *_countersGradient;
    NSMutableDictionary *_countersPreviewGradients; // map of CAGradientLayer for likes/checkins gradients
    NSMutableDictionary *_heightsMap;
    PMLSnippetEditTableViewCell *_snippetEditCell;
    
    // Headers
    PMLEventPlaceTabsTitleView *_eventPlaceTabsTitleView;
    PMLTab _activeTab;
    PMLSectionTitleView *_sectionTitleView;
    PMLSectionTitleView *_sectionLocalizationTitleView;
    PMLSectionTitleView *_sectionSummaryTitleView;
    PMLSectionTitleView *_sectionTopPlacesTitleView;
    PMLSectionTitleView *_sectionActivityTitleView;
    PMLSectionTitleView *_sectionPropertiesTitleView;
    PMLSectionTitleView *_sectionDealsAdminTitleView;
    
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
    BOOL _isLoaded;

    
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
    _actionManager = [TogaytherService actionManager];
    self.infoProvider = [_uiService infoProviderFor:_snippetItem];
    _thumbPreviewMode = ThumbPreviewModeNone;
    _countersView = (PMLCountersView*)[_uiService loadView:@"PMLCountersView"];
    _heightsMap = [[NSMutableDictionary alloc] init];
    _hoursTypeMap = [[NSMutableDictionary alloc] init];
    _galleryPctHeight = 0;
    
    self.tableView.backgroundColor = BACKGROUND_COLOR;
    self.tableView.opaque=YES;
    self.tableView.separatorColor = BACKGROUND_COLOR;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    // Navigation
    [self hideNavigationBar];
    
    [self.tableView.panGestureRecognizer addTarget:self action:@selector(tableViewPanned:)];
    self.tableView.panGestureRecognizer.delaysTouchesBegan = YES;
    
    // Initializing external table view cells
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLEventTableViewCell" bundle:nil] forCellReuseIdentifier:kPMLRowEventId];
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLButtonTableViewCell" bundle:nil] forCellReuseIdentifier:kPMLRowAddEventId];
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLButtonTableViewCell" bundle:nil] forCellReuseIdentifier:kPMLRowButtonId];
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLActivateDealTableViewCell" bundle:nil] forCellReuseIdentifier:kPMLRowDealActivateId];
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLDealTableViewCell" bundle:nil] forCellReuseIdentifier:kPMLRowDealInfoId];
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLDealDisplayTableViewCell" bundle:nil] forCellReuseIdentifier:kPMLRowDealDisplayId];
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLClaimButtonViewCell" bundle:nil] forCellReuseIdentifier:kPMLRowClaimButtonId];
    // Loading header views
    _eventPlaceTabsTitleView = (PMLEventPlaceTabsTitleView*)[_uiService loadView:@"PMLEventPlaceTabsTitleView"];
    _eventPlaceTabsTitleView.delegate = self;
    _sectionTitleView = (PMLSectionTitleView*)[_uiService loadView:@"PMLSectionTitleView"];
    _sectionLocalizationTitleView = (PMLSectionTitleView*)[_uiService loadView:@"PMLSectionTitleView"];
    _sectionSummaryTitleView = (PMLSectionTitleView*)[_uiService loadView:@"PMLSectionTitleView"];
    _sectionTopPlacesTitleView = (PMLSectionTitleView*)[_uiService loadView:@"PMLSectionTitleView"];
    _sectionActivityTitleView = (PMLSectionTitleView*)[_uiService loadView:@"PMLSectionTitleView"];
    _sectionPropertiesTitleView = (PMLSectionTitleView*)[_uiService loadView:@"PMLSectionTitleView"];
    _sectionDealsAdminTitleView = (PMLSectionTitleView*)[_uiService loadView:@"PMLSectionTitleView"];
    // Tab selection
    [self updateTab];
    
    // Animation init
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.tableView];
    
    // Tab init
    NSNumber *activeTab = [[NSUserDefaults standardUserDefaults] objectForKey:kPMLSettingActiveTab];
    if(activeTab != nil) {
        _activeTab = activeTab.intValue;
        if([self tableView:self.tableView numberOfRowsInSection:kPMLSectionOvEvents]==0) {
            _activeTab = PMLTabPlaces;
        }
    }

    // Adjusting template description view size
    self.templateDescLabel = [[UILabel alloc] init];
    self.templateDescLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, 44);
    self.templateDescLabel.font = [UIFont fontWithName:PML_FONT_PRO size:17];
    self.templateDescLabel.numberOfLines=0;
    

    // Date formatter for deals
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];

}
- (void)viewWillAppear:(BOOL)animated {
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
    _editVisible = PMLVisibityStateVisible; //Invisible;
    [self adjustEditVisibility];
    
    if(_opened) {
        [self hideParentNavigationBar];
    }

    // Navigation
    if([_infoProvider respondsToSelector:@selector(hasNavigation)]) {
        if(![_infoProvider hasNavigation]) {
            [self.navigationController setNavigationBarHidden:YES];
        }
    }
}
- (void)viewDidAppear:(BOOL)animated {

    // Getting data
    [_dataService registerDataListener:self];
    [[TogaytherService userService] registerListener:self];
    if(_snippetItem != nil) {
        [_dataService getOverviewData:_snippetItem];
    } else {
        if(_isLoaded) {
            [self.tableView reloadData];
        } else {
            _isLoaded = YES;
        }
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
            case kPMLSectionDeals:
                return self.deals.count;
            case kPMLSectionDealsAdmin:
                if([_infoProvider respondsToSelector:@selector(deals)]) {
                    // Determining whether current user is owner
                    CurrentUser *user = [[TogaytherService userService] getCurrentUser];
                    BOOL isOwner = [[_infoProvider ownerKey] isEqualToString:user.key];
                    
                    NSInteger dealsRows = [[_infoProvider deals] count];
                    if(isOwner || user.isAdmin) {
                        // If no deal, section to add a deal
                        if(dealsRows == 0) {
                            dealsRows++;
                        }
                        // Last row for accessing stats
                        dealsRows++;
                        return dealsRows;
                    } else {
                        return 0;
                    }

                }
                return 0;
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
                if([_infoProvider respondsToSelector:@selector(properties)]) {
                    return [[_infoProvider properties] count];
                }
                return 0;
            case kPMLSectionOvHours: {
                NSInteger count = [[_hoursTypeMap objectForKey:SPECIAL_TYPE_OPENING] count];
                return count == 0 ? 0 : count+1;
            }
            case kPMLSectionOvHappyHours: {
                NSInteger count = [[_hoursTypeMap objectForKey:SPECIAL_TYPE_HAPPY] count];
                return count == 0 ? 0 : count+1;
            }
            case kPMLSectionOvClaim:
                if( [_snippetItem isKindOfClass:[Place class]]) {
                    return ((Place*)_snippetItem).ownerKey==nil ? 1 : 0;
                }
                return 0;
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
            case kPMLSectionOvAdvertising:
                if([_infoProvider respondsToSelector:@selector(advertisingActionType)]) {
                    return [_infoProvider advertisingActionType] == PMLActionTypeNoAction? 0 : 1;
                } else {
                    return 0;
                }
            case kPMLSectionOvDesc:
                return [[_infoProvider descriptionText] length]>0 ? kPMLOvDescRows : 0;
            case kPMLSectionOvTags: {
                double rows = (double)_snippetItem.tags.count / (double)kPMLMaxTagsPerRow; //((double)tableView.bounds.size.width / (double)kPMLOvTagWidth);
                return (int)ceil(rows);
            }
            case kPMLSectionButtons: {
                NSInteger rowCount = 0;
                if([_infoProvider respondsToSelector:@selector(footerButtonsCount)]) {
                    rowCount = [_infoProvider footerButtonsCount];
                }
                
                return rowCount;
            }

        }
    } else {
        switch(section) {
            case kPMLSectionSnippet:
                return 1;
            case kPMLSectionActivity:
                return 0;
            case kPMLSectionTopPlaces:
                return 0;//[[_infoProvider topPlaces] count];
            case kPMLSectionOvEvents:
                switch(_activeTab) {
                    case PMLTabEvents:
                        if([_infoProvider respondsToSelector:@selector(events)]) {
                            return [[_infoProvider events] count];
                        }
                        return 0;
                    case PMLTabPlaces:
                        return [[_infoProvider topPlaces] count];
                    case PMLTabDeals:
                        return [[[_dataService modelHolder] happyHours] count];
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
        case kPMLSectionDeals:
            return kPMLRowDealDisplayId;
        case kPMLSectionDealsAdmin: {
            CurrentUser *user = [[TogaytherService userService] getCurrentUser];
            NSInteger dealsCount = [[_infoProvider deals] count];
            BOOL isOwner = [[_infoProvider ownerKey] isEqualToString:user.key] || user.isAdmin;
            if(isOwner) {
                // No deals, owner, first row => deal activation row
                if(indexPath.row == 0 && dealsCount == 0) {
                    return kPMLRowDealActivateId;
                } else if(indexPath.row < dealsCount) {
                    return kPMLRowDealInfoId;
                } else {
                    return kPMLRowButtonId;
                }
            } else {
                return 0;
            }
        }
        case kPMLSectionLocalization:
            return kPMLRowEventId;
        case kPMLSectionOvEvents:
            if(_snippetItem != nil || (_snippetItem == nil && _activeTab == PMLTabEvents)) {
                if(indexPath.row<[[_infoProvider events] count]) {
                    return kPMLRowEventId;
                } else {
                    return kPMLRowAddEventId;
                }
            } else if(_activeTab==PMLTabPlaces) {
                return kPMLRowEventId;
            } else if(_activeTab ==PMLTabDeals) {
                return kPMLRowEventId;
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
            return kPMLRowOvImagedTitleId;
        case kPMLSectionOvHours:
            return indexPath.row == 0 ? @"hoursTitle" : kPMLRowTextId;
        case kPMLSectionOvHappyHours:
            return indexPath.row == 0 ? @"hoursTitle" : kPMLRowTextId;
        case kPMLSectionOvClaim:
            return kPMLRowClaimButtonId;
        case kPMLSectionOvAdvertising:
            return kPMLRowButtonId;
        case kPMLSectionOvDesc:
            return kPMLRowDescId;
        case kPMLSectionOvTags:
            return kPMLRowOvTagsId;
        case kPMLSectionTopPlaces:
            return kPMLRowEventId;
        case kPMLSectionButtons:
            return kPMLRowButtonId;

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
        case kPMLSectionDeals:
            [self configureRowDisplayDeal:(PMLDealDisplayTableViewCell*)cell forIndex:indexPath.row];
            break;
        case kPMLSectionDealsAdmin: {
            CurrentUser *user = [[TogaytherService userService] getCurrentUser];
            NSInteger dealsCount = [[_infoProvider deals] count];
            BOOL isOwner = [[_infoProvider ownerKey] isEqualToString:user.key] || user.isAdmin;
            if(isOwner) {
                if(indexPath.row == 0 && dealsCount == 0) {
                    [self configureRowActivateDeal:(PMLActivateDealTableViewCell*)cell];
                } else if(indexPath.row < dealsCount) {
                    [self configureRowAdminDeal:(PMLDealTableViewCell*)cell forIndex:indexPath.row];
                } else {
                    [self configureRowPlaceReportButton:(PMLButtonTableViewCell*)cell];
                }
            }
            break;
        }
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
            [self configureRowProperty:(PMLImagedTitleTableViewCell*)cell atIndex:indexPath.row];
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
        case kPMLSectionOvClaim:
            [self configureRowClaim:(PMLButtonTableViewCell*)cell];
             break;
        case kPMLSectionOvEvents:
            if(_snippetItem != nil || (_snippetItem == nil && _activeTab==PMLTabEvents)) {
                if(indexPath.row < [[_infoProvider events] count]) {
                    [self configureRowOvEvents:(PMLEventTableViewCell*)cell atIndex:indexPath.row];
                } else {
                    [self configureRowOvAddEvent:(PMLButtonTableViewCell*)cell];
                }
            } else if(_activeTab == PMLTabPlaces) {
                [self configureRowTopPlace:(PMLEventTableViewCell*)cell atIndex:indexPath.row];
            } else if(_activeTab == PMLTabDeals) {
                [self configureRowOvHappyHours:(PMLEventTableViewCell*)cell atIndex:indexPath.row];
            }
            break;
        case kPMLSectionOvAdvertising:
            [self configureRowAdvertising:(PMLButtonTableViewCell*)cell];
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
            // Should no longer be used, now part of the event section for proper tab headers
            [self configureRowTopPlace:(PMLEventTableViewCell*)cell atIndex:indexPath.row];
            break;
        case kPMLSectionButtons:
            [self configureRowButton:(PMLButtonTableViewCell*)cell forIndex:indexPath.row];
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
        case kPMLSectionDeals: {
            PMLDeal *deal = [self.deals objectAtIndex:indexPath.row];
            if([[TogaytherService dealsService] isDealUsable:deal considerCheckinDistance:NO]) {
                return 111;
            } else {
                return 82;
            }
            break;
        }
        case kPMLSectionDealsAdmin: {
            NSString *rowId = [self rowIdForIndexPath:indexPath];
            if([rowId isEqualToString:kPMLRowDealActivateId]) {
                return 146;
            } else if([rowId isEqualToString:kPMLRowDealInfoId]) {
                return 85;
            } else if([rowId isEqualToString:kPMLRowButtonId]) {
                return kPMLHeightButton;
            }
            break;
        }
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
            return kPMLHeightOvImagedTitle;
        case kPMLSectionOvHours:
            return indexPath.row == 0 ? kPMLHeightOvHoursTitleRows : kPMLHeightOvHoursRows;
        case kPMLSectionOvHappyHours:
            return indexPath.row == 0 ? kPMLHeightOvHoursTitleRows : kPMLHeightOvHoursRows;
        case kPMLSectionOvClaim:
            return 80;
        case kPMLSectionOvEvents:
            if(_snippetItem!=nil || (_snippetItem==nil && _activeTab == PMLTabEvents)) {
                if(indexPath.row<[[_infoProvider events] count]) {
                    return kPMLHeightOvEventRows;
                } else {
                    return kPMLHeightOvAddEventRow;
                }
            } else if(_activeTab == PMLTabPlaces) {
                return kPMLHeightOvEventRows;
            } else if(_activeTab == PMLTabDeals) {
                return kPMLHeightOvEventRows;
            }
        case kPMLSectionOvAdvertising:
            return kPMLHeightButton;
        case kPMLSectionOvDesc: {
            if(_readMoreSize == 0) {
                self.templateDescLabel.text = _infoProvider.descriptionText;
                CGSize expectedSize = [self.templateDescLabel sizeThatFits:CGSizeMake(self.view.bounds.size.width-40, MAXFLOAT)];
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
        case kPMLSectionButtons:
            return kPMLHeightButton;
    }
    return 44;

}
- (BOOL)isOwner {
    CurrentUser *user = [[TogaytherService userService] getCurrentUser];
    if([_infoProvider respondsToSelector:@selector(ownerKey)]) {
        return user.isAdmin || [_infoProvider.ownerKey isEqualToString:user.key];
    }
    return NO;

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
                    if(_snippetItem!=nil) {
                        return _sectionTitleView;
                    } else {
                        [_eventPlaceTabsTitleView setActiveTab:_activeTab];
                        return _eventPlaceTabsTitleView;
                    }
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
        case kPMLSectionDealsAdmin:
            // Must be owner
            if([self isOwner]) {
                // Must be eligible to deals
                if([_infoProvider respondsToSelector:@selector(deals)]) {
                    _sectionDealsAdminTitleView.titleLabel.text = NSLocalizedString(@"deal.admin.sectionTitle", @"Manage your deals");
                    _sectionDealsAdminTitleView.backgroundColor = [UIColor blackColor];
                    return _sectionDealsAdminTitleView;
                }
            }
            return nil;
        case kPMLSectionOvSummary: {
            [_sectionSummaryTitleView setTitleLocalized:@"snippet.title.summary"];
            return _sectionSummaryTitleView;
        }
        case kPMLSectionOvProperties:
            [_sectionPropertiesTitleView setTitleLocalized:@"snippet.title.properties"];
            return _sectionPropertiesTitleView;
        case kPMLSectionTopPlaces:
//            [_sectionTopPlacesTitleView setTitleLocalized:@"snippet.header.topPlaces"];
//            return _sectionTopPlacesTitleView;
            return nil;
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
            case kPMLSectionOvProperties:
                if([_infoProvider respondsToSelector:@selector(properties)]) {
                    if([[_infoProvider properties] count]>0) {
                        return _sectionPropertiesTitleView.bounds.size.height;
                    } else {
                        return 0;
                    }
                }
                break;
            case kPMLSectionDealsAdmin:
                // Must be owner
                if([self isOwner]) {
                    // Must be eligible to deals
                    if([_infoProvider respondsToSelector:@selector(deals)]) {
                        return _sectionDealsAdminTitleView.bounds.size.height;
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
            case kPMLSectionTopPlaces:
//                if([[_infoProvider topPlaces] count ]>0) {
//                    return kPMLHeightTopPlacesHeader;
//                } else {
                    return 0;
//                }
            case kPMLSectionOvEvents:
                if([_infoProvider respondsToSelector:@selector(eventsSectionTitle)]) {
                    if([_infoProvider eventsSectionTitle]!=nil && ([[_infoProvider events] count]>0 || [[[_dataService modelHolder] happyHours] count]>0)) {
//                        return _sectionTitleView.bounds.size.height;
                        return _eventPlaceTabsTitleView.bounds.size.height;
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
        case kPMLSectionButtons:
        case kPMLSectionOvAdvertising:
        case kPMLSectionOvHours:
        case kPMLSectionOvHappyHours:
        case kPMLSectionOvClaim:
            return YES;
        case kPMLSectionDeals: {
            PMLDeal *deal = [self.deals objectAtIndex:indexPath.row];
            return deal.lastUsedDate == nil || [deal.lastUsedDate timeIntervalSinceNow] < -PML_DEAL_MIN_REUSE_SECONDS;
        }
        case kPMLSectionDealsAdmin:
            return ([kPMLRowButtonId isEqualToString:[self rowIdForIndexPath:indexPath]]);
        case kPMLSectionOvProperties: {
            PMLProperty *p = [[_infoProvider properties] objectAtIndex:indexPath.row];
            return [p.propertyCode isEqualToString:@"website"] || [p.propertyCode isEqualToString:@"phone"];
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
        case kPMLSectionDeals:
            [self useDealTapped:nil];
            break;
        case kPMLSectionDealsAdmin:
            if([kPMLRowButtonId isEqualToString:[self rowIdForIndexPath:indexPath]]) {
                PMLReportingTableViewController *controller = (PMLReportingTableViewController*)[_uiService instantiateViewController:SB_ID_REPORTING];
                controller.reportingPlace = (Place*)_snippetItem;
                [[[_uiService menuManagerController] navigationController] pushViewController:controller animated:YES];
            }
            break;
        case kPMLSectionOvAddress:
            [_actionManager execute:PMLActionTypeDirections onObject:_snippetItem];
//            self.tableView.contentOffset = CGPointMake(0,0);
//            if([_infoProvider respondsToSelector:@selector(mapObjectForLocalization)]) {
//                CALObject *localizationObj = [_infoProvider mapObjectForLocalization];
//                if(localizationObj!=nil) {
//                    [self.parentMenuController minimizeCurrentSnippet:YES];
//                    [self.parentMenuController.rootViewController selectCALObject:localizationObj];
//                }
//            }
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        case kPMLSectionOvProperties: {
            PMLProperty *p = [[_infoProvider properties] objectAtIndex:indexPath.row];
            if([p.propertyCode isEqualToString:@"website"]) {
                [_actionManager execute:PMLActionTypeWebsite onObject:_snippetItem];
            } else if([p.propertyCode isEqualToString:@"phone"]) {
                [_actionManager execute:PMLActionTypePhoneCall onObject:_snippetItem];
            }
            break;
        }
        case kPMLSectionOvHours:
        case kPMLSectionOvHappyHours: {
            PMLCalendarTableViewController *calendarController = (PMLCalendarTableViewController*)[_uiService instantiateViewController:@"calendarEditor"];
            if([_snippetItem isKindOfClass:[Place class]]) {
                calendarController.place = (Place*)_snippetItem;
                [(UINavigationController*)_uiService.menuManagerController.currentSnippetViewController pushViewController:calendarController animated:YES];
            }
            break;
        }
        case kPMLSectionLocalization: {
            CALObject *locationObject = [_infoProvider mapObjectForLocalization];
            [_uiService presentSnippetFor:locationObject opened:YES];
            break;
        }
        case kPMLSectionOvAdvertising:
            [_actionManager execute:[_infoProvider advertisingActionType] onObject:_snippetItem];
            break;
        case kPMLSectionOvEvents:
            if(_snippetItem != nil || (_snippetItem==nil && _activeTab == PMLTabEvents)) {
                if(indexPath.row == [[_infoProvider events] count]) {
                    [self addEventTapped];
                } else {
                    Event *event = [[_infoProvider events] objectAtIndex:indexPath.row];
                    [self pushSnippetFor:event];
                }
            } else if(_activeTab == PMLTabPlaces) {
                [self topPlaceTapped:indexPath.row];
            } else if(_activeTab == PMLTabDeals) {
                [self dealsTapped:indexPath.row];
            }
            break;
        case kPMLSectionOvClaim:
            [_actionManager execute:PMLActionTypeClaim onObject:_snippetItem];
            break;
            
        case kPMLSectionButtons: {
            [_actionManager execute:[_infoProvider footerButtonActionAtIndex:indexPath.row] onObject:_snippetItem];
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

//    if(_infoProvider.title == nil) {
//        cell.titleLabel.text = NSLocalizedString(@"snippet.title.notitle", @"Tap to enter a name");
//    } else {
        cell.titleLabel.text = _infoProvider.title;
//    }
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
        id<PMLCountersDatasource> datasource = [_infoProvider countersDatasource];
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
    [cell.galleryView reloadData];
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
        [cell.addPhotoButton setBackgroundImage:action.icon forState:UIControlStateNormal];
    } else {
        cell.addPhotoButton.hidden=YES;
    }
    
    cell.reportPhotoButton.tag = PMLActionTypeReportForDeletion;
    [cell.reportPhotoButton addTarget:self action:@selector(actionReportPhotoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    cell.reportPhotoButton.alpha=0.7;
    cell.reportPhotoButton.hidden = (_snippetItem.mainImage==nil);
    
    cell.secondaryButton.hidden=YES;
    cell.secondaryButtonTitle.hidden=YES;

}
-(void)actionReportPhotoButtonTapped:(UIButton*)source {
    NSInteger currentImage = _galleryCell.galleryView.currentPage;
    CALImage *image = [_snippetItem imageAtIndex:currentImage];
    [_actionManager execute:(PMLActionType)source.tag onObject:image];
}
-(void)actionButtonTapped:(UIButton*)source {
    [_actionManager execute:(PMLActionType)source.tag onObject:_snippetItem];
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
    cell.cellTextLabel.textColor = [UIColor whiteColor];

}
-(void)configureRowProperty:(PMLImagedTitleTableViewCell*)cell atIndex:(NSInteger)row {
    PMLProperty *property = [[_infoProvider properties] objectAtIndex:row];
    
    // Decoding property code
//    NSString *labelCode = [NSString stringWithFormat:@"property.label.%@",property.propertyCode];
//    NSString *label = NSLocalizedString(labelCode, labelCode);
//    if([label isEqualToString:labelCode]) {
//        label = property.defaultLabel;
//    }
    cell.titleLabel.text = property.propertyValue;
    CGSize size = [cell.titleLabel sizeThatFits:CGSizeZero];
    cell.widthTitleConstraint.constant = size.width;
    if([@"phone" isEqualToString:property.propertyCode]) {
        cell.titleImage.image = [UIImage imageNamed:@"btnActionPhone"];
    } else {
        cell.titleImage.image = [UIImage imageNamed:@"btnActionLink"];
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
//        cell.cellTextLabel.font = [UIFont fontWithName:PML_FONT_SARI_MEDIUM size:16];
        cell.cellTextLabel.textColor = UIColorFromRGB(0xababac);
    } else {
        cell.cellTextLabel.text = nil;
    }
}
-(void)configureRowOvHoursTitle:(PMLTextTableViewCell*)cell {
//    cell.cellTextLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:14];
    cell.cellTextLabel.textColor = UIColorFromRGB(0x72ff00);
    cell.cellTextLabel.text = NSLocalizedString(@"snippet.title.hours", @"Opening hours");
}
-(void)configureRowOvHappyHoursTitle:(PMLTextTableViewCell*)cell {
//    cell.cellTextLabel.font = [UIFont fontWithName:PML_FONT_SARI_MEDIUM size:18];
    cell.cellTextLabel.textColor = UIColorFromRGB(0xfff600);
    cell.cellTextLabel.text = NSLocalizedString(@"snippet.title.happyhours", @"Happy hours");
}
-(void)configureRowClaim:(PMLButtonTableViewCell*)cell {
    cell.buttonLabel.text = NSLocalizedString(@"snippet.button.claim", @"snippet.button.claim");
    cell.buttonSubtitleLabel.text = NSLocalizedString(@"snippet.button.claim.subtitle", @"snippet.button.claim.subtitle");
}
-(void)configureRowOvEvents:(PMLEventTableViewCell*)cell atIndex:(NSInteger)row {
    Event *event = [[_infoProvider events] objectAtIndex:row];
    [_uiService configureRowOvEvents:cell forEvent:event usingInfoProvider:_infoProvider];
    //    cell.backgroundColor = UIColorFromRGB(0x31363a);
}
-(void)configureRowOvHappyHours:(PMLEventTableViewCell*)cell atIndex:(NSInteger)row {
    Event *event = [[[_dataService modelHolder] happyHours] objectAtIndex:row];
    [_uiService configureRowOvEvents:cell forEvent:event usingInfoProvider:_infoProvider];
}
-(void)configureRowOvAddEvent:(PMLButtonTableViewCell*)cell {
    cell.buttonLabel.text = NSLocalizedString(@"events.addButton", @"Create and promote an event");
    cell.buttonImageView.image = [UIImage imageNamed:@"evtButtonAdd"];
}
-(void)configureRowLocalization:(PMLEventTableViewCell*)cell {

    // Getting provider of location object
    CALObject *mapObject = [_infoProvider mapObjectForLocalization];
    
    // Loading localization object because we are displaying it
    if(!mapObject.hasOverviewData) {
        [[TogaytherService dataService] getOverviewData:mapObject];
    }

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
-(void)configureRowTopPlace:(PMLEventTableViewCell*)cell atIndex:(NSInteger)row {
    Place *place = [[_infoProvider topPlaces] objectAtIndex:row];
    [_uiService configureRowPlace:cell place:place];
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

-(void) configureRowButton:(PMLButtonTableViewCell*)cell forIndex:(NSInteger)index {
    cell.buttonImageView.image = [_infoProvider footerButtonIconAtIndex:index];
    cell.buttonLabel.text = [_infoProvider footerButtonTextAtIndex:index];
    cell.buttonContainer.backgroundColor = [_infoProvider footerButtonColorAtIndex:index];
}

-(void) configureRowAdvertising:(PMLButtonTableViewCell*)cell {
    cell.buttonImageView.image = [UIImage imageNamed:@"btnAddBanner"];
    cell.buttonLabel.text = NSLocalizedString(@"banner.button.addPlaceBanner", @"banner.button.addPlaceBanner");
    cell.buttonContainer.backgroundColor = [UIColor clearColor];
}
-(void)configureRowActivateDeal:(PMLActivateDealTableViewCell*)cell {
    cell.backgroundColor = [UIColor blackColor];
    cell.activateHeadlineLabel.text = NSLocalizedString(@"deal.activate.headline", @"Get MORE clients!");
    [cell.activateButton setTitle:NSLocalizedString(@"deal.activate.button", @"Activate your deal now") forState:UIControlStateNormal];
    [cell.activateButton addTarget:self action:@selector(didTapActivateDeal:) forControlEvents:UIControlEventTouchUpInside];
}
- (void)configureRowAdminDeal:(PMLDealTableViewCell*)cell forIndex:(NSInteger)index {
    PMLDeal *deal = [[_infoProvider deals] objectAtIndex:index];
    NSString *statusCode = [NSString stringWithFormat:@"deal.status.%@",deal.dealStatus];
    NSString *statusLabel= NSLocalizedString(statusCode, statusCode);
    NSString *dealTypeCode = [NSString stringWithFormat:@"deal.type.%@",deal.dealType];
    NSString *dealType = NSLocalizedString(dealTypeCode,dealTypeCode);
    
    cell.backgroundColor = [UIColor blackColor];
    cell.dealHeadlineLabel.text = dealType;
    cell.statusLabel.text = statusLabel;
    cell.statusIntroLabel.text = NSLocalizedString(@"deal.status", @"STATUS");
    
    // Setuping play/pause button
    if([deal.dealStatus isEqualToString:DEAL_STATUS_RUNNING]) {
        [cell.dealActivationButton setImage:[UIImage imageNamed:@"btnPauseGrey"] forState:UIControlStateNormal];
        cell.statusLabel.textColor = UIColorFromRGB(0x5ED303);
        cell.dealHeadlineLabel.textColor = UIColorFromRGB(0x5ED303);
    } else {
        [cell.dealActivationButton setImage:[UIImage imageNamed:@"btnPlayGreen"] forState:UIControlStateNormal];
        cell.statusLabel.textColor = UIColorFromRGB(0x717171);
        cell.dealHeadlineLabel.textColor = UIColorFromRGB(0x717171);
    }
    
    // Setuping callback for play/pause button
    cell.dealActivationButton.tag=index;
    [cell.dealActivationButton addTarget:self action:@selector(didTapDealPlayPauseButton:) forControlEvents:UIControlEventTouchUpInside];
    
    // Setuping quota text
    if(deal.maxUses > 0 ) {
        NSString *template = NSLocalizedString(@"deal.condition.max", @"deal.condition.max");
        NSString *label = [NSString stringWithFormat:template, deal.maxUses];
        [cell.dealQuotaLabelButton setTitle:label forState:UIControlStateNormal];
    } else {
        [cell.dealQuotaLabelButton setTitle:NSLocalizedString(@"deal.condition.nomax", @"deal.condition.nomax") forState:UIControlStateNormal];
    }
    cell.dealQuotaWidthConstraint.constant = [cell.dealQuotaLabelButton sizeThatFits:CGSizeMake(MAXFLOAT, cell.dealQuotaLabelButton.bounds.size.height)].width;
    
    // Quota edit callback
    cell.dealQuotaEditButton.tag=index;
    [cell.dealQuotaLabelButton addTarget:self action:@selector(didTapEditDealQuota:) forControlEvents:UIControlEventTouchUpInside];
    [cell.dealQuotaEditButton addTarget:self action:@selector(didTapEditDealQuota:) forControlEvents:UIControlEventTouchUpInside];

}
-(void) configureRowPlaceReportButton:(PMLButtonTableViewCell*)cell {
    cell.backgroundColor = [UIColor blackColor];
    cell.buttonLabel.text= NSLocalizedString(@"deal.report.button", @"deal.report.button");
    cell.buttonImageView.image = [UIImage imageNamed:@"icoClaimStats"];
    cell.buttonContainer.backgroundColor = [UIColor clearColor];
    
}
-(void)configureRowDisplayDeal:(PMLDealDisplayTableViewCell*)cell forIndex:(NSInteger)row {
    PMLDeal *deal = [[_infoProvider deals] objectAtIndex:row];
    NSString *dealTypeCode = [NSString stringWithFormat:@"deal.type.%@",deal.dealType];
    NSString *dealType = NSLocalizedString(dealTypeCode,dealTypeCode);
    cell.dealTitle.text = dealType;
    cell.useDealButton.hidden = ![[TogaytherService dealsService] isDealUsable:deal considerCheckinDistance:NO];
    cell.dealConditionLabel.text = [[TogaytherService dealsService] dealConditionLabel:deal];

    
    [cell.useDealButton setTitle:NSLocalizedString(@"deal.use.button", @"Use this deal") forState:UIControlStateNormal];
    cell.useDealButton.userInteractionEnabled=NO;
//    [cell addTarget:self action:@selector(useDealTapped:) forControlEvents:UIControlEventTouchUpInside];
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

        UITouchBehavior *touch = [[UITouchBehavior alloc] initWithTarget:_countersView.likeIcon];
        [touch setMagnitude:0.5];
        [_animator removeAllBehaviors];
        [_animator addBehavior:touch];
        // Executing action
        [_actionManager execute:type onObject:_snippetItem];

    }
}
-(void)checkinTapped {
    PMLActionType type = [self checkinAction];
    if(type != PMLActionTypeNoAction) {

        UITouchBehavior *touch = [[UITouchBehavior alloc] initWithTarget:_countersView.checkinIcon];
        [touch setMagnitude:0.5];
        [_animator removeAllBehaviors];
        [_animator addBehavior:touch];
        
        // Executing action
        [_actionManager execute:type onObject:_snippetItem];
    }
}
-(void)commentTapped {
    PMLActionType type = [self commentAction];
    if(type != PMLActionTypeNoAction) {
        UITouchBehavior *touch = [[UITouchBehavior alloc] initWithTarget:_countersView.commentsIcon];
        [touch setMagnitude:0.5];
        [_animator removeAllBehaviors];
        [_animator addBehavior:touch];
        
        // Executing action
        [_actionManager execute:type onObject:_snippetItem];

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
-(void)dealsTapped:(NSInteger)index {
    CALObject *deal = [[[_dataService modelHolder] happyHours] objectAtIndex:index];
    [self pushSnippetFor:deal];
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

    // Executing action
    [_actionManager execute:PMLActionTypeEditEvent onObject:_snippetItem];
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
        [_actionManager execute:PMLActionTypeConfirm onObject:_snippetItem];
    }
    [self.tableView reloadData];
    
}
-(void)editOkTapped:(id)sender {
    if(![_snippetEditCell.addressTextField.text isEqualToString:((Place*)_snippetItem).address]) {
        [self updateAddress:_snippetEditCell.addressTextField.text];
    } else {
        [_actionManager execute:PMLActionTypeConfirm onObject:_snippetItem];
    }
}
-(void)editCancelTapped:(id)sender {
    [_actionManager execute:PMLActionTypeCancel onObject:_snippetItem];
}
#pragma mark - PMLImageGalleryDelegate
- (void)imageTappedAtIndex:(int)index image:(CALImage *)image {
    PMLPhotosCollectionViewController *photosController = (PMLPhotosCollectionViewController*)[_uiService instantiateViewController:SB_ID_PHOTOS_COLLECTION];
    photosController.provider = [[PMLCalObjectPhotoProvider alloc] initWithObject:_snippetItem];
    [self.navigationController pushViewController:photosController animated:YES];
//    [self toggleFullscreenGallery];
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
            [_actionManager execute:PMLActionTypeAddPhoto onObject:_snippetItem];
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
        self.infoProvider = [_uiService infoProviderFor:object];
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
    self.infoProvider = [TogaytherService.uiService infoProviderFor:_snippetItem];
    [self updateTab];
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

- (void)setInfoProvider:(NSObject<PMLInfoProvider> *)infoProvider {
    // Assigning
    _infoProvider = infoProvider;
    [self refreshDeals];
}
-(void)refreshDeals {
    // Computing deals
    self.deals = [[NSMutableArray alloc] init];
    if([_infoProvider respondsToSelector:@selector(deals)]) {
        for(PMLDeal *deal in [_infoProvider deals]) {
            if([deal.dealStatus isEqualToString:DEAL_STATUS_RUNNING]) {
                [self.deals addObject:deal];
            }
        }
    }
}
-(void)updateTab {
    if([_infoProvider respondsToSelector:@selector(events)]) {
        if([[_infoProvider events] count]>0) {
            _activeTab = PMLTabEvents;
        } else {
            _activeTab = PMLTabPlaces;
        }
    } else {
        _activeTab = PMLTabPlaces;
    }
    [_eventPlaceTabsTitleView setActiveTab:_activeTab];
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
-(void)userDidChangePrivateNetwork:(CurrentUser *)user {
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
                [_actionManager execute:PMLActionTypeConfirm onObject:_snippetItem];
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
//
            if(_snippetItem.editing || _snippetItem.editingDesc) {
                [self.tableView setContentOffset:CGPointMake(0, 0)];
                [self.parentMenuController minimizeCurrentSnippet:YES];
                [self installNavBarCommitCancel];
            } else if(!_snippetItem.editing && !_snippetItem.editingDesc && self.navigationItem.leftBarButtonItem!=self.navigationItem.backBarButtonItem) {
                [self uninstallNavBarCommitCancel];
            }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
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

    if(self.parentMenuController.navigationController == self.navigationController) {
        return;
    }
    switch(recognizer.state) {
        case UIGestureRecognizerStateBegan:
            if (abs((int)self.tableView.contentOffset.y) < kPMLHeightSnippet) {
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
    if(self.navigationItem.rightBarButtonItem==nil) {
        [self installNavBarEdit];
    }
    _editVisible = PMLVisibityStateVisible;
    // Showing help if needed
    if([_snippetItem isKindOfClass:[Place class]]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PML_HELP_EDIT object:self];
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
//    [self adjustEditVisibility];

}
#pragma mark - NavBar management
- (void)installNavBarEdit {
    
    // Info provider informs us whether edit is supported or not by providing the actual edit implementation
    if([_infoProvider respondsToSelector:@selector(editActionType)]) {
        PMLActionType editType = [_infoProvider editActionType];
        if(editType!=PMLActionTypeNoAction) {
            UIBarButtonItem *barItem = [self barButtonItemFromAction:[_infoProvider editActionType] selector:@selector(navbarActionTapped:)];
            self.navigationItem.rightBarButtonItem = barItem;
            
        } else {
            self.navigationItem.rightBarButtonItem=nil;
        }
    } else {
        self.navigationItem.rightBarButtonItem = nil;
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
    [_actionManager execute:(PMLActionType)source.tag onObject:_snippetItem];
}
-(void)hideNavigationBar {
    if(self.navigationController != self.parentMenuController.navigationController) {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
}
-(void)hideParentNavigationBar {
    if(self.navigationController != self.parentMenuController.navigationController) {
        [self.parentMenuController.navigationController setNavigationBarHidden:YES animated:YES];
    }
}
#pragma  mark - PMLSnippetDelegate
- (void)menuManager:(PMLMenuManagerController *)menuManager snippetWillOpen:(BOOL)animated {
    _opened = YES;
    
    // Gallery management
    BOOL shouldAddGallery = !_hasGallery && _snippetItem!=nil;
    _hasGallery = YES;
    if(shouldAddGallery) {
        @try {
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kPMLRowGallery inSection:kPMLSectionGallery]] withRowAnimation:UITableViewRowAnimationMiddle];
        } @catch(NSException *e) {
            [self.tableView reloadData];
        }
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
    [self hideNavigationBar];
    if(animated) {
        self.navigationItem.rightBarButtonItem=nil;
    }
    // Gallery management
    BOOL shouldRemoveGallery = _hasGallery && _snippetItem!=nil;
    _hasGallery = NO;
    if(shouldRemoveGallery) {
        @try {
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kPMLRowGallery inSection:kPMLSectionGallery]] withRowAnimation:UITableViewRowAnimationTop];
        } @catch(NSException *e) {
            [self.tableView reloadData];
        }
    }
}
- (void)menuManager:(PMLMenuManagerController *)menuManager snippetPanned:(float)pctOpened {
    _galleryPctHeight = pctOpened;
}

#pragma mark - PMLEventPlaceTabsDelegate
- (BOOL)eventsTabTapped {
    if([_infoProvider respondsToSelector:@selector(events)]) {
        if([[_infoProvider events] count]>0) {
            _activeTab = PMLTabEvents;
            [self updateScrollOffset];
            [self.tableView reloadData];
            [self saveActiveTab];
            return YES;
        }
    }

    return NO;
    
}
-(void)saveActiveTab {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:_activeTab] forKey:kPMLSettingActiveTab];
}
- (BOOL)placesTabTapped {
    if([[_infoProvider topPlaces] count]>0) {
        _activeTab = PMLTabPlaces;
        [self updateScrollOffset];
        [self.tableView reloadData];
        [self saveActiveTab];
        return YES;
    }

    return NO;
}
- (void)updateScrollOffset {
    NSInteger height = [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:kPMLRowSnippet inSection:kPMLSectionSnippet]];
    if(self.tableView.contentOffset.y>height) {
        [self.tableView setContentOffset:CGPointMake(0, height)];
    }
}
- (BOOL)dealsTabTapped {

    _activeTab = PMLTabDeals;
    [self updateScrollOffset];
    [self.tableView reloadData];
    [self saveActiveTab];
    return YES;
}
-(void)didTapActivateDeal:(UIButton*)button {
    Place *place = (Place*)_snippetItem;
    [[TogaytherService dealsService] activateDealFor:place onSuccess:^(id obj) {
        PMLDeal *deal = (PMLDeal*)obj;
        BOOL hasDeal = NO;
        for(PMLDeal *placeDeal in place.deals) {
            if([placeDeal.key isEqualToString:deal.key]) {
                hasDeal = YES;
                break;
            }
        }
        if(!hasDeal) {
            [place.deals addObject:deal];
        }
        [self.tableView reloadData];
    } onFailure:^(NSInteger errorCode, NSString *errorMessage) {
        [_uiService alertWithTitle:@"deal.activate.errorTitle" text:@"deal.activate.errorMsg"];
    }];
}
-(void)didTapDealPlayPauseButton:(UIButton*)button {
    NSInteger dealIndex = button.tag;
    PMLDeal *deal = [[_infoProvider deals] objectAtIndex:dealIndex];
    NSString *previousStatus = deal.dealStatus;
    if([deal.dealStatus isEqualToString:DEAL_STATUS_PAUSED]) {
        deal.dealStatus = DEAL_STATUS_RUNNING;
    } else {
        deal.dealStatus = DEAL_STATUS_PAUSED;
    }
    [[TogaytherService dealsService] updateDeal:deal onSuccess:^(id obj) {
//        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
//        [indexSet addIndex:kPMLSectionDeals];
//        [indexSet addIndex:kPMLSectionDealsAdmin];
        [self refreshDeals];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kPMLSectionDeals] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kPMLSectionDealsAdmin] withRowAnimation:UITableViewRowAnimationAutomatic];

//        [self.tableView reloadData];
    } onFailure:^(NSInteger errorCode, NSString *errorMessage) {
        deal.dealStatus = previousStatus;
        [_uiService alertError];
    }];
}
-(void)didTapEditDealQuota:(UIButton*)button {
    NSString *title = NSLocalizedString(@"deal.quota.editTitle", @"deal.quota.editTitle");
    NSString *message = NSLocalizedString(@"deal.quota.editMessage", @"deal.quota.editMessage");;
    NSString *cancel = NSLocalizedString(@"cancel", @"cancel");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:@"Ok", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    // Initializing text field to current user nickname
    PMLDeal *deal = [[_infoProvider deals] objectAtIndex:button.tag];
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.text = [NSString stringWithFormat:@"%d",(int)deal.maxUses];
    alertView.tag = button.tag;
    [alertView show];
}


-(void)useDealTapped:(UIButton*)button {

    PMLDeal *deal = [[_infoProvider deals] objectAtIndex:0];
    [_actionManager execute:PMLActionTypeUseDeal onObject:deal];


}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex != alertView.cancelButtonIndex) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        PMLDeal *deal = [[_infoProvider deals] objectAtIndex:alertView.tag];
        NSInteger previousValue = deal.maxUses;
        @try {
            if([textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length ==0) {
                deal.maxUses = 0;
            } else {
                NSNumber *number = [[[NSNumberFormatter alloc] init] numberFromString:textField.text];
                deal.maxUses = number.integerValue;
            }
            [[TogaytherService dealsService] updateDeal:deal onSuccess:^(id obj) {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kPMLSectionDealsAdmin] withRowAnimation:UITableViewRowAnimationAutomatic];
            } onFailure:^(NSInteger errorCode, NSString *errorMessage) {
                [_uiService alertError];
            }];
        } @catch(NSException *e) {
            [_uiService alertError];
            deal.maxUses = previousValue;
        }
    }
}
@end
