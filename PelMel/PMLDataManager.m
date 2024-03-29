//
//  UIDataManager.m
//  PelMel
//
//  Created by Christophe Fondacci on 14/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLDataManager.h"
#import "UIPopBehavior.h"
#import "PMLMenuManagerController.h"
#import "PMLSnippetTableViewController.h"
#import "Constants.h"

static PMLDataManager *_instance;

@interface PMLDataManager()
@property (nonatomic, strong) UIService *uiService;
@property (nonatomic, strong) DataService *dataService;
@property (nonatomic, strong) UserService *userService;
@end
@implementation PMLDataManager {
    
    // Main view controller for UI interactions
//    PMLMenuManagerController *_menuController;
    
    // Animation
    UIDynamicAnimator *_animator;
    
    // Search Settings
    BOOL _nearbyLoad;
    CLLocationCoordinate2D _searchCenter;
    double _searchRadius;
    
    // Photo upload
    CALObject *_photoUploadTargetObject;
    
    BOOL _deviceConnected;
    BOOL _isOnLoginPage;
    
    // Initial context
    CALObject *_initialContextObject;
    BOOL _initialContextSearch;
    
    Place *_checkedInPlace;
    
}
//+ (instancetype)sharedInstance {
//    if(_instance == nil) {
//        @synchronized([PMLDataManager class]) {
//            if(_instance == nil) {
//                _instance = [[PMLDataManager alloc] init];
//            }
//        }
//    }
//    return _instance;
//}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        // Service initialization
        _uiService = [TogaytherService uiService];
        _dataService = [TogaytherService dataService];
        _userService = [TogaytherService userService];
        
        // Starting data connection and fetch places
        [_dataService registerDataListener:self];
        [_userService registerListener:self];
        
        
        // TEST: Pelmel waiting
    }
    return self;
}
- (void)hideSpinner {
    [_uiService.menuManagerController.menuManagerDelegate loadingEnd];
}
- (void)detach {
    [_dataService unregisterDataListener:self];
    [_userService unregisterListener:self];
}
- (void)promptUserForPhotoUploadOn:(CALObject *)object {
    _photoUploadTargetObject = object;
    [TogaytherService.imageService promptUserForPhoto:_uiService.menuManagerController callback:self];
}

#pragma mark - DataRefreshCallback
- (void)didLoadData:(ModelHolder *)modelHolder silent:(BOOL)isSilent {
    if(_nearbyLoad) {
        if(modelHolder.places.count == 0 ) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:_searchCenter.latitude longitude:_searchCenter.longitude];
            if(([_dataService.modelHolder.userLocation distanceFromLocation:location] <100 || (_searchCenter.latitude == 0 && _searchCenter.longitude==0) )&&  _dataService.currentRadius!=1500) {
//                ((MapViewController*)_menuController.rootViewController).zoomUpdateType = PMLZoomUpdateAroundLocation;
                _dataService.currentRadius =1500;
                [_dataService fetchNearbyPlaces];
            } else {
                _nearbyLoad = NO;
            }
        } else {
            _nearbyLoad = NO;
        }
    } else {
        // Case of a single city, we search again in this city
        if(modelHolder.places.count == 0 && modelHolder.cities.count == 1) {
            _uiService.menuManagerController.rootViewController.zoomUpdateType = PMLZoomUpdateFitResults;
            [_dataService fetchPlacesFor:modelHolder.cities[0]];
            return;
        }
    }
    if(!_nearbyLoad) {
        [self hideSpinner];
        
        UIService *uiService = TogaytherService.uiService;
        if(!isSilent) {
            PMLSnippetTableViewController *snippetController = (PMLSnippetTableViewController*)[uiService instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
            
            [_uiService.menuManagerController presentControllerSnippet:snippetController];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:PML_HELP_SNIPPET_EVENTS object:self];
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [[NSNotificationCenter defaultCenter] postNotificationName:PML_HELP_REFRESH_TIMER object:self];
//        });
        // Displays a warning if filters are active
        double delay = 2;
        if(![[TogaytherService settingsService] allFiltersActive]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [_uiService.menuManagerController setWarningMessage:NSLocalizedString(@"filters.warning", @"filters.warning") color:UIColorFromRGB(0x272a2e) animated:NO duration:4];

            });
            delay = 4.6;
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self checkinWarningIfAvailable];
        });
        
    }
//    [insideImage removeFromSuperview];
//    [outsideImage removeFromSuperview];
}
-(void)checkinWarningIfAvailable {
    if([_userService checkedInPlace]==nil) {
        BOOL checkinAvailable = NO;
        for(Place *place in _dataService.modelHolder.places) {
            if([[TogaytherService getConversionService] numericDistanceTo:place]< PML_CHECKIN_DISTANCE) {
                checkinAvailable = YES;
                break;
            }
        }
        if(checkinAvailable) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_uiService.menuManagerController setWarningMessage:NSLocalizedString(@"checkin.globalEnabled", @"checkin.globalEnabled") color:UIColorFromRGB(0x3083ea) animated:YES duration:2];
            });
        }
    }
}
-(void)thumbAvailableFor:(Imaged *)place {
    
}
- (void)localizationDone {
    
}
- (void)didStartDataOperation:(NSString *)msg {
    

    

    // Clearing animation
    [_animator removeAllBehaviors];


//    if(insideImage != nil) {
//        [insideImage removeFromSuperview];
//        [outsideImage removeFromSuperview];
//    }

    if(_animator == nil) {
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:_uiService.menuManagerController.view];
    }
        [_uiService.menuManagerController.menuManagerDelegate loadingStart];

//    insideImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"marker-inside.png"]];
//    outsideImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"marker-outside.png"]];
//    btnSize = insideImage.bounds.size;
//
//    [_menuController.view insertSubview:insideImage aboveSubview:_menuController.rootViewController.view];
//    [_menuController.view insertSubview:outsideImage aboveSubview:insideImage];
//    // Capturing view dimensions
//    CGRect viewBounds = _menuController.view.bounds;
//    
//    // Capturing button frame
//    CGRect btnFrame = CGRectMake(viewBounds.size.width-10-btnSize.width, viewBounds.size.height-btnSize.height, btnSize.width, btnSize.height);
//    // Positioning 2 buttons
//    insideImage.frame = btnFrame;
//    outsideImage.frame = btnFrame;
//
//    
//
//    
//    // Animating
//    UIDynamicItemBehavior *outsideRotation = [[UIDynamicItemBehavior alloc] initWithItems:@[outsideImage]];
//    outsideRotation.angularResistance=0;
//    [outsideRotation addAngularVelocity:5 forItem:outsideImage];
//    [_animator addBehavior:outsideRotation];
//
//    UIDynamicItemBehavior *insideRotation = [[UIDynamicItemBehavior alloc] initWithItems:@[insideImage]];
//    insideRotation.angularResistance=0;
//    [insideRotation addAngularVelocity:-2 forItem:insideImage];
//    [_animator addBehavior:insideRotation];
    
//    UIPopBehavior *popBehavior = [[UIPopBehavior alloc] initWithViews:@[insideImage,outsideImage] pop:YES delay:NO];
//    [_animator addBehavior:popBehavior];
 
}
- (void)refresh {
    // TODO: Should skip authentification and handle wrong authentication
    _searchCenter = _dataService.modelHolder.userLocation.coordinate;
    _searchRadius = 0;
    [_userService authenticateWithLastLogin:self];
}

-(void)refreshAt:(CLLocationCoordinate2D)coordinates radius:(double)radius {
    _searchCenter = coordinates;
    _searchRadius = radius;
    [_userService authenticateWithLastLogin:self];
}
#pragma mark - PMLDataListener

- (void)didLoadOverviewData:(CALObject *)object {
    [self hideSpinner];
    if([_initialContextObject.key isEqualToString:object.key]) {
        if([object isKindOfClass:[User class]]) {
            [[TogaytherService uiService] presentSnippetFor:object opened:YES];
        } else {
            MapViewController *mapController = _uiService.menuManagerController.rootViewController;
            [mapController selectCALObject:_initialContextObject withSnippet:YES];
        }
        _initialContextObject = nil;
    }
//    if([_userService checkedInPlace]==nil && [object isKindOfClass:[Place class]]) {
//        if([[TogaytherService getConversionService] numericDistanceTo:(Place*)object] < PML_CHECKIN_DISTANCE) {
//            [_menuController setWarningMessage:NSLocalizedString(@"checkin.placeEnabled", @"checkin.placeEnabled") color:UIColorFromRGB(0x5fd500) animated:YES duration:2];
//        }
//    }
}
-(void)didLooseConnection {
    [_uiService.menuManagerController.menuManagerDelegate loadingEnd];
    [_uiService.menuManagerController setWarningMessage:NSLocalizedString(@"network.error",@"network.error") color:UIColorFromRGBAlpha(0xe11d21, 1) animated:YES duration:3];
    _deviceConnected = NO;
}

/**
 * Triggers the common standardized feedback when a like is done: updating counts, flags, likers,
 * and providing feedback to end user.
 *
 * @param likedObject the CALObject that was liked / unliked
 * @param likeCount new like count
 * @param dislikesCount new dislikes count
 * @param liked whether the object is now liked or not liked
 */
- (void)didLike:(CALObject *)likedObject newLikes:(int)likeCount newDislikes:(int)dislikesCount liked:(BOOL)liked {
    // Updating counts
    likedObject.likeCount = likeCount;
    likedObject.isLiked = liked;
    
    // Updating likers
//    CurrentUser *user = [_userService getCurrentUser];
//    if(liked) {
//        [likedObject.likers addObject:user];
//    } else {
//        [likedObject.likers removeObject:user];
//    }
    
    // Feedback message
    NSString *title;
    NSString *message;
    NSString *keyPrefix =[likedObject.key substringToIndex:4];
    BOOL isEvent = [keyPrefix isEqualToString:@"EVNT"] || [keyPrefix isEqualToString:@"SERI"];
    if(likedObject.isLiked) {
        if(isEvent) {
            title = NSLocalizedString(@"action.attend.feedbackTitle", @"action.attend.feedbackTitle");
            message = NSLocalizedString(@"action.attend.feedbackMessage", @"action.attend.feedbackMessage");
        } else {
            title = NSLocalizedString(@"action.like.feedbackTitle", @"action.like.feedbackTitle");
            message = NSLocalizedString(@"action.like.feedbackMessage", @"action.like.feedbackMessage");
        }
    } else {
        if(isEvent) {
            title = NSLocalizedString(@"action.attendCancel.feedbackTitle", @"action.attendCancel.feedbackTitle");
            message = NSLocalizedString(@"action.attendCancel.feedbackMessage", @"action.attendCancel.feedbackMessage");
        } else {
            title = NSLocalizedString(@"action.unlike.feedbackTitle", @"action.unlike.feedbackTitle");
            message = NSLocalizedString(@"action.unlike.feedbackMessage", @"action.unlike.feedbackMessage");
        }
    }
    
    // Displaying the alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alert show];
}

#pragma mark UserLoginCallback
- (void)authenticationFailed:(NSString *)reason {
    [self dataLoginFailed];
}
- (void)authenticationImpossible {
    [_uiService.menuManagerController setWarningMessage:NSLocalizedString(@"network.noconnection", @"network.noconnection") color:UIColorFromRGB(0x272a2e) animated:NO duration:0];
    _deviceConnected = NO;
//    UILabel *warningLabel = ((MapViewController*)_menuController.rootViewController).warningLabel;
//    warningLabel.hidden = NO;
//    warningLabel.alpha=1;
//    warningLabel.backgroundColor = UIColorFromRGB(0x272a2e);
//    warningLabel.text = NSLocalizedString(@"network.noconnection", @"network.noconnection");
}
- (void)willStartAuthentication {
    if(!_deviceConnected) {
        // Authenticating
        [_uiService.menuManagerController setWarningMessage:NSLocalizedString(@"network.connecting", @"Logging in") color:UIColorFromRGB(0x3083ea) animated:YES duration:0];
    }
}
- (void)dataLoginFailed {
    if(!_isOnLoginPage) {
        UIViewController *controller = [TogaytherService.uiService instantiateViewController:SB_LOGIN_CONTROLLER];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
        [_uiService.menuManagerController.navigationController presentViewController:navController animated:YES completion:nil];
        _isOnLoginPage = YES;
    }
    _deviceConnected = NO;
}
- (void)userAuthenticated:(CurrentUser *)user {
    NSLog(@"userAuthenticated called in UIDataManager");
    _isOnLoginPage = NO;
    if(!_deviceConnected) {
        _deviceConnected = YES;
        [_uiService.menuManagerController setWarningMessage:NSLocalizedString(@"network.connected", @"network.connected") color:UIColorFromRGB(0x5fd500) animated:NO duration:0.5];
    }
    // If we have an initial context we open it
    if(_initialContextObject != nil) {
        // Opening a context means fitting results
        _uiService.menuManagerController.rootViewController.zoomUpdateType = PMLZoomUpdateFitResults;
        // Overview or search use case
        if(_initialContextSearch) {
            [[TogaytherService dataService] fetchPlacesFor:_initialContextObject];
            // Only once at startup, clearing everything
            _initialContextObject = nil;
            _initialContextSearch = NO;
        } else {
            [_dataService fetchOverviewData:_initialContextObject];
        }

    } else {
        // Standard behavior
        _nearbyLoad = YES;
        if(_searchRadius>0) {
            _dataService.currentRadius = _searchRadius;
        } else {
            _dataService.currentRadius = 0;
            
            if(_userService.currentLocation == nil || (_userService.currentLocation.coordinate.latitude == 0 && _userService.currentLocation.coordinate.longitude==0)) {
                MKMapView *mapView = _uiService.menuManagerController.rootViewController.mapView;
                // Getting current map center coordinates
                CLLocationCoordinate2D centerCoords = mapView.centerCoordinate;
                CLLocationCoordinate2D cornerCoords = [mapView convertPoint:CGPointMake(0, 0) toCoordinateFromView:mapView];
                
                // Distance between center and top left corner will give our distance for search
                CLLocation *centerLoc = [[CLLocation alloc] initWithLatitude:centerCoords.latitude longitude:centerCoords.longitude];
                CLLocation *cornerLoc = [[CLLocation alloc] initWithLatitude:cornerCoords.latitude longitude:cornerCoords.longitude];
                CLLocationDistance distance = [centerLoc distanceFromLocation:cornerLoc];
                int milesRadius = MIN(1500,distance/1609.344);
                [self refreshAt:centerCoords radius:milesRadius];
                return ;
            }
        }
        [_dataService fetchPlacesAtLatitude:_searchCenter.latitude longitude:_searchCenter.longitude for:nil searchTerm:nil];
    }

}
-(void)userRegistered:(CurrentUser *)user {
    [self userAuthenticated:user];
}
- (void)user:(CurrentUser *)user didCheckOutFrom:(Place *)place {
    // Removing user from previous location
    for(User *u in [place.inUsers mutableCopy]) {
        if([u.key isEqualToString:user.key]) {
            [place.inUsers removeObject:u];
        }
    }
    
    // Refreshing data (models may have been switched because of memory pressure)
    [_dataService.modelHolder refreshPlaces:@[place]];
    // Updating map annotations
    [_uiService.menuManagerController.rootViewController updateAnnotations];
    
    // Feedback message
    [[TogaytherService uiService] alertWithTitle:@"action.checkout.feedbackTitle" text:@"action.checkout.feedbackMessage" textObjectName:place.title];
}
- (void)user:(CurrentUser *)user didCheckInTo:(CALObject *)object previousLocation:(Place *)previousLocation {
    NSMutableArray *newPlaces = [[NSMutableArray alloc] init];
    
    if(previousLocation != nil) {
        // Removing user from previous location
        for(User *u in [previousLocation.inUsers mutableCopy]) {
            if([u.key isEqualToString:user.key]) {
                [previousLocation.inUsers removeObject:u];
            }
        }
        // Adding previous location for update
        [newPlaces addObject:previousLocation];
    }
    if([object isKindOfClass:[Place class]]) {
        Place *place = (Place*)object;
        BOOL alreadyCheckedIn = NO;
        for(User *u in place.inUsers) {
            if([u.key isEqualToString:user.key]) {
                alreadyCheckedIn = YES;
                break;
            }
        }
        if(!alreadyCheckedIn) {
            [place.inUsers addObject:user];
        }
        // Adding new location for update
        [newPlaces addObject:place];
        
        // Feedback message
        if(user.networkUsers.count>0) {
            NSString *title = NSLocalizedString(@"action.checkin.feedbackNetworkTitle", @"action.checkin.feedbackNetworkTitle");
            NSString *msg = NSLocalizedString(@"action.checkin.feedbackNetworkMessage", @"action.checkin.feedbackNetworkMessage");
            msg = [NSString stringWithFormat:msg,place.title];
            NSString *btnNotNow = NSLocalizedString(@"action.checkin.feedbackNetworkNotNow", @"action.checkin.feedbackNetworkTitle");
            NSString *btnInvite = NSLocalizedString(@"action.checkin.feedbackNetworkInvite", @"action.checkin.feedbackNetworkTitle");
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:btnNotNow otherButtonTitles:btnInvite,nil];
            _checkedInPlace = place;
            [alertView show];
        } else {
            [[TogaytherService uiService] alertWithTitle:@"action.checkin.feedbackTitle" text:@"action.checkin.feedbackMessage" textObjectName:place.title];
        }
    }
    // Refreshing places if at least one update (there should always be
    if(newPlaces.count>0) {
        [_dataService.modelHolder refreshPlaces:newPlaces];
        [_uiService.menuManagerController.rootViewController updateAnnotations];
    }
}
- (void)user:(CurrentUser *)user didFailCheckInTo:(CALObject *)object {
    NSString *title;
    NSString *message;
    title = NSLocalizedString(@"action.failure.title", @"action.failure.title");
    message = NSLocalizedString(@"action.failure.message", @"action.failure.message");
    
    // Displaying the alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alert show];
}
-(void)searchText:(id)sender {
    
}

#pragma mark - PMLImagePicker
- (void)imagePicked:(CALImage *)image {
    // Uploading
    NSLog(@"image picked");
//    [_menuController.menuManagerDelegate loadingStart];
    
    [TogaytherService.imageService upload:image forObject:_photoUploadTargetObject callback:self];
    
}
#pragma mark PMLImageUploadCallback
- (void)imageUploaded:(CALImage *)image {
    // Setting current main image as first other image
    CALImage *currentMainImg = _photoUploadTargetObject.mainImage;
    if(currentMainImg != nil) {
        if(_photoUploadTargetObject.otherImages == nil) {
            _photoUploadTargetObject.otherImages = [[NSMutableArray alloc] init];
        }
        if(_photoUploadTargetObject.otherImages.count == 0) {
            [_photoUploadTargetObject.otherImages addObject:currentMainImg];
        } else {
            [_photoUploadTargetObject.otherImages insertObject:currentMainImg atIndex:0];
        }
    }
    
    // Assigning new image as main
    _photoUploadTargetObject.mainImage = image;
    
    
    [_uiService.menuManagerController.menuManagerDelegate loadingEnd];
}

- (void)imageUploadFailed:(CALImage *)image {
    [_uiService.menuManagerController.menuManagerDelegate loadingEnd];
}

- (void)setInitialContext:(CALObject *)object isSearch:(BOOL)isSearch {
    _initialContextObject = object;
    _initialContextSearch = isSearch;
}
#pragma mark - UIAlertViewDelegate 
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView.cancelButtonIndex != buttonIndex) {
        [_userService privateNetworkAction:PMLPrivateNetworkActionInvite withUser:_checkedInPlace success:^(id obj) {
            NSLog(@"Success");
        } failure:^(id obj) {
            [[TogaytherService uiService] alertError];
        }];
    }
    _checkedInPlace = nil;
}
@end
