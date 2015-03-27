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

@import QuartzCore;

#define kPMLMinimumPlacesForZoom 3



@interface MapViewController ()

@end

@implementation MapViewController {
    NSUserDefaults *_userDefaults;
    
    ModelHolder *_modelHolder;
    DataService *_dataService;
    UserService *_userService;
    UIService *_uiService;
    ConversionService *_conversionService;
    SettingsService *_settingsService;
    MKAnnotationView *selectedAnnotation;

    
    // Internal for adding new point management
    UILongPressGestureRecognizer *gestureRecognizer;
    BOOL newPointReady;
    
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
    
    // Menu management
    MenuAction *_menuAddAction;
    MenuAction *_menuRefreshAction;
    MenuAction *_menuMyPositionAction;
    BOOL _zoomAnimation;
    
    // Context filters
    NSMutableArray *_contextKeys;
    CALObject *_contextObject;
    
    // Geocoding
    CLGeocoder *_geocoder;
    BOOL _initialUserLocationZoomDone;
    
    BOOL _snippetDisabledOnSelection;
    
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
    _modelHolder = _dataService.modelHolder;
    newPointReady = YES;
    
    [_settingsService addSettingsListener:self];
    
    _annotationsKeyMap = [[NSMutableDictionary alloc] init];
    _annotationsViewMap = [[NSMutableDictionary alloc] init];
    _placeKeys = [[NSMutableSet alloc] init];
    
    // Geocoding
    _geocoder = [[CLGeocoder alloc] init];
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
    gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(mapPressed:)];
    [_mapView addGestureRecognizer:gestureRecognizer];
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
    [self.parentMenuController.menuManagerDelegate setupMenuAction:_menuMyPositionAction];
    
    [self.parentMenuController addObserver:self forKeyPath:@"contextObject" options:NSKeyValueObservingOptionNew context:NULL];
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
    _menuAddAction = [[MenuAction alloc] initWithIcon:[UIImage imageNamed:@"btnAdd"] pctWidth:1 pctHeight:1 action:^(PMLMenuManagerController *menuManagerController,MenuAction *menuAction) {
        NSLog(@"AddContent");
        CLLocationCoordinate2D coords = _mapView.centerCoordinate;
        [self addPlaceAtLatitude:coords.latitude longitude:coords.longitude];
    }];
    _menuAddAction.rightMargin=5;
    _menuAddAction.bottomMargin=160;
    
    // Refresh action
    _menuRefreshAction = [[MenuAction alloc] initWithIcon:[UIImage imageNamed:@"btnRefresh"] pctWidth:1 pctHeight:0 action:^(PMLMenuManagerController *menuManagerController, MenuAction *menuAction) {
        
        // Getting current map center coordinates
        CLLocationDistance distance = [self distanceFromCornerPoint];
        double milesRadius = distance/1609.344f;

        // No zoom, updating behind the scenes
        _zoomUpdateType = PMLZoomUpdateNone;
        [self.parentMenuController.dataManager refreshAt:_mapView.centerCoordinate radius:milesRadius];
    }];
    _menuRefreshAction.rightMargin = 5;
    _menuRefreshAction.topMargin = 84+24+50+5; //topMargin = 100; //69;
    
    // My Position action
    _menuMyPositionAction = [[MenuAction alloc] initWithIcon:[UIImage imageNamed:@"btnPosition"] pctWidth:1 pctHeight:00 action:^(PMLMenuManagerController *menuManagerController, MenuAction *menuAction) {
        if(_mapView.showsUserLocation) {
            
            // First zoom mode: center on current position
            CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:_mapView.centerCoordinate.latitude longitude:_mapView.centerCoordinate.longitude];
            if([_mapView.userLocation.location distanceFromLocation:centerLocation] < 750000) {
                [_mapView setCenterCoordinate:_mapView.userLocation.location.coordinate animated:YES];
                _menuRefreshAction.menuAction(self.parentMenuController,_menuRefreshAction);
            } else {
                _zoomUpdateType = PMLZoomUpdateAroundLocation;
                [_dataService fetchNearbyPlaces];
            }
        } else {
            NSString *title = NSLocalizedString(@"action.myposition.alertTitle", @"action.myposition.alertTitle");
            NSString *msg = NSLocalizedString(@"action.myposition.alertMsg", @"action.myposition.alertMsg");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alert show];
        }
    }];
    _menuMyPositionAction.rightMargin = 5;
    _menuMyPositionAction.topMargin = 84+24; //topMargin = 50;
    
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
        

//    } else if([annotation.annotationView isKindOfClass:[PMLPlaceAnnotationView class]]) {
//        [((PMLPlaceAnnotationView*)annotation.annotationView) updateData];
    }

    return annotation;
}

//
//- (void)setCentralObject:(CALObject *)centralObject {
//    _centralObject = centralObject;
//    if([TogaytherService.uiService isIpad:self]) {
//        [self updateMap];
//    }
//}
//- (void)setCenter:(CLLocationCoordinate2D)center {
//    _center = center;
//    if([TogaytherService.uiService isIpad:self]) {
//        [self updateMap];
//    }
//}

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
            
            // Selecting image depending on openings
            UIImage *offMarkerImage = [_uiService mapMarkerFor:object enabled:NO];
            UIImage *onMarkerImage = [_uiService mapMarkerFor:object enabled:YES];
            UIImage *markerImage = onMarkerImage;

            placeAnnotation.alpha=1;
            // Looking for opening hours
            if([object isKindOfClass:[Place class]]) {
                Place *p = (Place*)object;
                if([_conversionService calendarType:SPECIAL_TYPE_OPENING isCurrentFor:p noDataResult:YES]) {
                    markerImage = onMarkerImage;
                } else {
                    markerImage = offMarkerImage;
                }
// If closed we gray the image
//                if(p.closedReportsCount>0) {
//                    markerImage = [_uiService mapMarkerFor:object enabled:NO];
//                }
            }

            placeAnnotation.imageCenterOffset = [_uiService mapMarkerCenterOffsetFor:object];
            placeAnnotation.image = markerImage;
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
//    if(_zoomUpdateType == PMLZoomUpdateNone) {
//        // If we moved more than 100km (our current search radius, then we display refresh
//        if([currentLocation distanceFromLocation:_mapInitialCenter]>=50000) {
//            if([[_mapView annotationsInMapRect:_mapView.visibleMapRect] count] == 0) {
//                [UIView animateWithDuration:0.2 animations:^{
//                    _menuRefreshAction.menuActionView.transform = CGAffineTransformRotate(_menuRefreshAction.menuActionView.transform, M_PI_2);
//                }];
//            }
//        }
//    }
    NSSet *annotations = [self.mapView annotationsInMapRect:self.mapView.visibleMapRect];
    if(annotations.count < 300) {
            _labelsVisible = YES;
            [self toggleLabelsVisibility:YES forAnnotations:annotations];
    } else if(_labelsVisible) {
        _labelsVisible = NO;
        NSArray *annotations = [self.mapView annotations];
        [self toggleLabelsVisibility:NO forAnnotations:annotations];
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
    if(_editedObject == nil) {
        [_mapView deselectAnnotation:selectedAnnotation.annotation animated:NO];
        // Creating place
        [_dataService createPlaceAtLatitude:latitude longitude:longitude];
    }
}
-(void)geocodePlaceAddress:(Place*)place {
    [_conversionService geocodeAddressFor:place completion:^(NSString *address) {
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
    PMLPopupEditor *editor;
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
}

- (void)didLoadData:(ModelHolder *)modelHolder {

    // Preparing our annotation list (for zooming)
    _placeAnnotations = [[NSMutableSet alloc] initWithCapacity:_modelHolder.places.count];

    // Hashing places by their ID for fast annotation lookup
    for(Place *place in modelHolder.places) {
        [_placeKeys addObject:place.key];
    }
    
    // Purging all our previous data
//    [_annotationsKeyMap removeAllObjects];
//    [_annotationsViewMap removeAllObjects];
    
    // Updating map with new content
    [self updateMap];
//    [self updateAnnotations];
//    [_mapView showAnnotations:[_placeAnnotations allObjects] animated:YES];
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
//- (void)didUpdatePlace:(Place *)place {
//    if(_editedObject != nil) {
//        // Deselect / reselect
//        [_mapView deselectAnnotation:_editedAnnotation animated:YES];
//        [_mapView removeAnnotation:_editedAnnotation];
//        [_annotationsKeyMap removeObjectForKey:place.key];
//
//        _editedObject = nil;
//        
//        MapAnnotation *annotation = [self buildMapAnnotationFor:place];
//        [_mapView selectAnnotation:annotation animated:YES];
//    }
//}
-(void)thumbAvailableFor:(Imaged *)place {
    
}
-(void)objectCreated:(CALObject *)object {
    if([object isKindOfClass:[Place class]]) {
        Place *place = (Place*)object;
        [self setEditedObject:place];
//        CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(object.lat, object.lng);
//        
//        // Adding annotation
//        newPointAnnotation = [[MapAnnotation alloc] initWithCoordinates:coords object:place];
//        [_mapView addAnnotation:newPointAnnotation];
        
        // Geocoding
        [self geocodePlaceAddress:place];
    }
    
}

#pragma mark - UserLoginCallback
//- (void)authenticationFailed:(NSString *)reason {
//    [self performSegueWithIdentifier:@"login" sender:self];
//}
//- (void)dataLoginFailed {
//    [_userService authenticateWithLastLogin:self];
//}
//-(void)initDataAfterLogin {
//    [_dataService fetchPlacesFor:_parentObject];
//}
//- (void)userAuthenticated:(CurrentUser *)user {
//    [self initDataAfterLogin];
//}

-(void)searchText:(id)sender {
    
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
