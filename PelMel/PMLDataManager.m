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



@implementation PMLDataManager {
    
    // Main view controller for UI interactions
    PMLMenuManagerController *_menuController;
    
    // Services
    DataService *_dataService;
    UserService *_userService;
    
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
    
}


- (instancetype)initWith:(PMLMenuManagerController *)controller
{
    self = [super init];
    if (self) {
        
        // Keeping UI Controller
        _menuController = controller;
        
        // Service initialization
        _dataService = TogaytherService.dataService;
        _userService = TogaytherService.userService;
        
        // Starting data connection and fetch places
        [_dataService registerDataListener:self];
        [_userService registerListener:self];
        
        
        // TEST: Pelmel waiting
    }
    return self;
}
- (void)hideSpinner {
    [_menuController.menuManagerDelegate loadingEnd];
}

- (void)promptUserForPhotoUploadOn:(CALObject *)object {
    _photoUploadTargetObject = object;
    [TogaytherService.imageService promptUserForPhoto:_menuController callback:self];
}

#pragma mark - DataRefreshCallback
- (void)didLoadData:(ModelHolder *)modelHolder {
    if(_nearbyLoad) {
        if(modelHolder.places.count == 0 ) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:_searchCenter.latitude longitude:_searchCenter.longitude];
            if(([_dataService.modelHolder.userLocation distanceFromLocation:location] <100 || (_searchCenter.latitude == 0 && _searchCenter.longitude==0) )&&  _dataService.currentRadius!=1500) {
//                ((MapViewController*)_menuController.rootViewController).zoomUpdateType = PMLZoomUpdateAroundLocation;
                _dataService.currentRadius =1500;
                [_dataService fetchNearbyPlaces];
            }
        } else {
            _nearbyLoad = NO;
        }
    } else {
        // Case of a single city, we search again in this city
        if(modelHolder.places.count == 0 && modelHolder.cities.count == 1) {
            ((MapViewController*)_menuController.rootViewController).zoomUpdateType = PMLZoomUpdateFitResults;
            [_dataService fetchPlacesFor:modelHolder.cities[0]];
            return;
        }
    }
    if(!_nearbyLoad) {
        [self hideSpinner];
        
        UIService *uiService = TogaytherService.uiService;
        PMLSnippetTableViewController *snippetController = (PMLSnippetTableViewController*)[uiService instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
        
        [_menuController presentControllerSnippet:snippetController];
        
        // Displays a warning if filters are active
        if(![[TogaytherService settingsService] allFiltersActive]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [_menuController setWarningMessage:NSLocalizedString(@"filters.warning", @"filters.warning") color:UIColorFromRGB(0x272a2e) animated:NO duration:5];
            });

        }
    }
//    [insideImage removeFromSuperview];
//    [outsideImage removeFromSuperview];
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
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:_menuController.view];
    }
        [_menuController.menuManagerDelegate loadingStart];

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
            MapViewController *mapController = (MapViewController*)_menuController.rootViewController;
            [mapController selectCALObject:_initialContextObject withSnippet:YES];
        }
        _initialContextObject = nil;
    }
}
-(void)didLooseConnection {
    [_menuController.menuManagerDelegate loadingEnd];
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
    CurrentUser *user = [_userService getCurrentUser];
    if(liked) {
        [likedObject.likers addObject:user];
    } else {
        [likedObject.likers removeObject:user];
    }
    
    // Feedback message
    NSString *title;
    NSString *message;
    if(likedObject.isLiked) {
        if([[likedObject.key substringToIndex:4] isEqualToString:@"EVNT"]) {
            title = NSLocalizedString(@"action.attend.feedbackTitle", @"action.attend.feedbackTitle");
            message = NSLocalizedString(@"action.attend.feedbackMessage", @"action.attend.feedbackMessage");
        } else {
            title = NSLocalizedString(@"action.like.feedbackTitle", @"action.like.feedbackTitle");
            message = NSLocalizedString(@"action.like.feedbackMessage", @"action.like.feedbackMessage");
        }
    } else {
        if([[likedObject.key substringToIndex:4] isEqualToString:@"EVNT"]) {
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
    [_menuController setWarningMessage:NSLocalizedString(@"network.noconnection", @"network.noconnection") color:UIColorFromRGB(0x272a2e) animated:NO duration:0];
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
        [_menuController setWarningMessage:NSLocalizedString(@"network.connecting", @"Logging in") color:UIColorFromRGB(0x3083ea) animated:YES duration:0];
    }
}
- (void)dataLoginFailed {
    if(!_isOnLoginPage) {
        UIViewController *controller = [TogaytherService.uiService instantiateViewController:SB_LOGIN_CONTROLLER];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
        [_menuController.navigationController presentViewController:navController animated:YES completion:nil];
        _isOnLoginPage = YES;
    }
    _deviceConnected = NO;
}
- (void)userAuthenticated:(CurrentUser *)user {
    NSLog(@"userAuthenticated called in UIDataManager");
    _isOnLoginPage = NO;
    if(!_deviceConnected) {
        _deviceConnected = YES;
        [_menuController setWarningMessage:NSLocalizedString(@"network.connected", @"network.connected") color:UIColorFromRGB(0x5fd500) animated:NO duration:0.5];
    }
    // If we have an initial context we open it
    if(_initialContextObject != nil) {
        // Opening a context means fitting results
        ((MapViewController*)_menuController.rootViewController).zoomUpdateType = PMLZoomUpdateFitResults;
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
                MKMapView *mapView = ((MapViewController*)_menuController.rootViewController).mapView;
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

- (void)user:(CurrentUser *)user didCheckInTo:(CALObject *)object {
    if([object isKindOfClass:[Place class]]) {
        Place *place = (Place*)object;
        if(![place.inUsers containsObject:user]) {
            [place.inUsers addObject:user];
            place.inUserCount ++ ;
        }
        // Feedback message
        NSString *title;
        NSString *message;
        title = NSLocalizedString(@"action.checkin.feedbackTitle", @"action.checkin.feedbackTitle");
        NSString *msgTemplate = NSLocalizedString(@"action.checkin.feedbackMessage", @"action.checkin.feedbackMessage");
        message = [NSString stringWithFormat:msgTemplate,place.title];
        
        // Displaying the alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alert show];
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
    
    
    [_menuController.menuManagerDelegate loadingEnd];
}

- (void)imageUploadFailed:(CALImage *)image {
    [_menuController.menuManagerDelegate loadingEnd];
}

- (void)setInitialContext:(CALObject *)object isSearch:(BOOL)isSearch {
    _initialContextObject = object;
    _initialContextSearch = isSearch;
}
@end
