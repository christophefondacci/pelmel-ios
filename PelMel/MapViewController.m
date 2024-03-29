//
//  MapViewController.m
//  nativeTest
//
//  Created by Christophe Fondacci on 25/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "MapViewController.h"
#import "Place.h"
#import "MapAnnotation.h"
#import "TogaytherService.h"
#import "Constants.h"
#import "PMLMapPopupViewController.h"
#import "PMLPlaceAnnotationView.h"
#import "PMLSnippetTableViewController.h"
#import "MKNewPlaceAnnotationView.h"
#import "PMLDataManager.h"
#import "MKNumberBadgeView.h"
#import "PMLInfoProvider.h"
#import "PMLHelpOverlayView.h"
#import "PMLBanner.h"
#import "PMLBannerEditorTableViewController.h"
#import "PMLDealsTableViewController.h"

@import QuartzCore;

#define kPMLMinimumPlacesForZoom 3

#define kActionPlace 0
#define kActionEvent 1
#define kActionBanner 2
#define kActionCancel 3


@interface MapViewController ()

@end

@implementation MapViewController {
    NSUserDefaults *_userDefaults;
    
    ModelHolder *_modelHolder;
    DataService *_dataService;
    UserService *_userService;
    UIService *_uiService;
    PMLHelpService *_helpService;
    ConversionService *_conversionService;
    SettingsService *_settingsService;
    MKAnnotationView *selectedAnnotation;

    
    // Internal for adding new point management
    UILongPressGestureRecognizer *gestureRecognizer;
    BOOL newPointReady;
    Place *_editedPlace;
    UIImageView *_editedPlaceView;
    CALObject *_editedRangeObject;
    UIView *_editedRange;
    
    CALObject *_parentObject;
    
    // Annotation management
    NSMutableSet *_placeAnnotations;
    NSMutableDictionary *_annotationsKeyMap;
    NSMutableDictionary *_annotationsViewMap;
    NSMutableSet *_placeKeys;
    MapAnnotation *_editedAnnotation;
    BOOL _labelsVisible;
    
    // Location management
    CLLocation *_mapInitialCenter;
    CLLocationManager *_locationManager;
    int _lastAuthorizationStatus;
    
    // Menu management (referencing to avoid auto release)
    MenuAction *_menuAddAction;
    MenuAction *_menuRefreshAction;
//    MenuAction *_menuMyPositionAction;
    MenuAction *_menuCheckinAction;
    MenuAction *_menuNetworkAction;
    MenuAction *_menuDealsAction;
    BOOL _zoomAnimation;
    
    // Context filters
    NSMutableArray *_contextKeys;
    CALObject *_contextObject;
    
    // Geocoding
    BOOL _initialUserLocationZoomDone;
    
    BOOL _snippetDisabledOnSelection;
    
    // Help
    PMLHelpOverlayView *helpOverlayView;
    
}
@synthesize mapView = _mapView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [TogaytherService applyCommonLookAndFeel:self];
    
    // Defaults
    _userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Getting services
    _dataService = [TogaytherService dataService];
    _settingsService = [TogaytherService settingsService];
    _userService = [TogaytherService userService];
    _conversionService = [TogaytherService getConversionService];
    _uiService = TogaytherService.uiService;
    _helpService = [TogaytherService helpService];
    _modelHolder = _dataService.modelHolder;
    newPointReady = YES;
    
    [_settingsService addSettingsListener:self];
    
    _annotationsKeyMap = [[NSMutableDictionary alloc] init];
    _annotationsViewMap = [[NSMutableDictionary alloc] init];
    _placeKeys = [[NSMutableSet alloc] init];
    
    // Geocoding
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    if([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [_locationManager requestWhenInUseAuthorization];
    }
    _lastAuthorizationStatus = -1;
    
    // Map delegate
    _mapView.delegate = self;
    _mapView.showsPointsOfInterest = NO;
    [_mapView setUserTrackingMode:MKUserTrackingModeNone animated:NO];
    
    // Pre-centering map to last position
    [self configureMapCenter];
    _zoomUpdateType = PMLZoomUpdateAroundLocation;
    
    // Listening to data events
    [_dataService registerDataListener:self];
    
    
    // Listening to long press
//    gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(mapPressed:)];
//    [_mapView addGestureRecognizer:gestureRecognizer];
    _mapView.showsBuildings=NO;
    
    // Menu actions
    [self initializeMenuActions];
    // Popup management
    self.popupActionManager = [[PMLPopupActionManager alloc] init];
}
-(void)viewDidAppear:(BOOL)animated {
    // Adding menu action
    [self.parentMenuController.menuManagerDelegate setupMenuAction:_menuAddAction];
    [self.parentMenuController.menuManagerDelegate setupMenuAction:_menuRefreshAction];
//    [self.parentMenuController.menuManagerDelegate setupMenuAction:_menuMyPositionAction];
    [self.parentMenuController.menuManagerDelegate setupMenuAction:_menuCheckinAction];
    [self.parentMenuController.menuManagerDelegate setupMenuAction:_menuNetworkAction];
    [self.parentMenuController.menuManagerDelegate setupMenuAction:_menuDealsAction];
    
    // Adding the badge view for messages
    BOOL badgeViewExists = NO;
    for(UIView *subview in _menuNetworkAction.menuActionView.subviews) {
        if([subview isKindOfClass:[MKNumberBadgeView class]]) {
            badgeViewExists = YES;
            break;
        }
    }
    if(!badgeViewExists) {
        MKNumberBadgeView *badgeView = [[MKNumberBadgeView alloc] init];
        badgeView.frame = CGRectMake(_menuNetworkAction.menuActionView.frame.size.width-20, -5, 30, 20);
        badgeView.font = [UIFont fontWithName:PML_FONT_BADGES size:10];
        badgeView.shadow = NO;
        badgeView.shine=NO;
        badgeView.hidden=YES;
        [_menuNetworkAction.menuActionView addSubview:badgeView];
        [[TogaytherService getMessageService] setNetworkCountBadgeView:badgeView];

        // Deals badge
        badgeView = [[MKNumberBadgeView alloc] init];
        badgeView.frame = CGRectMake(_menuDealsAction.menuActionView.frame.size.width-20, -5, 30, 20);
        badgeView.font = [UIFont fontWithName:PML_FONT_BADGES size:10];
        badgeView.shadow = NO;
        badgeView.shine=NO;
        badgeView.hidden=YES;
        [_menuDealsAction.menuActionView addSubview:badgeView];
        [[TogaytherService dealsService] setDealsBadgeView:badgeView forDealsMenuAction:_menuDealsAction];
        
    }
    
    [self.parentMenuController addObserver:self forKeyPath:@"contextObject" options:NSKeyValueObservingOptionNew context:NULL];
    
    
    // Registering help bubbles
    PMLHelpBubble *bubble = [[PMLHelpBubble alloc] initWithRect:_menuAddAction.menuActionView.frame cornerRadius:25 helpText:NSLocalizedString(@"hint.addPlace",@"hint.addPlace") textPosition:PMLTextPositionLeft whenSnippetOpened:NO];
    [_helpService registerBubbleHint:bubble forNotification:PML_HELP_ADDCONTENT];
    
    bubble = [[PMLHelpBubble alloc] initWithRect:_menuRefreshAction.menuActionView.frame cornerRadius:25 helpText:NSLocalizedString(@"hint.reloadData",@"hint.reloadData") textPosition:PMLTextPositionLeft whenSnippetOpened:NO];
    [_helpService registerBubbleHint:bubble forNotification:PML_HELP_REFRESH];
    [_helpService registerBubbleHint:bubble forNotification:PML_HELP_REFRESH_TIMER];

//    bubble = [[PMLHelpBubble alloc] initWithRect:_menuMyPositionAction.menuActionView.frame cornerRadius:25 helpText:NSLocalizedString(@"hint.myposition",@"hint.myposition") textPosition:PMLTextPositionLeft whenSnippetOpened:NO];
//    [_helpService registerBubbleHint:bubble forNotification:PML_HELP_LOCALIZE];
}

- (void)viewDidUnload
{
    _mapView.delegate = nil;
    [self setMapView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}
- (void)viewWillAppear:(BOOL)animated {
//    [self updateMap];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


#pragma mark - Zooming / Positioning helper methods
/**
 * Pre-centers the map to its last known position or to a default place
 */
-(void)configureMapCenter {
    CLLocationCoordinate2D coords = [self lastKnownCoordinates];
    
    // Centering map
    [_mapView setCenterCoordinate:coords animated:NO];

    // Now listening to user position changes
    if(_modelHolder.userLocation == nil) {
        _initialUserLocationZoomDone = NO;
        [_modelHolder addObserver:self forKeyPath:@"userLocation" options:NSKeyValueObservingOptionNew context:NULL];
    }
}
-(CLLocationCoordinate2D)lastKnownCoordinates {
    // Retrieving last known position
    NSNumber *lat = [_userDefaults objectForKey:kPMLKeyLastLatitude];
    NSNumber *lng = [_userDefaults objectForKey:kPMLKeyLastLongitude];
    CLLocationCoordinate2D coords;
    if(lat != nil && lng != nil) {
        coords.latitude = lat.doubleValue;
        coords.longitude = lng.doubleValue;
    } else {
        // Using default San Francisco position
        coords.latitude = 37.754362f;
        coords.longitude = -122.426147f;
    }
    return coords;
}

#pragma mark - Map selection

- (void)selectCALObject:(CALObject *)calObject {
    [self selectCALObject:calObject withSnippet:NO];
}
-(void)selectCALObject:(CALObject*)calObject withSnippet:(BOOL)snippetEnabled {
    // Locating corresponding annotation
    id<MKAnnotation> annotation = [_annotationsKeyMap objectForKey:calObject.key];
    // Selecting
    _snippetDisabledOnSelection = !snippetEnabled;
    if(annotation) {
        if([_mapView.selectedAnnotations containsObject:annotation]) {
            if([annotation isKindOfClass:[MapAnnotation class]]) {
                CALObject *obj = ((MapAnnotation*)annotation).object;
                CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(obj.lat, obj.lng);
                [_mapView setCenterCoordinate:coords animated:YES];
            }
        } else {
            [_mapView selectAnnotation:annotation animated:YES];
        }
    } else {
        MapAnnotation *placeAnnotation = [self buildMapAnnotationFor:calObject];
        [_mapView selectAnnotation:placeAnnotation animated:YES];
    }
    _snippetDisabledOnSelection = NO;
}
#pragma mark - Map contributed menu actions
-(void)initializeMenuActions {
    // Providing our menu action (add content)
    _menuAddAction = [[MenuAction alloc] initWithIcon:[UIImage imageNamed:@"btnAdd"] pctWidth:1 pctHeight:0 action:^(PMLMenuManagerController *menuManagerController,MenuAction *menuAction) {
        
        // Ask the user what to create
        NSString *title= NSLocalizedString(@"action.add.sheetTitle","cancel");
        NSString *cancel= NSLocalizedString(@"cancel","cancel");
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"action.add.place", "Place")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"action.add.event", "Add an Event")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"action.add.banner", "Banner")];
        [actionSheet addButtonWithTitle:cancel];
        actionSheet.cancelButtonIndex = kActionCancel;
        [actionSheet showInView:self.view];

    }];
    _menuAddAction.rightMargin=5;
    _menuAddAction.topMargin=84+24+50+5+100;
    
    // Refresh action
    _menuRefreshAction = [[MenuAction alloc] initWithIcon:[UIImage imageNamed:@"btnRefresh"] pctWidth:1 pctHeight:0 action:^(PMLMenuManagerController *menuManagerController, MenuAction *menuAction) {
        
        // Getting current map center coordinates
        CLLocationDistance distance = [self distanceFromCornerPoint];
        double milesRadius = distance/1609.344f;
        
        // No zoom, updating behind the scenes
        _zoomUpdateType = PMLZoomUpdateNone;
        
        MKMapRect visibleRect = [self.mapView visibleMapRect];
        if(MKMapRectContainsPoint(visibleRect, MKMapPointForCoordinate([[self.mapView userLocation] coordinate]))) {
            [_dataService fetchNearbyPlaces];
        } else {
            [self.parentMenuController.dataManager refreshAt:_mapView.centerCoordinate radius:milesRadius];
        }
    }];
    _menuRefreshAction.rightMargin = 5;
    _menuRefreshAction.topMargin = 84+24; //topMargin = 100; //69;
    
//    // My Position action
//    _menuMyPositionAction = [[MenuAction alloc] initWithIcon:[UIImage imageNamed:@"btnPosition"] pctWidth:1 pctHeight:00 action:^(PMLMenuManagerController *menuManagerController, MenuAction *menuAction) {
//        if(_mapView.showsUserLocation) {
//            
//            // First zoom mode: center on current position
//            _zoomUpdateType = PMLZoomUpdateAroundLocation;
//            _dataService.currentRadius = 0;
//            [_dataService fetchNearbyPlaces];
//        } else {
//            NSString *title = NSLocalizedString(@"action.myposition.alertTitle", @"action.myposition.alertTitle");
//            NSString *msg = NSLocalizedString(@"action.myposition.alertMsg", @"action.myposition.alertMsg");
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
//            [alert show];
//        }
//    }];
//    _menuMyPositionAction.rightMargin = 5;
//    _menuMyPositionAction.topMargin = 84+24; //topMargin = 50;
    
    
    _menuCheckinAction = [[MenuAction alloc] initWithIcon:[UIImage imageNamed:@"btnCheckin"] pctWidth:0 pctHeight:0 action:^(PMLMenuManagerController *menuManagerController, MenuAction *menuAction) {
        [[TogaytherService actionManager] execute:PMLActionTypeCheckin onObject:nil];
    }];
    _menuCheckinAction.leftMargin = 5;
    _menuCheckinAction.topMargin = 84+24; //topMargin
    
    _menuNetworkAction = [[MenuAction alloc] initWithIcon:[UIImage imageNamed:@"btnNetwork"] pctWidth:0 pctHeight:0 action:^(PMLMenuManagerController *menuManagerController, MenuAction *menuAction) {
        [[TogaytherService actionManager] execute:PMLActionTypePrivateNetworkShow onObject:nil];
    }];
    _menuNetworkAction.leftMargin = 5;
    _menuNetworkAction.topMargin = _menuCheckinAction.topMargin+50+5;
    
    _menuDealsAction = [[MenuAction alloc] initWithIcon:[UIImage imageNamed:@"btnDeal"] pctWidth:0 pctHeight:0 action:^(PMLMenuManagerController *menuManagerController, MenuAction *menuAction) {
        PMLDealsTableViewController *dealsController = (PMLDealsTableViewController*)[_uiService instantiateViewController:SB_ID_LIST_DEALS];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:dealsController];
        [[_uiService menuManagerController] presentModal:navController];
    }];
    _menuDealsAction.leftMargin = 5;
    _menuDealsAction.topMargin = _menuNetworkAction.topMargin+50+5;
}

-(CLLocationDistance)distanceFromCornerPoint {
    CLLocationCoordinate2D centerCoords = _mapView.centerCoordinate;
    CLLocationCoordinate2D cornerCoords = [_mapView convertPoint:CGPointMake(0, 0) toCoordinateFromView:_mapView];
    
    // Distance between center and top left corner will give our distance for search
    CLLocation *centerLoc = [[CLLocation alloc] initWithLatitude:centerCoords.latitude longitude:centerCoords.longitude];
    CLLocation *cornerLoc = [[CLLocation alloc] initWithLatitude:cornerCoords.latitude longitude:cornerCoords.longitude];
    CLLocationDistance distance = [centerLoc distanceFromLocation:cornerLoc];
    return distance;
}
-(CLLocationDistance)distanceForMapWidth {
    CLLocationCoordinate2D leftCornerCoords = [_mapView convertPoint:CGPointMake(0, 0) toCoordinateFromView:_mapView];
    CLLocationCoordinate2D rightCornerCoords = [_mapView convertPoint:CGPointMake(self.mapView.bounds.size.width, 0) toCoordinateFromView:_mapView];
    CLLocation *leftLoc = [[CLLocation alloc] initWithLatitude:leftCornerCoords.latitude longitude:leftCornerCoords.longitude];
    CLLocation *rightLoc = [[CLLocation alloc] initWithLatitude:rightCornerCoords.latitude longitude:rightCornerCoords.longitude];
    CLLocationDistance distance = [leftLoc distanceFromLocation:rightLoc];
    return distance;
    
}
-(void)updateMap {
    // First updating annotations because we might need them to compute initial zoom
    NSArray *updatedAnnotations = [self updateAnnotations];
    
    // Calibrating center to last coordinates
    if(_modelHolder.userLocation != nil) {
        _center = _modelHolder.userLocation.coordinate;
    } else {
        _center = [self lastKnownCoordinates];
    }
    
    // Have we already setup initial zoom?
    int placesCount = 0;
    if(_zoomUpdateType != PMLZoomUpdateNone) {

        // Zooming to current user location with 800m x 800m wide rect
        if(_center.latitude != 0 && _center.longitude !=0) {
            
            // Setting up width (a little bit larger for iPad)
            int width = 800;
            if([TogaytherService.uiService isIpad:self]) {
               width = 1600;
            }
            
            MKMapRect rect;
            switch(_zoomUpdateType) {
                case PMLZoomUpdateAroundLocation: {
                    // Building our zoom rect around our center
                    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(_center, width, width);
                    MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
                    
                    // Converting to a rect to check if we got anything nearby
                    rect = [self MKMapRectForCoordinateRegion:adjustedRegion];
                }
                    break;
                case PMLZoomUpdateInMapRect:
                    rect = _mapView.visibleMapRect;
                    break;
                default:
                    break;
            }
            
            NSSet *nearbyAnnotations = [_mapView annotationsInMapRect:rect];
            placesCount = (int)nearbyAnnotations.count;
            if(_zoomUpdateType == PMLZoomUpdateAroundLocation) {
                if(_mapView.userLocation.location!=nil) {
                    nearbyAnnotations = [nearbyAnnotations setByAddingObject:_mapView.userLocation];
                    updatedAnnotations = [updatedAnnotations arrayByAddingObject:_mapView.userLocation];
                }
            }
            
            // If we haven't got much in our rect, we check if we need to zoom fit or no
            if(_zoomUpdateType == PMLZoomUpdateFitResults || (placesCount<kPMLMinimumPlacesForZoom)) {
                
                // If total places are bigger than current places in zoom rect then we zoom fit newly updated annotations
                [_mapView showAnnotations:updatedAnnotations animated:YES];
                
            } else {
                
                // We will have a good nearby view
                _mapView.camera.pitch = 0;
                
                // TODO: Compute final map rect and enable animation if close enough
                _zoomAnimation = _zoomUpdateType == PMLZoomUpdateAroundLocation && _modelHolder.userLocation!=nil;
                NSSet *annotationsToDisplay = nearbyAnnotations.count > 0 ? nearbyAnnotations : _placeAnnotations;
                [_mapView showAnnotations:[annotationsToDisplay allObjects] animated:YES];
            }
            _mapInitialCenter = [[CLLocation alloc] initWithLatitude:_mapView.centerCoordinate.latitude longitude:_mapView.centerCoordinate.longitude];
        } else {
            [_mapView showAnnotations:updatedAnnotations animated:YES];
        }
        // Only de-activating zoom if enough results
        if(placesCount>=kPMLMinimumPlacesForZoom) {
            _zoomUpdateType = PMLZoomUpdateNone;
        }
    }

}
- (MKMapRect) MKMapRectForCoordinateRegion:(MKCoordinateRegion) region
{
    MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude + region.span.latitudeDelta / 2,
                                                                      region.center.longitude - region.span.longitudeDelta / 2));
    MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude - region.span.latitudeDelta / 2,
                                                                      region.center.longitude + region.span.longitudeDelta / 2));
    return MKMapRectMake(MIN(a.x,b.x), MIN(a.y,b.y), ABS(a.x-b.x), ABS(a.y-b.y));
}

/**
 * Updates annotations (create/update) from ModelHolder contents and returns an array of all processed annotations
 */
- (NSArray*)updateAnnotations {

    // Preparing an array to put all processed annotations here.
    // This array will be returned so that we could distinguish those annotations from any pre-existing ones
    NSMutableArray *updatedAnnotations = [[NSMutableArray alloc] initWithCapacity:_modelHolder.places.count];
    
    // Removing annotations connected to place that are no longer present
    Place *place;

    for (id<MKAnnotation> annotation in _mapView.annotations) {
        if(annotation != _mapView.userLocation && annotation != _editedAnnotation) {
            if([annotation isKindOfClass:[MapAnnotation class]]) {
                MapAnnotation *mapAnnotation = (MapAnnotation*)annotation;
                CALObject *obj = mapAnnotation.object;
                BOOL visible = [_settingsService isVisible:obj];
                if(![_placeKeys containsObject:obj.key] || !visible) {
                    [_mapView removeAnnotation:annotation];
                    [_placeAnnotations removeObject:annotation];
                    if(obj.key != nil) {
                        [_annotationsKeyMap removeObjectForKey:obj.key];
                    }
                }
            }

        }
    }
    
    // Building annotations from places
    BOOL centralObjectProcessed = NO;
    for(place in _modelHolder.places) {
        BOOL visible = [_settingsService isVisible:place];
        if(visible && place.lat!=0 && place.lng!=0) {
            // Building annotation
            MapAnnotation *annotation = [self buildMapAnnotationFor:place];
            [updatedAnnotations addObject:annotation];
            if([annotation.annotationView isKindOfClass:[PMLPlaceAnnotationView class]]) {
                [(PMLPlaceAnnotationView*)annotation.annotationView updateData];
            }
            // Selecting if central object
            if ( _centralObject != nil && [place.key isEqualToString:_centralObject.key]) {
                [_mapView selectAnnotation:annotation animated:YES];
                centralObjectProcessed = YES;
            }
        }
    }
    // Adding cities
    for(City *city in _modelHolder.cities) {
        MapAnnotation *annotation = [self buildMapAnnotationFor:city];
        [_placeAnnotations addObject:annotation];
        [updatedAnnotations addObject:annotation];
    }
    if(!centralObjectProcessed && _centralObject != nil && [_centralObject isKindOfClass:[Place class]]) {
        Place *place = (Place*)_centralObject;
        CLLocationCoordinate2D coords;
        coords.latitude = _centralObject.lat;
        coords.longitude =_centralObject.lng;
//        NSString *distanceLabel = [TogaytherService.getConversionService distanceTo:place];
        MapAnnotation *annotation = [[MapAnnotation alloc] initWithCoordinates:coords object:place];
        [_mapView addAnnotation:annotation];

    }
    return updatedAnnotations;
}
-(MapAnnotation*)buildMapAnnotationFor:(CALObject*)place {
    CLLocationCoordinate2D coords;
    coords.latitude = place.lat;
    coords.longitude = place.lng;

    // Looking up any previously created annotation
    MapAnnotation *annotation = [_annotationsKeyMap objectForKey:place.key];
    if(annotation == nil) {
        
        // Initializing new annotation if needed
        annotation = [[MapAnnotation alloc] initWithCoordinates:coords object:place];
        [_mapView addAnnotation:annotation];
        if(place.key) {
            [_annotationsKeyMap setObject:annotation forKey:place.key];
            // Adding annotation to our list
            [_placeAnnotations addObject:annotation];
        }
    }
    annotation.object = place;
    return annotation;
}
#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    switch(buttonIndex) {
        case kActionPlace: {
            CLLocationCoordinate2D coords = _mapView.centerCoordinate;
            [self addPlaceAtLatitude:coords.latitude longitude:coords.longitude];
            break;
        }
        case kActionEvent:
            [[TogaytherService actionManager] execute:PMLActionTypeAddEvent onObject:nil];
            break;
        case kActionBanner:
            [[TogaytherService actionManager] execute:PMLActionTypeAddBanner onObject:nil];
            break;
        case kActionCancel:
            break;
    }
}

#pragma mark - MKMapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKAnnotationView *pinAnnotation = nil;
    if(annotation != mapView.userLocation) {
        static NSString *defaultPinID = @"myPin";
        MapAnnotation *a = (MapAnnotation *)annotation;
        CALObject *object = a.object;
        // Is it our central point ?
        BOOL isCentralObject = _centralObject != nil && [object.key isEqualToString:_centralObject.key];
        if(isCentralObject || object == self.editedObject) {
            MKPinAnnotationView *pin ;
            pin = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"central"];
            if(pin == nil) {
                pin = [[MKNewPlaceAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"central"];
            } else {
                pin.annotation = annotation;
            }
            pin.pinColor = MKPinAnnotationColorPurple;
            pin.canShowCallout = NO;
            pin.animatesDrop=YES;
            pinAnnotation = pin;
            pin.draggable = (object == self.editedObject);
            if(isCentralObject) {
                [pinAnnotation setSelected:YES animated:YES];
            } else {
                a.annotationView = pinAnnotation;
            }
        } else {
            PMLPlaceAnnotationView *placeAnnotation = (PMLPlaceAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:defaultPinID];

            placeAnnotation.alpha = 1;
            placeAnnotation.hidden=NO;
            if ( placeAnnotation == nil ) {
                placeAnnotation = [[PMLPlaceAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:defaultPinID];
            } else {
                placeAnnotation.annotation = annotation;
            }
            // Assigning
            pinAnnotation = placeAnnotation;

            [placeAnnotation updateSizeRatio];
            placeAnnotation.enabled = YES;
            placeAnnotation.canShowCallout = NO;
            
            [placeAnnotation updateImage];
            a.annotationView = placeAnnotation;
            //            pinAnnotation.centerOffset = CGPointMake(9, -18);


//            if(_contextKeys.count>0) {
//                if([_contextKeys containsObject:object.key]) {
//                    placeAnnotation.alpha=1;
//                } else {
//                    placeAnnotation.alpha = 0.3;
//                }
//            } else {
//                placeAnnotation.alpha=1;
//            }
        }
        // Registering annotation view
        if(object.key) {
            [_annotationsViewMap setObject:pinAnnotation forKey:object.key];
        }
    } else {
        NSLog(@"userLocation");
    }
    

    
    
    return pinAnnotation;
}
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    [self cancelEdition];
    
    
    if([view isKindOfClass:[PMLPlaceAnnotationView class]]) {
        view.layer.zPosition=0;
    }
//    NSLog(@"didSelect");
    selectedAnnotation = view;
    if([selectedAnnotation.annotation isKindOfClass:[MapAnnotation class]]) {
        MapAnnotation *mapAnnotation = selectedAnnotation.annotation;
        CALObject *place = mapAnnotation.object;
        
        // Removing any 'new place' pending marker
        if(view.annotation!=_editedAnnotation && _editedObject != nil && (_editedObject.key == nil && newPointReady)) {
            [self setEditedObject:nil];
        }
        
        CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(place.lat, place.lng);
        [_mapView setCenterCoordinate:coords animated:YES];
    
        if(!_snippetDisabledOnSelection) {
            [_uiService presentSnippetFor:place opened:NO];
        }
        
        if(_popupController != nil) {
            [_popupController dismiss];
        }
        _popupController = [[PMLMapPopupViewController alloc] initWithObject:mapAnnotation.object inParentView:view withController:self];
        [self.parentMenuController.view endEditing:YES];
        [self.parentMenuController dismissSearch];
    }
}


- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
//    NSLog(@"didDeselect");
    if(!_snippetDisabledOnSelection) {
//        [self.parentMenuController dismissControllerSnippet];
    }
    if(_popupController != nil) {
        [_popupController dismiss];
        _popupController = nil;
    }
    [self.parentMenuController.view endEditing:YES];
    
    if([view isKindOfClass:[PMLPlaceAnnotationView class]]) {
        [((PMLPlaceAnnotationView*)view) updateData];
    }
}

-(void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    if(_editedObject != nil){
        
        // Selecting annotation if newly added to map, after a delay to overcome MapKit bug
        if(views.count==1 && views[0] == _editedAnnotation.annotationView && newPointReady) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // Now we can safely select
                [_mapView selectAnnotation:_editedAnnotation animated:YES];
            });
            
        }
    }
    
}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:_mapView.centerCoordinate.latitude longitude:_mapView.centerCoordinate.longitude];
    if(_zoomAnimation) {
        _zoomAnimation = NO;
        MKMapCamera *camera = [MKMapCamera camera];
        camera.centerCoordinate = _mapView.camera.centerCoordinate;
        camera.heading = _mapView.camera.heading;
        camera.altitude = _mapView.camera.altitude;
        camera.pitch=70;
        
        [_mapView setCamera:camera animated:YES];
        
    }

    // If we moved more than 100km (our current search radius, then we display refresh
    if([currentLocation distanceFromLocation:_mapInitialCenter]>=50000 && _mapInitialCenter!=nil) {
        _mapInitialCenter = currentLocation;
        [[NSNotificationCenter defaultCenter] postNotificationName:PML_HELP_REFRESH object:self];
    }
    if(!mapView.userLocationVisible) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PML_HELP_LOCALIZE object:self];
    }

    // Displaying help if no annotation and zoom is high enough
    NSSet *annotations = [self.mapView annotationsInMapRect:self.mapView.visibleMapRect];
    if(annotations.count == 0) {
        CLLocationDistance distance = [self distanceFromCornerPoint];
        if(distance < 5000) {
            [[NSNotificationCenter defaultCenter]postNotificationName:PML_HELP_ADDCONTENT object:self];
        }
    }
    
    // Displaying help for annotated marker that would be visible
    if(![_settingsService settingValueAsBoolFor:PML_HELP_BADGE]) {
        CLLocationDistance distance = [self distanceFromCornerPoint];
        if(distance < 5000) {
            MKMapRect rect = MKMapRectMake(MKMapRectGetMinX(self.mapView.visibleMapRect), MKMapRectGetMidY(self.mapView.visibleMapRect), MKMapRectGetWidth(self.mapView.visibleMapRect), MKMapRectGetHeight(self.mapView.visibleMapRect)/2-kSnippetHeight);
            NSSet *relevantAnnotations = [self.mapView annotationsInMapRect:rect];
            for(id<MKAnnotation> annotation in relevantAnnotations) {
                if([annotation isKindOfClass:[MapAnnotation class]]) {
                    MapAnnotation *ann = (MapAnnotation*)annotation;
                    if([ann.object isKindOfClass:[Place class]]) {
                        Place *p = (Place*)ann.object;
                        // Anybody here?
                        if(p.inUserCount>0) {
                            PMLPlaceAnnotationView *annView = (PMLPlaceAnnotationView*)ann.annotationView;
                            CGRect rect = [self.mapView convertRect:annView.frame toView:self.parentMenuController.view];
                            NSString *hintText = [_uiService localizedString:@"hint.badge" forCount:p.inUserCount];
                            PMLHelpBubble *bubble = [[PMLHelpBubble alloc] initWithRect:rect cornerRadius:30 helpText:hintText textPosition:PMLTextPositionTop whenSnippetOpened:NO];
                            [_helpService registerBubbleHint:bubble forNotification:PML_HELP_BADGE];
                            [[NSNotificationCenter defaultCenter] postNotificationName:PML_HELP_BADGE object:self];
                        }
                    }
                }
            }
        }
    }
    // Labels display / hide management
    if(annotations.count < 300) {
        _labelsVisible = YES;
        [self toggleLabelsVisibility:YES forAnnotations:annotations];
    } else if(_labelsVisible) {
        _labelsVisible = NO;
        NSArray *annotations = [self.mapView annotations];
        [self toggleLabelsVisibility:NO forAnnotations:annotations];
    }
    
    // New place management
    if(_editedPlace !=nil) {
        _editedPlace.lat = _mapView.centerCoordinate.latitude;
        _editedPlace.lng = _mapView.centerCoordinate.longitude;
        
        CGPoint mapCenter = [_mapView convertCoordinate:_mapView.centerCoordinate toPointToView:_mapView];
        CGRect frame = _editedPlaceView.bounds;
        _editedPlaceView.frame = CGRectMake(mapCenter.x-CGRectGetWidth(frame)/2, mapCenter.y-CGRectGetHeight(frame), CGRectGetWidth(frame), CGRectGetHeight(frame));
        // Geocoding
        [self geocodePlaceAddress:_editedPlace];
    } else if(_editedRangeObject != nil) {
        if(_editedRange != nil) {
            [self updateEditedRange];
        }
    }
}

-(void)toggleLabelsVisibility:(BOOL)labelsVisible forAnnotations:(id<NSFastEnumeration>)annotations {

    for(id<MKAnnotation> annotation in annotations) {
        if([annotation isKindOfClass:[MapAnnotation class]]) {
            MKAnnotationView *mapAnnotationView = ((MapAnnotation*)annotation).annotationView;
            if([mapAnnotationView isKindOfClass:[PMLPlaceAnnotationView class]]) {
                // Extracting annotation view to make some checks
                PMLPlaceAnnotationView *annView = (PMLPlaceAnnotationView*)mapAnnotationView;
                if(!labelsVisible) {
                    annView.showLabel = labelsVisible;
                } else {
                    PMLPlaceAnnotationView *titledAnnotation = annView;
                    for(id<MKAnnotation> otherAnnotation  in annotations) {
                        if(otherAnnotation!=annotation && [otherAnnotation isKindOfClass:[MapAnnotation class]]) {
                            PMLPlaceAnnotationView *otherAnnView = (PMLPlaceAnnotationView*) ((MapAnnotation*)otherAnnotation).annotationView;
                            if([otherAnnView isKindOfClass: [PMLPlaceAnnotationView class]]) {
                                // Checking intersection of title labels
                                CGRect otherTitleFrame = [otherAnnView convertRect:otherAnnView.titleLabel.frame toView:self.mapView];
                                CGRect titleFrame = [annView convertRect:annView.titleLabel.frame toView:self.mapView];
                                
                                CALObject *obj = (CALObject*)((MapAnnotation*)annotation).object;
                                CALObject *otherObj = (CALObject*)((MapAnnotation*)otherAnnotation).object;
                                if(CGRectIntersectsRect(titleFrame, otherTitleFrame)) {
                                    if(otherObj.likeCount>obj.likeCount) {
                                        titledAnnotation = nil;
                                        break;
                                    } else if(obj.likeCount == otherObj.likeCount && otherAnnView.showLabel) {
                                        titledAnnotation = nil;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    if(titledAnnotation == annView) {
                        annView.showLabel = YES;
                    } else {
                        annView.showLabel = NO;
                    }
                }
            }
        }
    }
}


#pragma mark Add place management
-(void)mapPressed:(UILongPressGestureRecognizer *)sender {
    newPointReady=NO;
    if(sender.state == UIGestureRecognizerStateBegan) {
        // No effect if currently editing object
        if(_editedObject==nil) {
            NSLog(@"pressed began");
            
            // Adding place at point under pressed coordinates
            CGPoint point = [sender locationInView:_mapView];
            CLLocationCoordinate2D location = [_mapView convertPoint:point toCoordinateFromView:_mapView];
            [self addPlaceAtLatitude:location.latitude longitude:location.longitude];
        }
    } else if(sender.state == UIGestureRecognizerStateChanged) {
//        [_mapView deselectAnnotation:_editedAnnotation animated:NO];
        NSLog(@"Changed");
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        newPointReady = YES;
        NSLog(@"Ended");
        
        // End of long press, selecting annotation
        if(_editedAnnotation.annotationView != nil) {

            [_mapView selectAnnotation:_editedAnnotation animated:YES];

        }
    }
}

-(void)addPlaceAtLatitude:(double)latitude longitude:(double)longitude {
    NSLog(@"AddContent");
    if(_editedPlace==nil) {
        if(_editedObject == nil) {
            [_mapView deselectAnnotation:selectedAnnotation.annotation animated:NO];
            // Creating place
            [_dataService createPlaceAtLatitude:latitude longitude:longitude];
        }
    } else {
        [_uiService presentSnippetFor:_editedPlace opened:NO];
    }
}

-(void)geocodePlaceAddress:(Place*)place {
    [_conversionService reverseGeocodeAddressFor:place completion:^(NSString *address) {
        [place setAddress:address];
    }];
}
- (void)setEditedObject:(CALObject *)editedObject {
    NSString *key;
    if(editedObject != nil) {
        key = editedObject.key;
    } else {
        key = _editedObject.key;
    }
    // Nullifying to prevent infinite recusrive loop
    _editedObject = nil;
    // Preserving editor when we change annotation
    PMLEditor *editor;
    // Removing current annotation
    if(key != nil) {
        MKAnnotationView *annotationView = [_annotationsViewMap objectForKey:key];
        if([annotationView.annotation isKindOfClass:[MapAnnotation class]]) {
            editor = ((MapAnnotation*)annotationView.annotation).popupEditor;
        }
        [_mapView removeAnnotation:annotationView.annotation];
        [_annotationsKeyMap removeObjectForKey:key];
        [_annotationsViewMap removeObjectForKey:key];
    }
    
    
    // Re-selecting
    if(editedObject!=nil) {
        // Creating edited reference
        _editedObject = editedObject;
        _editedAnnotation = [self buildMapAnnotationFor:_editedObject];
        if(_editedAnnotation.popupEditor == nil) {
            _editedAnnotation.popupEditor=editor;
        }
        if(editedObject.key != nil || newPointReady) {
            [_mapView selectAnnotation:_editedAnnotation animated:YES];
        }
    } else {
        _editedObject= nil;
        if(_editedAnnotation != nil) {
            [_mapView deselectAnnotation:_editedAnnotation animated:YES];
            [_mapView removeAnnotation:_editedAnnotation];
            _editedAnnotation=nil;
        }

        [self updateAnnotations];
    }
    
}
#pragma mark - DataRefreshCallback
- (void)willLoadData {
    [self setEditedObject:nil];
    [self cancelEdition];
}

- (void)didLoadData:(ModelHolder *)modelHolder silent:(BOOL)isSilent {
    if(selectedAnnotation != nil){
        [self.mapView deselectAnnotation:selectedAnnotation.annotation animated:YES];
    }
    // Preparing our annotation list (for zooming)
    _placeAnnotations = [[NSMutableSet alloc] initWithCapacity:_modelHolder.places.count];

    // Hashing places by their ID for fast annotation lookup
    for(Place *place in modelHolder.places) {
        [_placeKeys addObject:place.key];
    }
    
    // Updating map with new content
    if(isSilent) {
        _zoomUpdateType = PMLZoomUpdateNone;
    }
    [self updateMap];
}
- (void)didLoadOverviewData:(CALObject *)object {
//    _contextObject = object; //self.parentMenuController.contextObject;
    if([object.key isEqualToString:_contextObject.key]) {
        [self fillContextKeys];
    }
}

- (void)reselectPlace:(Place*)place {
    // Removing any pre-existing entry

    MapAnnotation *annotation = [_annotationsKeyMap objectForKey:place.key];
    if(annotation != nil) {
        [_mapView deselectAnnotation:annotation animated:YES];
        [_mapView removeAnnotation:annotation];
        [_annotationsKeyMap removeObjectForKey:place.key];
    }

    annotation = [self buildMapAnnotationFor:place];
    [_mapView selectAnnotation:annotation animated:YES];
}

-(void)thumbAvailableFor:(Imaged *)place {
    
}
-(void)objectCreated:(CALObject *)object {
    if([object isKindOfClass:[Place class]]) {
        [self editPlaceLocation:(Place*)object centerMapOnPlace:NO];
    } else if([object isKindOfClass:[PMLBanner class]]) {

        // Editing banner
        [[TogaytherService actionManager] execute:PMLActionTypeEditBanner onObject:object];
    }
}
- (void)editRangeFor:(CALObject *)object {
    // Starting edition
    PMLEditor *editor = [PMLEditor editorFor:object on:self];
    [editor startEditionWith:^{
        [_editedRange removeFromSuperview];
        _editedRange = nil;
        _editedRangeObject = nil;
        [[_uiService menuManagerController] dismissControllerSnippet];
    } cancelledBy:^{
        [_editedRange removeFromSuperview];
        _editedRange = nil;
        _editedRangeObject = nil;
        
    } mapEdition:NO];
    
    _editedRangeObject = object;
    
    // Creating range hovering the map
    [self createEditedRange:object];

}
- (void)didUpdatePlace:(Place *)place {
    [self cancelEdition];
    [self reselectPlace:place];
}

#pragma mark - Edition management

- (void)cancelEdition {
    if(_editedPlace!=nil) {
        _editedPlace = nil;
        [_editedPlaceView removeFromSuperview];
    }
    if(_editedRange != nil) {
        [_editedRange removeFromSuperview];
        _editedRange = nil;
        _editedRangeObject = nil;
    }
}
- (void)editPlaceLocation:(Place *)place centerMapOnPlace:(BOOL)centerMap {
    _editedPlace = nil;

    // Adding cancel action to remove view and restore lat/lng/address information
    PMLEditor *editor = [PMLEditor editorFor:place on:self];
    
    __block double lat = place.lat;
    __block double lng = place.lng;
    __block NSString *address=place.address;
    __block Place *p = place;
    [editor startEditionWith:nil cancelledBy:^{
        // Restoring lat/lng
        p.lat = lat;
        p.lng = lng;
        p.address = address;
        
        // Resetting local edition state
        _editedPlace = nil;
        [_editedPlaceView removeFromSuperview];
        _editedPlaceView = nil;
    } mapEdition:NO];
    
    CGPoint mapCenter = [_mapView convertCoordinate:_mapView.centerCoordinate toPointToView:_mapView];
    if(!centerMap) {
        // Making sure place is at the center of map, altering place to be at map center
        CLLocationCoordinate2D coords = _mapView.centerCoordinate;
        place.lat=coords.latitude;
        place.lng=coords.longitude;
        
        // Geocoding
        [self geocodePlaceAddress:place];
    } else {
        // Otherwise we center the map on the place
        CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(place.lat, place.lng);
        _mapView.centerCoordinate = coords;
        if(place.key != nil) {
            MapAnnotation *ann = [_annotationsKeyMap objectForKey:place.key];
            [_mapView removeAnnotation:ann];
        }
        mapCenter.y+= self.parentMenuController.navigationController.navigationBar.frame.size.height/2;
    }
    place.editing = YES;
    
    // Showing snippet
    [_uiService presentSnippetFor:place opened:NO];
    
    // Adding central edition pin
    [self addCentralPin];
    
    // Registering for map region change updates
    _editedPlace = place;
}

-(void)addCentralPin {
    CGPoint mapCenter = [_mapView convertCoordinate:_mapView.centerCoordinate toPointToView:_mapView];
    
    // Placing view
    _editedPlaceView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mapPinNewPlace"]];
    CGRect imgFrame = CGRectMake(0, 0, 40, 40);
    _editedPlaceView.bounds=imgFrame;
    _editedPlaceView.frame = CGRectMake(self.mapView.center.x-CGRectGetWidth(imgFrame)/2,mapCenter.y-CGRectGetHeight(imgFrame), CGRectGetWidth(imgFrame), CGRectGetHeight(imgFrame));
    [self.mapView addSubview:_editedPlaceView];
}
-(void)createEditedRange:(CALObject*)object {
    // Adjusting zoom so that we make sure the ad range is fully displayed in the map
    CLLocationDistance dist = [self distanceForMapWidth];
    if(dist/METERS_PER_MILE < (kPMLBannerMilesRadius*1.5f)) {
        // Building our zoom rect around our center
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.mapView.centerCoordinate, kPMLBannerMilesRadius*2*1.5f*METERS_PER_MILE, kPMLBannerMilesRadius*2*1.5f*METERS_PER_MILE);
        MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
        MKMapRect mapRect = [self MKMapRectForCoordinateRegion:adjustedRegion];
        [_mapView setVisibleMapRect:mapRect animated:NO];
    }

    // Removing any previous range
    if(_editedRange != nil) {
        [_editedRange removeFromSuperview];
        _editedRange = nil;
    }
    
    // Centering if needed
    if(object.lat!=0 && object.lng!=0) {
        // Centering on object
        CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(object.lat, object.lng);
        [_mapView setCenterCoordinate:coords animated:NO];
        
        // Offsetting center by kSnippetEditHeight/2 pixels
        CGPoint mapCenter = [_mapView convertCoordinate:_mapView.centerCoordinate toPointToView:_mapView];
        CGPoint deltaCenter = CGPointMake(mapCenter.x, mapCenter.y+kSnippetEditHeight/2);
        CLLocationCoordinate2D newCoords= [_mapView convertPoint:deltaCenter toCoordinateFromView:_mapView];
        [_mapView setCenterCoordinate:newCoords animated:NO];
    }
    
    // Creating range
    _editedRange = [[UIView alloc] init ];
    _editedRange.layer.borderColor = [[UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1] CGColor];
    _editedRange.layer.borderWidth = 2;
    _editedRange.layer.masksToBounds=YES;
    _editedRange.userInteractionEnabled = NO;
    _editedRange.backgroundColor = [UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:0.4f];
    [self.mapView addSubview:_editedRange] ; //] belowSubview:_editedPlaceView];
    [self updateEditedRange];

}
-(void)updateEditedRange {

    CLLocationDistance dist = [self distanceForMapWidth];

    double milesRadius = dist/METERS_PER_MILE;
    double milesPerPixels = milesRadius / (double)self.mapView.bounds.size.width;
    double pixelsRadius = kPMLBannerMilesRadius / milesPerPixels;
    
    CGPoint mapCenter = [_mapView convertCoordinate:_mapView.centerCoordinate toPointToView:_mapView];
    _editedRange.frame = CGRectMake(mapCenter.x - pixelsRadius, mapCenter.y-pixelsRadius-kSnippetEditHeight/2, pixelsRadius*2, pixelsRadius*2);
    _editedRange.layer.cornerRadius = pixelsRadius;
    
    // Setting lat/lng to map center
    CLLocationCoordinate2D coords = [_mapView convertPoint:_editedRange.center toCoordinateFromView:_mapView];
    _editedRangeObject.lat = coords.latitude;
    _editedRangeObject.lng = coords.longitude;
}
#pragma mark - KVO observing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([object isKindOfClass:[PMLMenuManagerController class]]) {
        PMLMenuManagerController *controller = (PMLMenuManagerController*)object;
        
//        if([controller.contextObject isKindOfClass:[User class]]) {
//            // Init
            _contextObject = (User*)controller.contextObject;
            [self fillContextKeys];
//        }
        

    } else if([object isKindOfClass:[ModelHolder class]]) {
        if(!_initialUserLocationZoomDone) {
            // Centering
//            [_mapView setCenterCoordinate:_modelHolder.userLocation.coordinate animated:YES];
            // Unregistering
            [_modelHolder removeObserver:self forKeyPath:@"userLocation"];
            _initialUserLocationZoomDone = YES;
        }
    }
}
-(void)fillContextKeys {
    // Filling context keys with connected info from user
    _contextKeys = [[NSMutableArray alloc] init];
    if([_contextObject isKindOfClass:[User class]]) {
        User *user = (User*)_contextObject;
        for(CALObject *place in user.likedPlaces) {
            [_contextKeys addObject:place.key];
        }
    }
    for(NSString *key in _annotationsViewMap.keyEnumerator) {
        MKAnnotationView *annotationView = [_annotationsViewMap objectForKey:key];
        if(annotationView != nil) {
            if([_contextKeys containsObject:key] || _contextKeys.count==0) {
                annotationView.hidden=NO;
            } else {
                annotationView.hidden=YES; //alpha=0.3;
            }
        }
    }
}
#pragma mark - SettingsListener
- (void)filtersChanged {
    [self updateAnnotations];
}


#pragma mark - Show/hide management
-(void)show:(CALObject *)object {
    MKAnnotationView *view = [_annotationsViewMap objectForKey:object.key];
    view.alpha=1;
}
-(void)hide:(CALObject *)object {
    MKAnnotationView *view = [_annotationsViewMap objectForKey:object.key];
    view.alpha=0;
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorized) {
        self.mapView.showsUserLocation = YES;
        if(_lastAuthorizationStatus != status && _lastAuthorizationStatus != -1) {
            [_dataService fetchNearbyPlaces];
        }
    }
    _lastAuthorizationStatus = status;
}

@end
