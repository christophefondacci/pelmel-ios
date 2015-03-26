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
#import "PMLCalendarTableViewController.h"
#import "PMLCalendarEditorTableViewController.h"
#import "PMLEventTableViewController.h"


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
#define kPMLActionEditHours 4



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
    PopupAction *_reportForDeletionAction;
    PopupAction *_confirmAction;
    PopupAction *_cancelAction;
    
    // Report
    UIActionSheet *_reportActionSheet;
    UIActionSheet *_editActionSheet;
    UIActionSheet *_eventEditActionSheet;
    UIActionSheet *_relocationConfirmActionSheet;
    UIActionSheet *_descriptionActionSheet;
    
    CALObject *_currentObject;
    BOOL _checkinEnabled;
    NSObject<PMLInfoProvider> *_infoProvider;
    NSMutableSet *_observedProperties;
    NSMutableDictionary *_actionTypes;
    
    // Navbar management
    BOOL _navbarEdit;
    UIBarButtonItem *_navbarLeftItem;
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

- (instancetype)initWithObject:(CALObject *)currentObject
{
    self = [self init];
    if (self) {
        _currentObject = currentObject;
        _menuManagerController = [[TogaytherService uiService] menuManagerController];
        _infoProvider = [TogaytherService.uiService infoProviderFor:_currentObject];
    }
    return self;
}
- (void)setPopupController:(PMLMapPopupViewController *)popupController {
    _popupController = popupController;
    _menuManagerController = popupController.controller.parentMenuController;
}
- (void)dealloc {
    [_dataService unregisterDataListener:self];
    [self clearObservers];
}
-(void)dismiss {
//    [_dataService unregisterDataListener:self];
    [self clearObservers];
}

-(void)clearObservers {
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
-(void)registerAction:(PopupAction*)action forType:(PMLActionType)type {
    [_actionTypes setObject:action forKey:[NSNumber numberWithInt:type]];
}
-(PopupAction*)actionForType:(PMLActionType)type {
    return [_actionTypes objectForKey:[NSNumber numberWithInt:type]];
}
-(void) initActions {
    _actionTypes = [[NSMutableDictionary alloc] init];
    _checkinAction = [[PopupAction alloc] initWithAngle:kPMLLikeAngle distance:kPMLLikeDistance icon:[UIImage imageNamed:@"popActionCheckin"] titleCode:nil size:kPMLLikeSize command:^{
        NSLog(@"CHECKIN");
        if(_currentObject.key != nil) {
            [_menuManagerController.menuManagerDelegate loadingStart];
            
            // Are we checked in here?
            CurrentUser *user = [_userService getCurrentUser];
            if([user.lastLocation.key isEqualToString:_currentObject.key]) {
                [_userService checkout:_currentObject completion:^(id obj) {
                    [_menuManagerController.menuManagerDelegate loadingEnd];
                    [self updateBadge];
                }];
            } else {
                [_userService checkin:_currentObject completion:^(id obj) {
                    [_menuManagerController.menuManagerDelegate loadingEnd];
                    [self updateBadge];
                }];
            }
        }
    }];
    _checkinAction.color = UIColorFromRGB(kPMLCheckinColor);
    [self registerAction:_checkinAction forType:PMLActionTypeCheckin];
    
    _likeAction = [[PopupAction alloc] initWithAngle:kPMLLikeAngle distance:kPMLLikeDistance icon:[UIImage imageNamed:@"popActionLike"] titleCode:nil size:kPMLLikeSize command:^{
        NSLog(@"LIKE");
        [self likeAction];
    }];
    _likeAction.color = UIColorFromRGB(kPMLLikeColor);
    [self registerAction:_likeAction forType:PMLActionTypeLike];
    
    PopupAction *attendAction = [[PopupAction alloc] initWithAngle:kPMLLikeAngle distance:kPMLLikeDistance icon:[UIImage imageNamed:@"popActionCheckin"] titleCode:nil size:kPMLLikeSize command:^{
        NSLog(@"ATTEND");
        [self likeAction];
    }];
    attendAction.color = UIColorFromRGB(kPMLCheckinColor);
    [self registerAction:attendAction forType:PMLActionTypeAttend];
    
    PopupAction *attendCancelAction = [[PopupAction alloc] initWithAngle:kPMLLikeAngle distance:kPMLLikeDistance icon:[UIImage imageNamed:@"popActionCancel"] titleCode:nil size:kPMLLikeSize command:^{
        NSLog(@"Cancel ATTEND");
        [self likeAction];
    }];
    attendCancelAction.color = UIColorFromRGB(kPMLCheckinColor);
    [self registerAction:attendCancelAction forType:PMLActionTypeAttendCancel];
    
    _modifyAction = [[PopupAction alloc] initWithAngle:kPMLEditAngle distance:kPMLEditDistance icon:[UIImage imageNamed:@"popActionEdit"] titleCode:nil size:kPMLEditSize command:^{
        NSLog(@"MODIFY PLACE");
        [self initializeEditFor:_currentObject];
    }];
    _modifyAction.color = UIColorFromRGB(kPMLEditColor);
    [self registerAction:_modifyAction forType:PMLActionTypeEditPlace];
    
    PopupAction *editEventAction = [[PopupAction alloc] initWithAngle:kPMLEditAngle distance:kPMLEditDistance icon:[UIImage imageNamed:@"popActionEdit"] titleCode:nil size:kPMLEditSize command:^{
        NSLog(@"MODIFY EVENT");
        [_menuManagerController currentSnippetViewController];
        
        // Displaying event editor if event is current object
        if([_currentObject isKindOfClass:[Event class]]) {
            [self editEvent:(Event*)_currentObject];
        } else if([_currentObject isKindOfClass:[Place class]]) {
            [self initializeEventEditFor:_currentObject];
        }
    }];
    editEventAction.color = UIColorFromRGB(kPMLEditColor);
    [self registerAction:editEventAction forType:PMLActionTypeEditEvent];
    
    PopupAction *genericEdit =[[PopupAction alloc] initWithAngle:kPMLEditAngle distance:kPMLEditDistance icon:[UIImage imageNamed:@"popActionEdit"] titleCode:nil size:kPMLEditSize command:^{
        NSLog(@"MODIFY GENERIC");
        if([_infoProvider respondsToSelector:@selector(editActionType)]) {
            PopupActionBlock block= [[self actionForType:[_infoProvider editActionType]] actionCommand];
            if(block != nil) {
                block();
            }
        }
        [self initializeEditFor:_currentObject];
    }];
    genericEdit.color = UIColorFromRGB(kPMLEditColor);
    [self registerAction:genericEdit forType:PMLActionTypeEdit];
    
    
    _photoAction = [[PopupAction alloc] initWithAngle:kPMLPhotoAngle distance:kPMLPhotoDistance icon:[UIImage imageNamed:@"popActionPhoto"] titleCode:nil size:kPMLPhotoSize command:^{
        NSLog(@"Photo");
        
        // Asking our data manager to prompt for photo upload
        PMLDataManager *dataManager = _menuManagerController.dataManager;
        [dataManager promptUserForPhotoUploadOn:_currentObject];
    }];
    _photoAction.color = UIColorFromRGB(kPMLPhotoColor);
    [self registerAction:_photoAction forType:PMLActionTypeAddPhoto];
    
    _confirmAction = [[PopupAction alloc] initWithAngle:kPMLConfirmAngle distance:kPMLConfirmDistance icon:[UIImage imageNamed:@"popActionCheck"] titleCode:nil size:kPMLConfirmSize command:^{
        NSLog(@"Confirm");
        
        [[self popupEditor] commit];
    }];
    _confirmAction.color = UIColorFromRGB(kPMLConfirmColor);
    [self registerAction:_confirmAction forType:PMLActionTypeConfirm];
    
    _commentAction = [[PopupAction alloc] initWithAngle:kPMLCommentAngle distance:kPMLCommentDistance icon:[UIImage imageNamed:@"popActionComment"] titleCode:nil size:kPMLCommentSize command:^{
        NSLog(@"COMMENT");
        if(_currentObject!= nil) {
            MessageViewController *msgController = (MessageViewController*)[_uiService instantiateViewController:SB_ID_MESSAGES];
            msgController.withObject = _currentObject;
            [(UINavigationController*)_menuManagerController.currentSnippetViewController pushViewController:msgController animated:YES];
            [_menuManagerController openCurrentSnippet:YES];
        }
    }];
    _commentAction.color = UIColorFromRGB(kPMLCommentColor);
    [self registerAction:_commentAction forType:PMLActionTypeComment];
    
    _reportAction = [[PopupAction alloc] initWithAngle:kPMLReportAngle distance:kPMLReportDistance icon:[UIImage imageNamed:@"popActionReport"] titleCode:nil size:kPMLReportSize command:^{
        NSLog(@"REPORT");
        [self initializeReportFor:_currentObject];
    }];
    _reportAction.color = UIColorFromRGB(kPMLReportColor);
    [self registerAction:_reportAction forType:PMLActionTypeReport];
    _reportForDeletionAction = [[PopupAction alloc] initWithAngle:kPMLReportAngle distance:kPMLReportDistance icon:[UIImage imageNamed:@"popActionReport"] titleCode:nil size:kPMLReportSize command:^{
        NSLog(@"REPORT FOR DELETION");
        [_dataService sendReportFor:_currentObject reportType:PMLReportTypeRemovalRequest];
    }];
    _reportForDeletionAction.color = UIColorFromRGB(kPMLReportColor);
    [self registerAction:_reportForDeletionAction forType:PMLActionTypeReportForDeletion];
    _cancelAction = [[PopupAction alloc] initWithAngle:kPMLCancelAngle distance:kPMLCancelDistance icon:[UIImage imageNamed:@"popActionCancel"] titleCode:nil size:kPMLCancelSize command:^{
        NSLog(@"Cancel");
        [[self popupEditor] cancel];
        if(_navbarEdit) {
//            [self installNavBarEdit:_menuManagerController];
        }
    }];
    _cancelAction.color = UIColorFromRGB(kPMLCancelColor);
    [self registerAction:_cancelAction forType:PMLActionTypeCancel];
    
}

-(PMLPopupEditor*)popupEditor {
    return [PMLPopupEditor editorFor:_currentObject on:(MapViewController*)[[TogaytherService uiService] menuManagerController].rootViewController];
}
-(void) likeAction {
    if([_infoProvider respondsToSelector:@selector(likeTapped:callback:)]) {
        [_menuManagerController.menuManagerDelegate loadingStart];
        [_infoProvider likeTapped:_currentObject callback:^(int likes, int dislikes, BOOL liked) {
            [self.popupController updateBadgeFor:_likeAction with:likes];
            [_menuManagerController.menuManagerDelegate loadingEnd];
            
            
        }];
    }
}
-(void)setCurrentObject:(CALObject*)object {
    _currentObject = object;
    _infoProvider = [TogaytherService.uiService infoProviderFor:_currentObject];
}
- (NSArray *)computeActionsFor:(CALObject *)object annotatedBy:(MapAnnotation*)annotation fromController:(PMLMapPopupViewController *)popupController {
    _popupController = popupController;
    _currentObject = object;
    // Setting editor that handles history of changes
//    if(annotation.popupEditor!=nil) {
//        _currentEditor = annotation.popupEditor;
//    } else {
        PMLPopupEditor *_currentEditor = [PMLPopupEditor editorFor:_currentObject on:popupController.controller];
        annotation.popupEditor = _currentEditor;
//    }
    _infoProvider = [TogaytherService.uiService infoProviderFor:_currentObject];
    
    // Preparing list of actions
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    
    if([object isKindOfClass:[Place class]]) {
        Place *place = (Place*)object;
        if(object.key != nil) {
            if(_currentEditor.editing) {
                [actions addObjectsFromArray:@[_cancelAction,_confirmAction]];
                [actions addObject:_modifyAction];
            }
            // Updates the badge on popup actions
            [self updateBadge];
        } else {
            // New place, we propose save if name defined
            if(place.title!= nil) {
                [actions addObjectsFromArray:@[_cancelAction,_confirmAction,_modifyAction]];
            } else {
                [actions addObjectsFromArray:@[_cancelAction,_confirmAction ]];
            }
        }
    }
    return actions;
}
- (void)updateBadge {
    if([_currentObject isKindOfClass:[Place class]]) {
        Place *place = (Place*)_currentObject;
        if(_currentObject.likeCount>0 && !_checkinEnabled) {
            _likeAction.badgeValue = [NSNumber numberWithInt:(int)_currentObject.likeCount];
        } else if(_checkinEnabled) {
            int badgeCount = MAX((int)place.inUserCount,(int)place.inUsers.count);
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
    [_editActionSheet addButtonWithTitle:NSLocalizedString(@"action.edit.hours", @"Opening Hours / Events")];
    [_editActionSheet addButtonWithTitle:cancel];
    _editActionSheet.cancelButtonIndex=5;
    [_editActionSheet showInView:_popupController.controller.parentMenuController.view];
}
-(void)initializeEventEditFor:(CALObject*)object {
    // Ask the user the photo source
    NSString *title = NSLocalizedString(@"action.edit.eventType",@"Type of event");
    NSString *cancel= NSLocalizedString(@"cancel","cancel");
    _eventEditActionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [_eventEditActionSheet addButtonWithTitle:NSLocalizedString(@"action.edit.event.onetime", @"One time")];
    [_eventEditActionSheet addButtonWithTitle:NSLocalizedString(@"action.edit.event.recurring", @"Recurring")];
    [_eventEditActionSheet addButtonWithTitle:cancel];
    _eventEditActionSheet.cancelButtonIndex=2;
    [_eventEditActionSheet showInView:_popupController.controller.parentMenuController.view];
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
            case kPMLActionEditHours:
                [self editHours];
                break;
        }
    } else if(_descriptionActionSheet == actionSheet) {
        switch(buttonIndex) {
            case 0:
                [self editDescriptionWithCurrentLanguage:NO];
                break;
            case 1:
                [self editDescriptionWithCurrentLanguage:YES];
                break;
        }
    } else if(_eventEditActionSheet == actionSheet) {
        switch(buttonIndex) {
            case 0: {
                Event *event = [[Event alloc] initWithPlace:(Place*)_currentObject];
                [self editEvent:event];
                break;
            }
            case 1:
                [self editHours];
                break;
        }
    }
}
#pragma mark - Edition actions
- (void)editName {
    if(!_currentObject.editing) {
        _currentObject.editing = YES;
        _currentObject.editingDesc=NO;
//        [self installNavBarCommitCancel];
        NSString *oldName = ((Place*)_currentObject).title;
        NSString *oldPlaceType= ((Place*)_currentObject).placeType;
        EditionAction cancelAction = ^{
            Place *place = (Place*)_currentObject;
            place.title = oldName;
            place.placeType = oldPlaceType;
            place.editing = NO;
//            [self uninstallNavBarCommitCancel];
        };
        EditionAction commitAction = ^{
            ((Place*)_currentObject).editing = NO;
//            [self uninstallNavBarCommitCancel];
        };
        [[self popupEditor] startEditionWith:commitAction cancelledBy:cancelAction mapEdition:NO];
    }
}
-(void)editDescription {
    if(!_currentObject.editingDesc) {
//        [self installNavBarCommitCancel];
        NSString *sysLang = [TogaytherService getLanguageIso6391Code];
        BOOL noDescription = (_currentObject.miniDescKey == nil||_currentObject.miniDescKey.length==0);
        // If there is an existing description in another language
        // OR if there is NO description and english is not the system language
        if((!noDescription && ![sysLang isEqualToString: _currentObject.miniDescLang])
           || ( noDescription && ![sysLang isEqualToString:@"en"])) {
            
            // Then we offer to choose between current description language (or english if none) and current sys language
            NSString *title = NSLocalizedString(@"description.edition.title", @"Choose your language");
            _descriptionActionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            
            // Language labels
            NSString *descTemplate  = [NSString stringWithFormat:@"language.%@", noDescription ? @"en" : _currentObject.miniDescLang];
            NSString *descLangLabel = NSLocalizedString(descTemplate, @"language name");
            NSString *sysTemplate   = [NSString stringWithFormat:@"language.%@",[TogaytherService getLanguageIso6391Code] ];
            NSString *sysLangLabel  = NSLocalizedString(sysTemplate, @"Language");
            
            // Current choice
            NSString *choiceTemplate= NSLocalizedString(@"description.edition.langChoice", @"Write in ..." );
            NSString *choiceCurrent = [NSString stringWithFormat:choiceTemplate,descLangLabel];
            // System choice
            NSString *systemChoice  = [NSString stringWithFormat:choiceTemplate,sysLangLabel];
            
            // Registering options
            [_descriptionActionSheet addButtonWithTitle:systemChoice];
            [_descriptionActionSheet addButtonWithTitle:choiceCurrent];
            [_descriptionActionSheet addButtonWithTitle:NSLocalizedString(@"cancel", @"cancel")];
            _descriptionActionSheet.cancelButtonIndex=2;
            [_descriptionActionSheet showInView:_popupController.controller.parentMenuController.view];

        } else {
            [self editDescriptionWithCurrentLanguage:YES];
        }
    }
}
-(void)editDescriptionWithCurrentLanguage:(BOOL)currentLanguage {
    NSString *oldDesc = _currentObject.miniDesc;
    NSString *oldDescKey = _currentObject.miniDescKey;
    NSString *oldDescLang = _currentObject.miniDescLang;
    // If current description exists and is in another language
    if(!currentLanguage) {
        // Then we prepare a new one
        _currentObject.miniDesc = nil;
        _currentObject.miniDescKey = nil;
        _currentObject.miniDescLang = [TogaytherService getLanguageIso6391Code];
    } else {
        // If currentLanguage set to YES with no description, it means english
        if(_currentObject.miniDescKey == nil || _currentObject.miniDescKey.length==0) {
            _currentObject.miniDescLang = @"en";
        }
    }
    _currentObject.editingDesc = YES;
    _currentObject.editing = NO;
    EditionAction cancelAction = ^{
        _currentObject.miniDesc = oldDesc;
        _currentObject.miniDescKey = oldDescKey;
        _currentObject.miniDescLang = oldDescLang;
        _currentObject.editingDesc = NO;
//        [self uninstallNavBarCommitCancel];
    };
    EditionAction commitAction = ^{
        _currentObject.editingDesc = NO;
//        [self uninstallNavBarCommitCancel];
    };
    [[self popupEditor] startEditionWith:commitAction cancelledBy:cancelAction mapEdition:NO];

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
    [[self popupEditor] startEditionWith:nil cancelledBy:cancelAction mapEdition:YES];
}
-(void)editToMyLocation {
    CLLocationCoordinate2D coords;
    NSString *title;
    NSString *msg;
    EditionAction cancelAction = nil;
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
        cancelAction = ^{
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
        [[self popupEditor] startEditionWith:nil cancelledBy:cancelAction mapEdition:YES];

    } else {
        title =  NSLocalizedString(@"action.edit.mylocation.fail.title", @"action.edit.mylocation.fail.title");
        msg =NSLocalizedString(@"action.edit.mylocation.fail.msg", @"action.edit.mylocation.fail.msg");
    }
    
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];

}

-(void)editHours {
    PMLCalendarTableViewController *calendarController = (PMLCalendarTableViewController*)[_uiService instantiateViewController:@"calendarEditor"];
    if([_currentObject isKindOfClass:[Place class]]) {
        calendarController.place = (Place*)_currentObject;
        [(UINavigationController*)_menuManagerController.currentSnippetViewController pushViewController:calendarController animated:YES];
    } else {
        NSLog(@"WARNING: Expected a Place object but got %@", NSStringFromClass([_currentObject class]) );
    }
}
-(void)editEvent:(Event*)event {
    
    if([event.key hasPrefix:@"SERI"]) {
        PMLCalendarEditorTableViewController *controller =(PMLCalendarEditorTableViewController*)[_uiService instantiateViewController:@"hoursEditor"];
        [_dataService getObject:event.key callback:^(CALObject *overviewObject) {
            controller.calendar = (PMLCalendar*)overviewObject;
            // Wrapping inside a nav controller
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
            
            // Preparing transition
            [_menuManagerController presentModal:navController];
        }];
    } else {
        // Building event editor
        PMLEventTableViewController *eventController = (PMLEventTableViewController*)[_uiService instantiateViewController:@"eventEditor"];
        eventController.event = event;
        
        // Wrapping inside a nav controller
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:eventController];
        
        // Preparing transition
        [_menuManagerController presentModal:navController];
    }
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
        [self updateBadge];
    }
}
#pragma mark - KVO Observing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    if([@"title" isEqualToString:keyPath]) {
//        [self.popupController refreshActions ]; //buildActions:@[[self buildSaveActionFor:(Place*)object]]];
//    }
}
@end
