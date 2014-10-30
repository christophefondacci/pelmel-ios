//
//  PopupActionManager.m
//  PelMel
//
//  Created by Christophe Fondacci on 23/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLPopupActionManager.h"
#import "TogaytherService.h"
#import "PopupAction.h"
#import "PMLMapPopupViewController.h"
#import "PMLDataManager.h"
#import "PMLPopupEditor.h"
#import "MapAnnotation.h"
#import "MessageViewController.h"

#define kCheckinDistanceMeters 100

#define kPMLLikeDistance 32.0
#define kPMLLikeSize 60.0
#define kPMLLikeAngle -M_PI/24
#define kPMLLikeColor 0x93b2dd
#define kPMLCheckinColor 0x7ac943

#define kPMLPhotoDistance 21.0
#define kPMLPhotoSize 52.0
#define kPMLPhotoAngle kPMLLikeAngle+M_PI*0.333
#define kPMLPhotoColor 0x96ca4c

#define kPMLConfirmDistance 21.0
#define kPMLConfirmSize 52.0
#define kPMLConfirmAngle M_PI*0.1666
#define kPMLConfirmColor 0x96ca4c

#define kPMLEditDistance 63.0
#define kPMLEditSize 65.0
#define kPMLEditAngle kPMLLikeAngle-M_PI*0.333
#define kPMLEditColor 0xfde15a

#define kPMLReportDistance 20.0
#define kPMLReportSize 50.0
#define kPMLReportAngle kPMLLikeAngle-0.666*M_PI
#define kPMLReportColor 0xc50000

#define kPMLCommentDistance 50.0
#define kPMLCommentSize 50.0
#define kPMLCommentAngle kPMLLikeAngle-M_PI-M_PI/24
#define kPMLCommentColor 0x8b126b

#define kPMLCancelDistance 20.0
#define kPMLCancelSize 50.0
#define kPMLCancelAngle M_PI-M_PI*.1666
#define kPMLCancelColor 0xc50000

#define kPMLActionReportClosed 0
#define kPMLActionReportNotGay 1
#define kPMLActionReportLocation 2

#define kPMLActionEditName 0
#define kPMLActionEditDescription 1
#define kPMLActionEditLocation 2
#define kPMLActionEditMyLocation 3


//#define kPMLLikeSize 50.0
//#define kPMLLikeDistance 135.0
//#define kPMLLikeAngle -5*M_PI/12 //M_PI + M_PI/8
//#define kPMLLikeAngleSlot M_PI/8


@implementation PMLPopupActionManager {
    
    // Services
    DataService *_dataService;
    UIService *_uiService;
    UserService *_userService;
    
    // Standard actions
    PopupAction *_checkinAction;
    PopupAction *_likeAction;
    PopupAction *_modifyAction;
    PopupAction *_photoAction;
    PopupAction *_commentAction;
    PopupAction *_reportAction;
    PopupAction *_confirmAction;
    PopupAction *_cancelAction;
    
    // Report
    UIActionSheet *_reportActionSheet;
    UIActionSheet *_editActionSheet;
    UIActionSheet *_relocationConfirmActionSheet;
    
    CALObject *_currentObject;
    BOOL _checkinEnabled;
    PMLPopupEditor *_currentEditor;
    NSObject<DetailProvider> *_detailProvider;
    NSMutableSet *_observedProperties;

}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initServices];
        [self initActions];
        _observedProperties = [[NSMutableSet alloc] init];
    }
    return self;
}
- (void)dealloc {
    [_dataService unregisterDataListener:self];
}
-(void)dismiss {
//    [_dataService unregisterDataListener:self];
    // Cleaning any property change listener
    for(NSString *prop in _observedProperties) {
        [_currentObject removeObserver:self forKeyPath:prop];
    }
    [_observedProperties removeAllObjects];
}
-(void) initServices {
    _dataService = [TogaytherService dataService];
    _uiService = [TogaytherService uiService];
    _userService = [TogaytherService userService];
    [_dataService registerDataListener:self];
}
-(void) initActions {
    _checkinAction = [[PopupAction alloc] initWithAngle:kPMLLikeAngle distance:kPMLLikeDistance icon:[UIImage imageNamed:@"popActionCheckin"] titleCode:nil size:kPMLLikeSize command:^{
        NSLog(@"CHECKIN");
        if(_currentObject.key != nil) {
            [self.popupController.controller.parentMenuController.menuManagerDelegate loadingStart];
            [_userService checkin:_currentObject completion:^(id obj) {
                [self.popupController.controller.parentMenuController.menuManagerDelegate loadingEnd];
                [self updateBadge];
            }];
        }
    }];
    _checkinAction.color = UIColorFromRGB(kPMLCheckinColor);
    _likeAction = [[PopupAction alloc] initWithAngle:kPMLLikeAngle distance:kPMLLikeDistance icon:[UIImage imageNamed:@"popActionLike"] titleCode:nil size:kPMLLikeSize command:^{
        NSLog(@"LIKE");
        if(_detailProvider) {
            [self.popupController.controller.parentMenuController.menuManagerDelegate loadingStart];
            [_detailProvider likeTapped:_currentObject callback:^(int likes, int dislikes, BOOL liked) {
                [self.popupController updateBadgeFor:_likeAction with:likes];
                [self.popupController.controller.parentMenuController.menuManagerDelegate loadingEnd];

                                
            }];
        }
    }];
    _likeAction.color = UIColorFromRGB(kPMLLikeColor);
    
    
    _modifyAction = [[PopupAction alloc] initWithAngle:kPMLEditAngle distance:kPMLEditDistance icon:[UIImage imageNamed:@"popActionEdit"] titleCode:nil size:kPMLEditSize command:^{
        NSLog(@"MODIFY");
        [self initializeEditFor:_currentObject];
    }];
    _modifyAction.color = UIColorFromRGB(kPMLEditColor);
    
    _photoAction = [[PopupAction alloc] initWithAngle:kPMLPhotoAngle distance:kPMLPhotoDistance icon:[UIImage imageNamed:@"popActionPhoto"] titleCode:nil size:kPMLPhotoSize command:^{
        NSLog(@"Photo");
        
        // Asking our data manager to prompt for photo upload
        PMLDataManager *dataManager = self.popupController.controller.parentMenuController.dataManager;
        [dataManager promptUserForPhotoUploadOn:_currentObject];
    }];
    _photoAction.color = UIColorFromRGB(kPMLPhotoColor);
    
    _confirmAction = [[PopupAction alloc] initWithAngle:kPMLConfirmAngle distance:kPMLConfirmDistance icon:[UIImage imageNamed:@"popActionCheck"] titleCode:nil size:kPMLConfirmSize command:^{
        NSLog(@"Confirm");
        [_currentEditor commit];
        
    }];
    _confirmAction.color = UIColorFromRGB(kPMLConfirmColor);
    
    _commentAction = [[PopupAction alloc] initWithAngle:kPMLCommentAngle distance:kPMLCommentDistance icon:[UIImage imageNamed:@"popActionComment"] titleCode:nil size:kPMLCommentSize command:^{
        NSLog(@"COMMENT");
        if(_currentObject!= nil) {
            MessageViewController *msgController = (MessageViewController*)[_uiService instantiateViewController:SB_ID_MESSAGES];
            msgController.withObject = _currentObject;
            [_popupController.controller.navigationController pushViewController:msgController animated:YES];
        }
    }];
    _commentAction.color = UIColorFromRGB(kPMLCommentColor);
    
    _reportAction = [[PopupAction alloc] initWithAngle:kPMLReportAngle distance:kPMLReportDistance icon:[UIImage imageNamed:@"popActionReport"] titleCode:nil size:kPMLReportSize command:^{
        NSLog(@"REPORT");
        [self initializeReportFor:_currentObject];
    }];
    _reportAction.color = UIColorFromRGB(kPMLReportColor);
    
    _cancelAction = [[PopupAction alloc] initWithAngle:kPMLCancelAngle distance:kPMLCancelDistance icon:[UIImage imageNamed:@"popActionCancel"] titleCode:nil size:kPMLCancelSize command:^{
        NSLog(@"Cancel");
        [_currentEditor cancel];
    }];
    _cancelAction.color = UIColorFromRGB(kPMLCancelColor);
    
}
- (NSArray *)computeActionsFor:(CALObject *)object annotatedBy:(MapAnnotation*)annotation fromController:(PMLMapPopupViewController *)popupController {
    _popupController = popupController;
    _currentObject = object;
    // Setting editor that handles history of changes
    if(annotation.popupEditor!=nil) {
        _currentEditor = annotation.popupEditor;
    } else {
        _currentEditor = [PMLPopupEditor editorFor:_currentObject annotatedBy:annotation on:popupController.controller];
        annotation.popupEditor = _currentEditor;
    }
    _detailProvider = [TogaytherService.uiService buildProviderFor:_currentObject];
    
    // Preparing list of actions
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    
    if([object isKindOfClass:[Place class]]) {
        Place *place = (Place*)object;
        if(object.key != nil) {
            // Preparing actions for a place
            if(!_currentEditor.editing) {
                // Computing distance from current location
                PopupAction *likeOrCheckinAction = _likeAction;
                if(_userService.currentLocation!=nil) {
                    CLLocation *objectLocation = [[CLLocation alloc] initWithLatitude:object.lat longitude:object.lng];
                    CLLocationDistance distance = [_userService.currentLocation distanceFromLocation:objectLocation];
                    
                    // If less than our checkin distance, we activate checkin action
                    if(distance <= kCheckinDistanceMeters) {
                        _checkinEnabled = YES;
                        likeOrCheckinAction = _checkinAction;
                    }
                }
                [actions addObjectsFromArray:@[likeOrCheckinAction,_modifyAction,_photoAction,_commentAction,_reportAction]];
            } else {
                [actions addObjectsFromArray:@[_cancelAction,_confirmAction]];
                [actions addObject:_modifyAction];
            }
            // Updates the badge on popup actions
            [self updateBadge];
            
            // Loading overview data if not yet available
            if(!object.hasOverviewData) {
                [_dataService getOverviewData:object];
            }
            
        } else {
            // New place, we propose save if name defined

            if(place.title!= nil) {
                [actions addObjectsFromArray:@[_cancelAction,_confirmAction,_modifyAction]];
            } else {
                [actions addObject:_cancelAction];
            }
            // Observing title changes
            [place addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
            [_observedProperties addObject:@"title"];
        }

    } else if( [object isKindOfClass:[City class]] ) {
        PopupAction *searchInCityAction = [[PopupAction alloc] initWithAngle:M_PI/5 distance:kPMLPhotoDistance icon:[UIImage imageNamed:@"popActionSearch"] titleCode:nil size:kPMLLikeSize command:^{
            _popupController.controller.zoomUpdateType = PMLZoomUpdateFitResults;
            [_dataService fetchPlacesFor:object searchTerm:nil];
        }];
        searchInCityAction.color = UIColorFromRGB(0x344160);
        [actions addObject:searchInCityAction];
    }
    return actions;
}
- (void)updateBadge {
    if([_currentObject isKindOfClass:[Place class]]) {
        Place *place = (Place*)_currentObject;
        if(_currentObject.likeCount>0 && !_checkinEnabled) {
            _likeAction.badgeValue = [NSNumber numberWithInt:(int)_currentObject.likeCount];
        } else if(_checkinEnabled) {
            int badgeCount = MAX((int)place.inUserCount,place.inUsers.count);
            if(badgeCount>0) {
                _checkinAction.badgeValue = [NSNumber numberWithInt:badgeCount];
                [self.popupController updateBadgeFor:_checkinAction with:badgeCount];
            } else {
                _checkinAction.badgeValue = nil;
            }
        } else {
            _likeAction.badgeValue = nil;
            _checkinAction.badgeValue = nil;
        }
    }
}
-(NSArray*)peopleConnectionsWithImage:(CALObject*)parent {
    NSMutableArray *people = [[NSMutableArray alloc] init ];
    NSMutableSet *peopleKeys = [[NSMutableSet alloc] init];
    
    // Processing likers of parent
    for(CALObject *liker in parent.likers) {
        // Only adding if image
        if(liker.mainImage!=nil) {
            [people addObject:liker];
            // Filling a key set so that we make sure we only add a same object once
            [peopleKeys addObject:liker.key];
        }
    }
    if([parent isKindOfClass:[Place class]]) {
        Place *place = (Place*)parent;
        for(CALObject *user in place.inUsers) {
            if(user.mainImage != nil && ![peopleKeys containsObject:user.key]) {
                [people addObject:user];
                [peopleKeys addObject:user.key];
            }
        }
    }
    return people;
}

#pragma mark - Report action
-(void)initializeReportFor:(CALObject*)object {
    // Ask the user the photo source
    NSString *title = NSLocalizedString(@"action.report.title",@"Actions on this image");
    NSString *cancel= NSLocalizedString(@"cancel","cancel");
    _reportActionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [_reportActionSheet addButtonWithTitle:NSLocalizedString(@"action.report.closed", @"Place has closed")];
    [_reportActionSheet addButtonWithTitle:NSLocalizedString(@"action.report.notgay", @"Place is not gay")];

    [_reportActionSheet addButtonWithTitle:NSLocalizedString(@"action.report.location", @"Incorrect location")];
    [_reportActionSheet addButtonWithTitle:cancel];
    _reportActionSheet.cancelButtonIndex=3;
    [_reportActionSheet showInView:_popupController.controller.parentMenuController.view];
}
-(void)initializeEditFor:(CALObject*)object {
    // Ask the user the photo source
    NSString *title = NSLocalizedString(@"action.edit.title",@"Info to edit");
    NSString *cancel= NSLocalizedString(@"cancel","cancel");
    _editActionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [_editActionSheet addButtonWithTitle:NSLocalizedString(@"action.edit.name", @"Name / Place type")];
    [_editActionSheet addButtonWithTitle:NSLocalizedString(@"action.edit.description", @"Description")];
    [_editActionSheet addButtonWithTitle:NSLocalizedString(@"action.edit.location", @"Location")];
    [_editActionSheet addButtonWithTitle:NSLocalizedString(@"action.edit.mylocation", @"Change to my location")];
    [_editActionSheet addButtonWithTitle:cancel];
    _editActionSheet.cancelButtonIndex=4;
    [_editActionSheet showInView:_popupController.controller.parentMenuController.view];
}
#pragma mark - ActionSheet Delegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(_reportActionSheet == actionSheet) {
        switch(buttonIndex) {
            case kPMLActionReportClosed:
                [_dataService sendReportFor:_currentObject reportType:PMLReportTypeClosed];
                break;
            case kPMLActionReportNotGay:
                [_dataService sendReportFor:_currentObject reportType:PMLReportTypeNotGay];
                break;
            case kPMLActionReportLocation: {
                NSString *title = NSLocalizedString(@"action.report.location.infotitle",@"");
                NSString *message = NSLocalizedString(@"action.report.location.infomsg",@"");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
                // Starting location edition
                [self editLocation];
            }
                
        }
        _reportActionSheet = nil;
    } else if(_editActionSheet == actionSheet) {
        switch(buttonIndex) {
            case kPMLActionEditName:
                [self editName];
                break;
            case kPMLActionEditDescription:
                [self editDescription];
                break;
            case kPMLActionEditLocation:
                [self editLocation];
                break;
            case kPMLActionEditMyLocation:
                [self editToMyLocation];
                break;
        }
    }
}
#pragma mark - Edition actions
- (void)editName {
    if(!_currentObject.editing) {
        _currentObject.editing = YES;
        NSString *oldName = ((Place*)_currentObject).title;
        NSString *oldPlaceType= ((Place*)_currentObject).placeType;
        EditionAction cancelAction = ^{
            Place *place = (Place*)_currentObject;
            place.title = oldName;
            place.placeType = oldPlaceType;
            place.editing = NO;
        };
        EditionAction commitAction = ^{
            ((Place*)_currentObject).editing = NO;
        };
        [_currentEditor startEditionWith:commitAction cancelledBy:cancelAction mapEdition:NO];
    }
}
-(void)editDescription {
    if(!_currentObject.editingDesc) {
        _currentObject.editingDesc = YES;
        NSString *oldDesc = _currentObject.miniDesc;
        EditionAction cancelAction = ^{
            _currentObject.miniDesc = oldDesc;
            _currentObject.editingDesc = NO;
        };
        EditionAction commitAction = ^{
            _currentObject.editingDesc = NO;
        };
        [_currentEditor startEditionWith:commitAction cancelledBy:cancelAction mapEdition:NO];
    }
}
-(void)editLocation
{
    // Preparing validation blocks
    double oldLat = _currentObject.lat;
    double oldLng = _currentObject.lng;
    NSString *oldAddress;
    if([_currentObject isKindOfClass:[Place class]]) {
        oldAddress = ((Place*)_currentObject).address;
    }
    __block CALObject *obj = _currentObject;
    EditionAction cancelAction = ^{
        obj.lat=oldLat;
        obj.lng=oldLng;
        if([obj isKindOfClass:[Place class]]) {
            ((Place*)obj).address =  oldAddress;
        }
        
    };
    // Starting new edition
    [_currentEditor startEditionWith:nil cancelledBy:cancelAction mapEdition:YES];
}
-(void)editToMyLocation {
    CLLocationCoordinate2D coords;
    NSString *title;
    NSString *msg;
    if(_dataService.modelHolder.userLocation != nil) {
        coords = _dataService.modelHolder.userLocation.coordinate;
        title =  NSLocalizedString(@"action.edit.mylocation.title", @"action.edit.mylocation.title");
        msg =NSLocalizedString(@"action.edit.mylocation.msg", @"action.edit.mylocation.msg");
        
        // Saving old information to roll it back
        double oldLat = _currentObject.lat;
        double oldLng = _currentObject.lng;
        NSString *oldAddress;
        if([_currentObject isKindOfClass:[Place class]]) {
            oldAddress = ((Place*)_currentObject).address;
        }
        __block CALObject *obj = _currentObject;
        // Preparing cancel action
        EditionAction cancelAction = ^{
            obj.lat=oldLat;
            obj.lng=oldLng;
            if([obj isKindOfClass:[Place class]]) {
                ((Place*)obj).address =  oldAddress;
            }
            
        };
        
        ConversionService *conversionService = [TogaytherService getConversionService];
        _currentObject.lat = coords.latitude;
        _currentObject.lng = coords.longitude;
        [conversionService geocodeAddressFor:_currentObject completion:^(NSString *address) {
            ((Place*)_currentObject).address = address;
        }];
        // Starting new edition
        [_currentEditor startEditionWith:nil cancelledBy:cancelAction mapEdition:YES];

    } else {
        title =  NSLocalizedString(@"action.edit.mylocation.fail.title", @"action.edit.mylocation.fail.title");
        msg =NSLocalizedString(@"action.edit.mylocation.fail.msg", @"action.edit.mylocation.fail.msg");
    }
    
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
}
#pragma mark - Dynamic actions generation
-(NSArray *)buildLikeActions:(CALObject*)object {
//    NSMutableArray *likeActions = [[NSMutableArray alloc] initWithCapacity:object.likers.count];
//
//    double angle = kPMLLikeAngle;
//    double offset = 0;
//    NSArray *people = [self peopleConnectionsWithImage:object];
//    for(CALObject *liker in people) {
//        
//        // Building action for this liker
//        PopupAction *action = [[PopupAction alloc] initWithAngle:angle distance:kPMLLikeDistance icon:nil titleCode:nil size:kPMLLikeSize command:^{
//            NSLog(@"Like '%@'",((User*)liker).pseudo );
//        }];
//        action.xOffset = offset;
//        action.showAttachment = (offset == 0);
//        
//        // Setting image
//        if(liker.mainImage!=nil) {
//            action.image = liker.mainImage;
//        } else {
//            action.image = [CALImage getDefaultUserCalImage];
//        }
//        // Adding our like action to the list
//        [likeActions addObject:action];
//        
//        // Next angle
//        offset += kPMLLikeSize + 3;
////        angle = angle + kPMLLikeAngleSlot;
//    }
//    
//    return likeActions;
    return @[];
}

- (PopupAction*)buildSaveActionFor:(Place*)place {
    // Pre-defined save action
    PopupAction *saveAction = [[PopupAction alloc] initWithAngle:M_PI/5 distance:kPMLPhotoDistance icon:[UIImage imageNamed:@"popActionCheck"] titleCode:nil size:kPMLPhotoSize command:^{
        NSLog(@"Save");
        [_dataService updatePlace:place callback:nil];
    }];
    saveAction.color = UIColorFromRGB(kPMLConfirmColor);;
    return saveAction;
}

#pragma mark - PMLDataListener
- (void)didLoadOverviewData:(CALObject *)object {
    if([object.key isEqualToString:_currentObject.key]) {
//        [self.popupController updateBadgeFor:_likeAction with:(int)object.likeCount];
        [self updateBadge];
    }
//    if([object.key isEqualToString:_currentObject.key]) {
//        // Building additional actions
//        NSArray *actions = [self buildLikeActions:object];
//        
//        // Adding like actions
//        [_popupController buildActions:actions];
//    }
}
#pragma mark - KVO Observing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([@"title" isEqualToString:keyPath]) {
        [self.popupController refreshActions ]; //buildActions:@[[self buildSaveActionFor:(Place*)object]]];
    }
}
@end
