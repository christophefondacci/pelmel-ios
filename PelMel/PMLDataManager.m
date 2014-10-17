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
#import "PMLSnippetViewController.h"
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
    
    BOOL deviceConnected;
    // Loaders
//    UIView *_bgView;
//    UIActivityIndicatorView *_indicatorView;
//    UIImageView *insideImage;
//    UIImageView *outsideImage;
//    CGSize btnSize;
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
            if(_dataService.currentRadius!=1500) {
                _dataService.currentRadius =1500;
                [_dataService fetchNearbyPlaces];
            }
        } else {
            _nearbyLoad = NO;
        }
    } else {
        // Case of a single city, we search again in this city
        if(modelHolder.places.count == 0 && modelHolder.cities.count == 1) {
            [_dataService fetchPlacesFor:modelHolder.cities[0]];
            return;
        }
    }
    if(!_nearbyLoad) {
        [self hideSpinner];
        
        UIService *uiService = TogaytherService.uiService;
        PMLSnippetViewController *snippetController = (PMLSnippetViewController*)[uiService instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
        
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
}
-(void)didLooseConnection {
    [_menuController.menuManagerDelegate loadingEnd];
}
#pragma mark UserLoginCallback
- (void)authenticationFailed:(NSString *)reason {
    [self dataLoginFailed];
}
- (void)authenticationImpossible {
    [_menuController setWarningMessage:NSLocalizedString(@"network.noconnection", @"network.noconnection") color:UIColorFromRGB(0x272a2e) animated:NO duration:0];
    deviceConnected = NO;
//    UILabel *warningLabel = ((MapViewController*)_menuController.rootViewController).warningLabel;
//    warningLabel.hidden = NO;
//    warningLabel.alpha=1;
//    warningLabel.backgroundColor = UIColorFromRGB(0x272a2e);
//    warningLabel.text = NSLocalizedString(@"network.noconnection", @"network.noconnection");
}
- (void)willStartAuthentication {
    if(!deviceConnected) {
        // Authenticating
        [_menuController setWarningMessage:NSLocalizedString(@"network.connecting", @"Logging in") color:UIColorFromRGB(0x3083ea) animated:YES duration:0];
    }
}
- (void)dataLoginFailed {
    UIViewController *controller = [TogaytherService.uiService instantiateViewController:SB_LOGIN_CONTROLLER];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [_menuController.navigationController presentViewController:navController animated:YES completion:nil];
    deviceConnected = NO;
}
- (void)userAuthenticated:(CurrentUser *)user {
    NSLog(@"userAuthenticated called in UIDataManager");
    if(!deviceConnected) {
        deviceConnected = YES;
        [_menuController setWarningMessage:NSLocalizedString(@"network.connected", @"network.connected") color:UIColorFromRGB(0x5fd500) animated:NO duration:0.5];
    }
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
-(void)userRegistered:(CurrentUser *)user {
    [self userAuthenticated:user];
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

@end
