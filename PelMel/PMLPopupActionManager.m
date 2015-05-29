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
#import "PMLEditor.h"
#import "MapAnnotation.h"
#import "MessageViewController.h"
#import "PMLCalendarTableViewController.h"
#import "PMLCalendarEditorTableViewController.h"
#import "PMLEventTableViewController.h"
#import <MBProgressHUD.h>
#import "PMLProperty.h"
#import <PBWebViewController.h>

@implementation PMLPopupActionManager {
    
    // Services
    DataService *_dataService;
    UIService *_uiService;
    UserService *_userService;
    
    CALObject *_currentObject;
    BOOL _checkinEnabled;
    NSObject<PMLInfoProvider> *_infoProvider;
    NSMutableSet *_observedProperties;
    CLGeocoder *_geocoder;
    
    // Navbar management
    BOOL _navbarEdit;
    UIBarButtonItem *_navbarLeftItem;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initServices];
        _observedProperties = [[NSMutableSet alloc] init];
    }
    return self;
}

- (instancetype)initWithObject:(CALObject *)currentObject
{
    self = [self init];
    if (self) {
        _currentObject = currentObject;
        _infoProvider = [TogaytherService.uiService infoProviderFor:_currentObject];
    }
    return self;
}
- (void)setPopupController:(PMLMapPopupViewController *)popupController {
    _popupController = popupController;
}
- (void)dealloc {
    [_dataService unregisterDataListener:self];
    [self clearObservers];
}
-(void)dismiss {
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
-(void)setCurrentObject:(CALObject*)object {
    _currentObject = object;
    _infoProvider = [TogaytherService.uiService infoProviderFor:_currentObject];
}
- (NSArray *)computeActionsFor:(CALObject *)object annotatedBy:(MapAnnotation*)annotation fromController:(PMLMapPopupViewController *)popupController {
    _popupController = popupController;
    _currentObject = object;
    // Setting editor that handles history of changes
    PMLEditor *_currentEditor = [PMLEditor editorFor:_currentObject on:popupController.controller];
    annotation.popupEditor = _currentEditor;
    _infoProvider = [TogaytherService.uiService infoProviderFor:_currentObject];
    
    // Preparing list of actions
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    
    if([object isKindOfClass:[Place class]]) {
        PopupAction *cancelAction = [[TogaytherService actionManager] actionForType:PMLActionTypeCancel];
        PopupAction *confirmAction= [[TogaytherService actionManager] actionForType:PMLActionTypeConfirm];
        PopupAction *editAddressAction= [[TogaytherService actionManager] actionForType:PMLActionTypeEditAddress];
        if(object.key != nil) {
            if(_currentEditor.editing) {
                [actions addObjectsFromArray:@[cancelAction,confirmAction,editAddressAction]];
            }
        } else {
            // New place, we propose save if name defined
            [actions addObjectsFromArray:@[cancelAction,confirmAction,editAddressAction]];
        }
    }
    return actions;
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

#pragma mark - KVO Observing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    if([@"title" isEqualToString:keyPath]) {
//        [self.popupController refreshActions ]; //buildActions:@[[self buildSaveActionFor:(Place*)object]]];
//    }
}
@end
