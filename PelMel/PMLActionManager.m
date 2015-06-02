//
//  PMLActionManager.m
//  PelMel
//
//  Created by Christophe Fondacci on 28/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLActionManager.h"
#import "PMLCalendarEditorTableViewController.h"
#import "PMLCalendarTableViewController.h"
#import "PMLEventTableViewController.h"
#import "PBWebViewController.h"
#import "PMLDataManager.h"
#import "MessageViewController.h"
#import "PMLBannerEditorTableViewController.h"
#import <MBProgressHUD.h>

#define kPMLConfirmDistance 21.0
#define kPMLConfirmSize 52.0
#define kPMLConfirmAngle M_PI*0.1666
#define kPMLConfirmColor 0x96ca4c

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

#define kPMLEditDistance 63.0
#define kPMLEditSize 65.0
#define kPMLLikeAngle -M_PI/24
#define kPMLEditAngle kPMLLikeAngle-M_PI*0.333
#define kPMLEditColor 0xfde15a


@interface PMLActionManager()
// Storing all actions hashed by their their action type
@property (nonatomic,retain) NSMutableDictionary *actionRegistry;

@property (nonatomic,retain) CALObject *modalActionObject;
@property (nonatomic,retain) UIActionSheet *editActionSheet;
@property (nonatomic,retain) UIActionSheet *reportActionSheet;
@property (nonatomic,retain) UIActionSheet *eventEditActionSheet;
@property (nonatomic,retain) UIActionSheet *relocationConfirmActionSheet;
@property (nonatomic,retain) UIActionSheet *descriptionActionSheet;
@property (nonatomic,retain) UIAlertView *addressAlertView;
@property (nonatomic,retain) CLGeocoder *geocoder;

@end
@implementation PMLActionManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _actionRegistry = [[NSMutableDictionary alloc] init];
        [self registerAddBannerAction];
        [self registerCancelAction];
        [self registerCheckinAction];
        [self registerCommentAction];
        [self registerConfirmAction];
        [self registerEditAddressAction];
        [self registerEditEventAction];
        [self registerGenericEditAction];
        [self registerLikeAction];
        [self registerModifyAction];
        [self registerMyProfileAction];
        [self registerOpenWebsiteAction];
        [self registerPhoneCallAction];
        [self registerPhotoAction];
        [self registerReportAction];
        [self registerReportForDeletionAction];
        [self registerEditBannerAction];
        [self registerAddEventAction];
    }
    return self;
}
-(void)registerAction:(PopupAction*)action forType:(PMLActionType)type {
    [self.actionRegistry setObject:action forKey:[NSNumber numberWithInt:type]];
}
-(PopupAction*)actionForType:(PMLActionType)type {
    return [self.actionRegistry objectForKey:[NSNumber numberWithInt:type]];
}
-(void)execute:(PMLActionType)actionType onObject:(CALObject*)object {
    PopupAction *action = [self actionForType:actionType];
    if(action != nil) {
        action.actionCommand(object);
    } else {
        NSLog(@"ActionManager: nil action for type '%d'",actionType);
    }
}
-(void)registerCheckinAction {
    PopupAction *checkinAction = [[PopupAction alloc] initWithCommand:^(CALObject *object) {
        NSLog(@"CHECKIN");
        if(object.key != nil) {
            [self.uiService.menuManagerController.menuManagerDelegate loadingStart];
            
            // Get the checkin object
            Place *checkinObj = nil;
            if([object isKindOfClass:[Place class]]) {
                checkinObj = (Place*)object;
            } else if([object isKindOfClass:[Event class]]) {
                checkinObj = ((Event*)object).place;
            }
            
            if(checkinObj != nil) {
                // Are we checked in here?
                if([_userService isCheckedInAt:checkinObj ]) {
                    [_userService checkout:checkinObj completion:^(id obj) {
                        [self.uiService.menuManagerController.menuManagerDelegate loadingEnd];
                    }];
                } else {
                    [_userService checkin:checkinObj completion:^(id obj) {
                        [self.uiService.menuManagerController.menuManagerDelegate loadingEnd];
                    }];
                }
            }
        }
    }];
    [self registerAction:checkinAction forType:PMLActionTypeCheckin];
}

-(void)registerLikeAction {
    PopupAction *likeAction = [[PopupAction alloc] initWithCommand:^(CALObject *object) {
        NSLog(@"LIKE");
        [self likeAction:object];
    }];
    
    // Registering
    [self registerAction:likeAction forType:PMLActionTypeLike];
    [self registerAction:likeAction forType:PMLActionTypeAttend];
    [self registerAction:likeAction forType:PMLActionTypeAttendCancel];
}
-(void)registerModifyAction {
    PopupAction *modifyAction = [[PopupAction alloc] initWithAngle:kPMLEditAngle distance:kPMLEditDistance icon:[UIImage imageNamed:@"popActionEdit"] titleCode:nil size:kPMLEditSize command:^(CALObject *object) {
        NSLog(@"MODIFY PLACE");
        [self initializeEditFor:object];
    }];
    modifyAction.color = UIColorFromRGB(kPMLEditColor);
    [self registerAction:modifyAction forType:PMLActionTypeEditPlace];
}
-(void)registerEditAddressAction {
    PopupAction *editAddressAction = [[PopupAction alloc] initWithCommand:^(CALObject *object) {
        
        NSLog(@"MODIFY ADDRESS");
        [self editAddress:object];
    }];
    [self registerAction:editAddressAction forType:PMLActionTypeEditAddress];

}
-(void)registerEditEventAction {
    PopupAction *editEventAction = [[PopupAction alloc] initWithAngle:kPMLEditAngle distance:kPMLEditDistance icon:[UIImage imageNamed:@"popActionEdit"] titleCode:nil size:kPMLEditSize command:^(CALObject *object) {
        NSLog(@"MODIFY EVENT");
        
        // Displaying event editor if event is current object
        if([object isKindOfClass:[Event class]]) {
            [self editEvent:(Event*)object];
        } else if([object isKindOfClass:[Place class]]) {
            [self initializeEventEditFor:object];
        }
    }];
    editEventAction.color = UIColorFromRGB(kPMLEditColor);
    [self registerAction:editEventAction forType:PMLActionTypeEditEvent];
}
-(void)registerAddEventAction {
    PopupAction *addEventAction = [[PopupAction alloc] initWithCommand:^(CALObject *object) {
        PMLItemSelectionTableViewController *itemSelectionController = (PMLItemSelectionTableViewController*)[[TogaytherService uiService] instantiateViewController:SB_ID_ITEM_SELECTION];
        itemSelectionController.targetType = PMLTargetTypePlace;
        itemSelectionController.delegate = self;
        [[[TogaytherService uiService] menuManagerController].navigationController pushViewController:itemSelectionController animated:YES];
    }];
    [self registerAction:addEventAction forType:PMLActionTypeAddEvent];
}
-(void)registerGenericEditAction {
    PopupAction *genericEdit =[[PopupAction alloc] initWithAngle:kPMLEditAngle distance:kPMLEditDistance icon:[UIImage imageNamed:@"popActionEdit"] titleCode:nil size:kPMLEditSize command:^(CALObject *object) {
        NSLog(@"MODIFY GENERIC");
        id<PMLInfoProvider> infoProvider = [_uiService infoProviderFor:object];
        if([infoProvider respondsToSelector:@selector(editActionType)]) {
            PMLActionBlock block= [[self actionForType:[infoProvider editActionType]] actionCommand];
            if(block != nil) {
                block(object);
            }
        }
        // Was in the initial method, don't see any reason to call edit here
//        [self initializeEditFor:object];
    }];
    genericEdit.color = UIColorFromRGB(kPMLEditColor);
    [self registerAction:genericEdit forType:PMLActionTypeEdit];
}
-(void)registerPhoneCallAction {
    PopupAction *phoneCall = [[PopupAction alloc] initWithCommand:^(CALObject *object) {
        
        // Getting info provider for object
        id<PMLInfoProvider> infoProvider = [_uiService infoProviderFor:object];
        
        // Extracting phone property
        PMLProperty *property = [_uiService propertyFrom:infoProvider forCode:PML_PROPERTY_CODE_PHONE];
        
        // Continuing only if there is a phone number
        if(property != nil) {
            // Building a phone URL string
            NSString *cleanedString = [[property.propertyValue componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+()"] invertedSet]] componentsJoinedByString:@""];
            NSString *escapedPhoneNumber = [cleanedString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *phoneURLString = [NSString stringWithFormat:@"telprompt:%@", escapedPhoneNumber];
            NSURL *phoneURL = [NSURL URLWithString:phoneURLString];
            
            // Check the system if it supports "telprompt:" URL scheme
            if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
                // If yes we prompt
                [[UIApplication sharedApplication] openURL:phoneURL];
            } else {
                // Otherwise we fallback on "tel:" URL scheme
                phoneURLString = [NSString stringWithFormat:@"tel:%@",escapedPhoneNumber];
                phoneURL = [NSURL URLWithString:phoneURLString];
                // And test again
                if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
                    [[UIApplication sharedApplication] openURL:phoneURL];
                } else {
                    [_uiService alertWithTitle:@"phone.unsupported.title" text:@"phone.unsupported"];
                }
            }
        }
    }];
    phoneCall.icon = [UIImage imageNamed:@"btnActionPhone"];
    [self registerAction:phoneCall forType:PMLActionTypePhoneCall];
}
-(void)registerOpenWebsiteAction {
    PopupAction *openWebsite = [[PopupAction alloc] initWithCommand:^(CALObject *object) {
        id<PMLInfoProvider> infoProvider = [_uiService infoProviderFor:object];
        
        PMLProperty *property = [_uiService propertyFrom:infoProvider forCode:PML_PROPERTY_CODE_WEBSITE];
        if(property != nil) {
            PBWebViewController *webviewController= [[PBWebViewController alloc] init];
            webviewController.URL = [[NSURL alloc] initWithString:property.propertyValue];
            [TogaytherService applyCommonLookAndFeel:[_uiService menuManagerController]];
            ((UINavigationController*)[_uiService menuManagerController].currentSnippetViewController).navigationBar.translucent=NO;
            
            [_uiService presentController:webviewController];
            
        }
    }];
    [self registerAction:openWebsite forType:PMLActionTypeWebsite];
}
-(void)registerPhotoAction {
    PopupAction *photoAction = [[PopupAction alloc] initWithCommand:^(CALObject *object) {
        NSLog(@"Photo");
        
        // Asking our data manager to prompt for photo upload
        PMLDataManager *dataManager = [[TogaytherService uiService] menuManagerController].dataManager;
        [dataManager promptUserForPhotoUploadOn:object];
    }];
    photoAction.icon =[UIImage imageNamed:@"popActionPhoto"];
    [self registerAction:photoAction forType:PMLActionTypeAddPhoto];
}
-(void)registerConfirmAction {
    PopupAction *confirmAction = [[PopupAction alloc] initWithAngle:kPMLConfirmAngle distance:kPMLConfirmDistance icon:[UIImage imageNamed:@"popActionCheck"] titleCode:nil size:kPMLConfirmSize command:^(CALObject* object){
        NSLog(@"Confirm");
        
        [[PMLEditor editorFor:object] commit];
    }];
    confirmAction.color = UIColorFromRGB(kPMLConfirmColor);
    [self registerAction:confirmAction forType:PMLActionTypeConfirm];
}
-(void)registerCommentAction {
    PopupAction *commentAction = [[PopupAction alloc] initWithCommand:^(CALObject *object) {
        NSLog(@"COMMENT");
        if(object!= nil) {
            MessageViewController *msgController = (MessageViewController*)[_uiService instantiateViewController:SB_ID_MESSAGES];
            msgController.withObject = object;
            [_uiService presentController:msgController];
        }
    }];

    [self registerAction:commentAction forType:PMLActionTypeComment];
}
-(void)registerReportAction {
    PopupAction *reportAction = [[PopupAction alloc] initWithCommand:^(CALObject *object) {
        
        NSLog(@"REPORT");
        [self initializeReportFor:object];
    }];
    [self registerAction:reportAction forType:PMLActionTypeReport];

}
-(void)registerReportForDeletionAction {
    PopupAction *reportForDeletionAction = [[PopupAction alloc] initWithCommand:^(CALObject *object) {
        NSLog(@"REPORT FOR DELETION");
        [_dataService sendReportFor:object reportType:PMLReportTypeRemovalRequest];
    }];
    [self registerAction:reportForDeletionAction forType:PMLActionTypeReportForDeletion];
}
-(void)registerAddBannerAction {
    PopupAction *addBannerAction = [[PopupAction alloc] initWithCommand:^(CALObject *object) {
        if([object isKindOfClass:[PMLBanner class]]) {
            
        } else {
            NSLog(@"Add place banner");
            [_uiService alertWithTitle:@"banner.hint.title" text:@"banner.hint"];
            CurrentUser *user = [_userService getCurrentUser];
            double lat = user.lat;
            double lng = user.lng;
            if(object != nil) {
                lat = object.lat;
                lng = object.lng;
            }
            [_dataService createBannerAtLatitude:user.lat longitude:user.lng forObject:(Place*)object];
        }
    }];
    [self registerAction:addBannerAction forType:PMLActionTypeAddPlaceBanner];
}
-(void)registerEditBannerAction {
    PopupAction *editBannerAction = [[PopupAction alloc] initWithCommand:^(CALObject *object) {
        
        // Hiding banner to avoid messing with current edition
        _dataService.modelHolder.banner = nil;
        
        // Editing range on map
        [[[_uiService menuManagerController] rootViewController] editRangeFor:object];
        
        // Instantiating editor and displaying as a snippet
        PMLBannerEditorTableViewController *bannerController = (PMLBannerEditorTableViewController*)[_uiService instantiateViewController:SB_ID_BANNER_EDITOR];
        bannerController.banner = (PMLBanner*)object;
        
        // Resigning menus
        [[_uiService menuManagerController] dismissControllerMenu:NO];
        
        // Showing editor
        [_uiService presentSnippet:bannerController opened:NO root:YES];
    }];
    [self registerAction:editBannerAction forType:PMLActionTypeEditBanner];
}
-(void)registerCancelAction {
    PopupAction *cancelAction = [[PopupAction alloc] initWithAngle:kPMLCancelAngle distance:kPMLCancelDistance icon:[UIImage imageNamed:@"popActionCancel"] titleCode:nil size:kPMLCancelSize command:^(CALObject *object) {
        NSLog(@"Cancel");
        [[PMLEditor editorFor:object] cancel];
    }];
    cancelAction.color = UIColorFromRGB(kPMLCancelColor);
    [self registerAction:cancelAction forType:PMLActionTypeCancel];
}
-(void)registerMyProfileAction {
    PopupAction *myProfileAction = [[PopupAction alloc] initWithAngle:kPMLEditAngle distance:kPMLEditDistance icon:[UIImage imageNamed:@"popActionEdit"] titleCode:nil size:kPMLEditSize command:^(CALObject *object) {
        
        NSLog(@"MY PROFILE");
        UIViewController *accountController = [[TogaytherService uiService] instantiateViewController:SB_ID_MYACCOUNT];
        [[[TogaytherService uiService] menuManagerController].navigationController pushViewController:accountController animated:YES];
    }];
    myProfileAction.color = UIColorFromRGB(kPMLEditColor);
    [self registerAction:myProfileAction forType:PMLActionTypeMyProfile];

}
-(void) likeAction:(CALObject*)object {
    
    // Getting provider
    id<PMLInfoProvider> infoProvider = [self.uiService infoProviderFor:object];
    
    // Checking if like is enabled
    if([infoProvider respondsToSelector:@selector(likeTapped:callback:)]) {
        [self.uiService.menuManagerController.menuManagerDelegate loadingStart];

        // Calling provider like action
        [infoProvider likeTapped:object callback:^(int likes, int dislikes, BOOL liked) {
            [self.uiService.menuManagerController.menuManagerDelegate loadingEnd];
        }];
    }
}

#pragma mark - Edition sheets
-(void)initializeEditFor:(CALObject*)object {
    self.modalActionObject = object;
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
    [_editActionSheet showInView:_uiService.menuManagerController.view];
}
-(void)initializeEventEditFor:(CALObject*)object {
    self.modalActionObject = object;
    // Ask the user the photo source
    NSString *title = NSLocalizedString(@"action.edit.eventType",@"Type of event");
    NSString *cancel= NSLocalizedString(@"cancel","cancel");
    _eventEditActionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [_eventEditActionSheet addButtonWithTitle:NSLocalizedString(@"action.edit.event.onetime", @"One time")];
    [_eventEditActionSheet addButtonWithTitle:NSLocalizedString(@"action.edit.event.recurring", @"Recurring")];
    [_eventEditActionSheet addButtonWithTitle:cancel];
    _eventEditActionSheet.cancelButtonIndex=2;
    [_eventEditActionSheet showInView: [_uiService menuManagerController].view];
}
-(void)initializeReportFor:(CALObject*)object {
    self.modalActionObject = object;
    // Ask the user the photo source
    NSString *title = NSLocalizedString(@"action.report.title",@"Actions on this image");
    NSString *cancel= NSLocalizedString(@"cancel","cancel");
    _reportActionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [_reportActionSheet addButtonWithTitle:NSLocalizedString(@"action.report.closed", @"Place has closed")];
    [_reportActionSheet addButtonWithTitle:NSLocalizedString(@"action.report.notgay", @"Place is not gay")];
    
    [_reportActionSheet addButtonWithTitle:NSLocalizedString(@"action.report.location", @"Incorrect location")];
    [_reportActionSheet addButtonWithTitle:cancel];
    _reportActionSheet.cancelButtonIndex=3;
    [_reportActionSheet showInView:_uiService.menuManagerController.view];
}


#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(_reportActionSheet == actionSheet) {
        
        switch(buttonIndex) {
            case kPMLActionReportClosed:
                [_dataService sendReportFor:self.modalActionObject reportType:PMLReportTypeClosed];
                break;
            case kPMLActionReportNotGay:
                [_dataService sendReportFor:self.modalActionObject reportType:PMLReportTypeNotGay];
                break;
            case kPMLActionReportLocation: {
                NSString *title = NSLocalizedString(@"action.report.location.infotitle",@"");
                NSString *message = NSLocalizedString(@"action.report.location.infomsg",@"");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
                // Starting location edition
                [self editLocation:self.modalActionObject];
            }
                
        }
        _reportActionSheet = nil;
    } else if(_editActionSheet == actionSheet) {
        
        switch(buttonIndex) {
            case kPMLActionEditName:
                [self editName:self.modalActionObject];
                break;
            case kPMLActionEditDescription:
                [self editDescription:self.modalActionObject];
                break;
            case kPMLActionEditLocation:
                [self editLocation:self.modalActionObject];
                break;
            case kPMLActionEditMyLocation:
                [self editToMyLocation:self.modalActionObject];
                break;
            case kPMLActionEditHours:
                [self editHours:self.modalActionObject];
                break;
        }
    } else if(_descriptionActionSheet == actionSheet) {
        switch(buttonIndex) {
            case 0:
                [self editDescriptionWithCurrentLanguage:NO ofObject:self.modalActionObject];
                break;
            case 1:
                [self editDescriptionWithCurrentLanguage:YES ofObject:self.modalActionObject];
                break;
        }
    } else if(_eventEditActionSheet == actionSheet) {
        switch(buttonIndex) {
            case 0: {
                Event *event = [[Event alloc] initWithPlace:(Place*)self.modalActionObject];
                [self editEvent:event];
                break;
            }
            case 1:
                [self editHours:self.modalActionObject];
                break;
        }
    }
    // Clearing object
    self.modalActionObject = nil;
}
#pragma mark - Edition actions
- (void)editName:(CALObject*)object {
    if(!object.editing) {
        object.editing = YES;
        object.editingDesc=NO;
        //        [self installNavBarCommitCancel];
        NSString *oldName = ((Place*)object).title;
        NSString *oldPlaceType= ((Place*)object).placeType;
        EditionAction cancelAction = ^{
            Place *place = (Place*)object;
            place.title = oldName;
            place.placeType = oldPlaceType;
            place.editing = NO;
            //            [self uninstallNavBarCommitCancel];
        };
        EditionAction commitAction = ^{
            ((Place*)object).editing = NO;
            //            [self uninstallNavBarCommitCancel];
        };
        [[PMLEditor editorFor:object] startEditionWith:commitAction cancelledBy:cancelAction mapEdition:NO];
    }
}
-(void)editDescription:(CALObject*)object {
    if(!object.editingDesc) {
        //        [self installNavBarCommitCancel];
        NSString *sysLang = [TogaytherService getLanguageIso6391Code];
        BOOL noDescription = (object.miniDescKey == nil||object.miniDescKey.length==0);
        // If there is an existing description in another language
        // OR if there is NO description and english is not the system language
        if((!noDescription && ![sysLang isEqualToString: object.miniDescLang])
           || ( noDescription && ![sysLang isEqualToString:@"en"])) {
            
            // Then we offer to choose between current description language (or english if none) and current sys language
            NSString *title = NSLocalizedString(@"description.edition.title", @"Choose your language");
            _descriptionActionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            
            // Language labels
            NSString *descTemplate  = [NSString stringWithFormat:@"language.%@", noDescription ? @"en" : object.miniDescLang];
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
            [_descriptionActionSheet showInView:_uiService.menuManagerController.view];
            
        } else {
            [self editDescriptionWithCurrentLanguage:YES ofObject:object];
        }
    }
}
-(void)editDescriptionWithCurrentLanguage:(BOOL)currentLanguage ofObject:(CALObject*)object {
    NSString *oldDesc = object.miniDesc;
    NSString *oldDescKey = object.miniDescKey;
    NSString *oldDescLang = object.miniDescLang;
    // If current description exists and is in another language
    if(!currentLanguage) {
        // Then we prepare a new one
        object.miniDesc = nil;
        object.miniDescKey = nil;
        object.miniDescLang = [TogaytherService getLanguageIso6391Code];
    } else {
        // If currentLanguage set to YES with no description, it means english
        if(object.miniDescKey == nil || object.miniDescKey.length==0) {
            object.miniDescLang = @"en";
        }
    }
    object.editingDesc = YES;
    object.editing = NO;
    EditionAction cancelAction = ^{
        object.miniDesc = oldDesc;
        object.miniDescKey = oldDescKey;
        object.miniDescLang = oldDescLang;
        object.editingDesc = NO;
        //        [self uninstallNavBarCommitCancel];
    };
    EditionAction commitAction = ^{
        object.editingDesc = NO;
        //        [self uninstallNavBarCommitCancel];
    };
    [[PMLEditor editorFor:object] startEditionWith:commitAction cancelledBy:cancelAction mapEdition:NO];
    
}
-(void)editLocation:(CALObject*)object
{
    [_uiService.menuManagerController.rootViewController editPlaceLocation:(Place*)object centerMapOnPlace:YES];
    //    // Preparing validation blocks
    //    double oldLat = _currentObject.lat;
    //    double oldLng = _currentObject.lng;
    //    NSString *oldAddress;
    //    if([_currentObject isKindOfClass:[Place class]]) {
    //        oldAddress = ((Place*)_currentObject).address;
    //    }
    //    __block CALObject *obj = _currentObject;
    //    EditionAction cancelAction = ^{
    //        obj.lat=oldLat;
    //        obj.lng=oldLng;
    //        if([obj isKindOfClass:[Place class]]) {
    //            ((Place*)obj).address =  oldAddress;
    //        }
    //
    //    };
    //    // Starting new edition
    //    [[self popupEditor] startEditionWith:nil cancelledBy:cancelAction mapEdition:NO];
}
-(void)editToMyLocation:(CALObject*)object {
    CLLocationCoordinate2D coords;
    NSString *title;
    NSString *msg;
    EditionAction cancelAction = nil;
    if(_dataService.modelHolder.userLocation != nil) {
        coords = _dataService.modelHolder.userLocation.coordinate;
        title =  NSLocalizedString(@"action.edit.mylocation.title", @"action.edit.mylocation.title");
        msg =NSLocalizedString(@"action.edit.mylocation.msg", @"action.edit.mylocation.msg");
        
        // Saving old information to roll it back
        double oldLat = object.lat;
        double oldLng = object.lng;
        NSString *oldAddress;
        if([object isKindOfClass:[Place class]]) {
            oldAddress = ((Place*)object).address;
        }
        __block CALObject *obj = object;
        // Preparing cancel action
        cancelAction = ^{
            obj.lat=oldLat;
            obj.lng=oldLng;
            if([obj isKindOfClass:[Place class]]) {
                ((Place*)obj).address =  oldAddress;
            }
            
        };
        
        ConversionService *conversionService = [TogaytherService getConversionService];
        object.lat = coords.latitude;
        object.lng = coords.longitude;
        [conversionService reverseGeocodeAddressFor:object completion:^(NSString *address) {
            ((Place*)object).address = address;
        }];
        
        // Starting new edition
        [[PMLEditor editorFor:object] startEditionWith:nil cancelledBy:cancelAction mapEdition:YES];
        
    } else {
        title =  NSLocalizedString(@"action.edit.mylocation.fail.title", @"action.edit.mylocation.fail.title");
        msg =NSLocalizedString(@"action.edit.mylocation.fail.msg", @"action.edit.mylocation.fail.msg");
    }
    
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
    [alert show];
    
}

-(void)editHours:(CALObject*)object {
    PMLCalendarTableViewController *calendarController = (PMLCalendarTableViewController*)[_uiService instantiateViewController:@"calendarEditor"];
    if([object isKindOfClass:[Place class]]) {
        calendarController.place = (Place*)object;
        [(UINavigationController*)_uiService.menuManagerController.currentSnippetViewController pushViewController:calendarController animated:YES];
    } else {
        NSLog(@"WARNING: Expected a Place object but got %@", NSStringFromClass([object class]) );
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
            [_uiService.menuManagerController presentModal:navController];
        }];
    } else {
        // Building event editor
        PMLEventTableViewController *eventController = (PMLEventTableViewController*)[_uiService instantiateViewController:@"eventEditor"];
        eventController.event = event;
        
        // Wrapping inside a nav controller
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:eventController];
        
        // Preparing transition
        [_uiService.menuManagerController presentModal:navController];
    }
}

-(void)editAddress:(CALObject*)object {
    NSString *title = NSLocalizedString(@"action.edit.address.title", @"action.edit.address.title");
    NSString *message = NSLocalizedString(@"action.edit.address.message", @"action.edit.address.message");
    NSString *cancel = NSLocalizedString(@"cancel", @"cancel");
    self.modalActionObject = object;
    _addressAlertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:@"Ok", nil];
    _addressAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    // Initializing text field to current user nickname
    Place *place = (Place*)object;
    UITextField *textField = [_addressAlertView textFieldAtIndex:0];
    textField.text = place.address;
    textField.delegate = self;
    textField.clearButtonMode = UITextFieldViewModeAlways;
    
    //    textField.selectedTextRange paste:<#(id)#>]
    [_addressAlertView show];
}
- (void)selectTextForInput:(UITextField *)input atRange:(NSRange)range {
    UITextPosition *start = [input positionFromPosition:[input beginningOfDocument]
                                                 offset:range.location];
    UITextPosition *end = [input positionFromPosition:start
                                               offset:range.length];
    [input setSelectedTextRange:[input textRangeFromPosition:start toPosition:end]];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self selectTextForInput:textField atRange:NSMakeRange(0, 0)];
    });
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex != [alertView cancelButtonIndex]) {
        Place *place = (Place*)self.modalActionObject;
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSString *address = textField.text;
        
        // Adding cancel action that reverts address and latitude / longitude
        NSString *oldAddress = place.address;
        double oldLat = place.lat;
        double oldLng = place.lng;
        [[[PMLEditor editorFor:self.modalActionObject] pendingCancelActions] addObject:^{
            place.address = oldAddress;
            place.lat = oldLat;
            place.lng = oldLng;
        }];
        
        // Geolocating
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[[[TogaytherService uiService] menuManagerController] view] animated:NO];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = NSLocalizedString(@"action.edit.address.geocoding", @"Geocoding address");
        
        _geocoder = [[CLGeocoder alloc] init];
        [_geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
            if(error == nil && placemarks.count>0) {
                // Computing current place location to compare distance
                CLLocation *currentPlaceLocation = [[CLLocation alloc] initWithLatitude:place.lat longitude:place.lng];
                for(CLPlacemark *placemark in placemarks) {
                    place.address = [[TogaytherService getConversionService] addressFromPlacemark:placemark];
                    // If address is more than 100 meters from current place, we relocate place
                    if([placemark.location distanceFromLocation:currentPlaceLocation]>100) {
                        place.lat = placemark.location.coordinate.latitude;
                        place.lng = placemark.location.coordinate.longitude;
                        
                        [[[[TogaytherService uiService] menuManagerController] rootViewController] reselectPlace:place];
                        [[[[TogaytherService uiService] menuManagerController] rootViewController] selectCALObject:place withSnippet:YES];
                        [_uiService alertWithTitle:@"action.edit.address.geocodingMovedPlaceTitle" text:@"action.edit.address.geocodingMovedPlace"];
                    }
                    break;
                }
            } else {
                place.address = address;
                [_uiService alertWithTitle:@"action.edit.address.geocodingFailedTitle" text:@"action.edit.address.geocodingFailed"];
            }
            
            
            // Done
            [hud hide:YES];
        }];
        
    }
    self.modalActionObject = nil;
}

#pragma mark - PMLItemSelectionDelegate

- (void)itemSelected:(CALObject *)item {
    // For now only event creation could land here,
    // Need to place some state if we reuse item selector in other contexts
    [self execute:PMLActionTypeEditEvent onObject:item];
}

@end
