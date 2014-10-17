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
#import "DetailViewController.h"
#import "Constants.h"
#import "PMLMapPopupViewController.h"
#import "PMLPlaceAnnotationView.h"
#import "PMLSnippetTableViewController.h"
#import "MKNewPlaceAnnotationView.h"
#import "PlaceMasterProvider.h"
#import "PMLDataManager.h"
#import "MKNumberBadgeView.h"
#import "PMLInfoProvider.h"

@import QuartzCore;

#define kPMLMinimumPlacesForZoom 3

@interface MapViewController ()

@end

@implementation MapViewController {
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
    
    BOOL isNearbyMode;
    CALObject *_parentObject;
    
    // Annotation management
    NSMutableSet *_placeAnnotations;
    NSMutableDictionary *_annotationsKeyMap;
    NSMutableDictionary *_annotationsViewMap;
    NSMutableSet *_placeKeys;
    MapAnnotation *_editedAnnotation;
    
    long maxLikes;
    
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
    
    BOOL _snippetDisabledOnSelection;
    
}
@synthesize mapView = _mapView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [TogaytherService applyCommonLookAndFeel:self];
    
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

    if(_centralObject == nil && _modelHolder.parentObject == nil) {
//        [_mapView setUserTrackingMode:MKUserTrackingModeFollow animated:NO];
//        self.mapView.centerCoordinate = self.mapView.userLocation.location.coordinate;
    } else {
        [_mapView setUserTrackingMode:MKUserTrackingModeNone animated:NO];
    }
    
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
    [self updateMap];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([[segue identifier] isEqualToString:@"mapOverview"]) {
        MapAnnotation *mapAnnotation = selectedAnnotation.annotation;
        CALObject *object = mapAnnotation.object;
        
        DetailViewController *myDetailViewController = [segue destinationViewController];
        myDetailViewController.detailItem = object;
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
    //        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
    //        [self presentViewController:navigationController animated:YES completion:nil];
    //        [[self navigationController] presentViewController:detailViewController animated:YES completion:nil];
    
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
        [_mapView selectAnnotation:annotation animated:YES];
    } else {
        MapAnnotation *placeAnnotation = [self buildMapAnnotationFor:calObject];
        [_mapView selectAnnotation:placeAnnotation animated:YES];
    }
    _snippetDisabledOnSelection = NO;
}
#pragma mark - Map contributed menu actions
-(void)initializeMenuActions {
    // Providing our menu action (add content)
    _menuAddAction = [[MenuAction alloc] initWithIcon:[UIImage imageNamed:@"btnAdd"] pctWidth:1 pctHeight:0.5 action:^(PMLMenuManagerController *menuManagerController,MenuAction *menuAction) {
        NSLog(@"AddContent");
        CLLocationCoordinate2D coords = _mapView.centerCoordinate;
        [self addPlaceAtLatitude:coords.latitude longitude:coords.longitude];
    }];
    _menuAddAction.rightMargin=5;
    _menuAddAction.topMargin=58;
    
    // Refresh action
    _menuRefreshAction = [[MenuAction alloc] initWithIcon:[UIImage imageNamed:@"btnRefresh"] pctWidth:1 pctHeight:0.5 action:^(PMLMenuManagerController *menuManagerController, MenuAction *menuAction) {
        
        // Getting current map center coordinates
        CLLocationCoordinate2D centerCoords = _mapView.centerCoordinate;
        CLLocationCoordinate2D cornerCoords = [_mapView convertPoint:CGPointMake(0, 0) toCoordinateFromView:_mapView];

        // Distance between center and top left corner will give our distance for search
        CLLocation *centerLoc = [[CLLocation alloc] initWithLatitude:centerCoords.latitude longitude:centerCoords.longitude];
        CLLocation *cornerLoc = [[CLLocation alloc] initWithLatitude:cornerCoords.latitude longitude:cornerCoords.longitude];
        CLLocationDistance distance = [centerLoc distanceFromLocation:cornerLoc];
        int milesRadius = MIN(1500,distance/1609.344);
        
        
        [self.parentMenuController.dataManager refreshAt:centerCoords radius:milesRadius];
    }];
    _menuRefreshAction.rightMargin = 5;
    _menuRefreshAction.topMargin = 0; //topMargin = 100; //69;
    
    // My Position action
    _menuMyPositionAction = [[MenuAction alloc] initWithIcon:[UIImage imageNamed:@"btnPosition"] pctWidth:1 pctHeight:0.5 action:^(PMLMenuManagerController *menuManagerController, MenuAction *menuAction) {
        if(_mapView.showsUserLocation) {
            [_mapView setCenterCoordinate:_mapView.userLocation.coordinate animated:YES];
        }
    }];
    _menuMyPositionAction.rightMargin = 5;
    _menuMyPositionAction.topMargin = -184; //topMargin = 50;
    
}
-(void)updateMap {
    // First updating annotations because we might need them to compute initial zoom
    [self updateAnnotations];
    
    // Calibrating user tracking and initial zoom flags
    if(_centralObject == nil && _modelHolder.parentObject == nil) {
        _center = _modelHolder.userLocation.coordinate;
        if(!isNearbyMode) {
            _doneInitialZoom = NO;
        }
        isNearbyMode = YES;
    } else {
        if(isNearbyMode) {
            _doneInitialZoom = NO;
        }
        isNearbyMode = NO;
    }
    
    // Have we already setup initial zoom?
    if(!_doneInitialZoom) {
        //CLLocationCoordinate2D coords = [[mapView userLocation] coordinate];
        
        // Zooming to current user location with 800m x 800m wide rect
        if(_modelHolder.parentObject!= nil && _centralObject == nil) {
            _center.latitude = _modelHolder.parentObject.lat;
            _center.longitude =_modelHolder.parentObject.lng;
        }
        if(_center.latitude != 0 && _center.longitude !=0) {
            
            // Setting up width (a little bit larger for iPad)
            int width = 800;
            if([TogaytherService.uiService isIpad:self]) {
               width = 1600;
            }
            
            // Building our zoom rect
            MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(_center, width, width);
            MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];

            // Converting to a rect to check if we got anything nearby
            MKMapRect rect = [self MKMapRectForCoordinateRegion:adjustedRegion];
            NSSet *nearbyAnnotations = [_mapView annotationsInMapRect:rect];
            int placesCount = (int)nearbyAnnotations.count;
            
            // If we haven't got much in our rect, we check if we need to zoom fit or no
            if(placesCount<kPMLMinimumPlacesForZoom && (placesCount-1) < _modelHolder.places.count+_modelHolder.cities.count) {
                
                // If total places are bigger than current places in zoom rect then we zoom fit
                [_mapView showAnnotations:[_placeAnnotations allObjects] animated:YES];
                
            } else {
                
                // We will have a good nearby view
                _mapView.camera.pitch = 0;
                _zoomAnimation = YES;
                NSSet *annotationsToDisplay = nearbyAnnotations.count > 0 ? nearbyAnnotations : _placeAnnotations;
                [_mapView showAnnotations:[annotationsToDisplay allObjects] animated:YES];
//                [_mapView setUserTrackingMode:MKUserTrackingModeNone];
//                [_mapView setRegion:adjustedRegion animated:YES];
//                _mapView.pitchEnabled = YES;
//                _mapView.camera.pitch = 70;
//                [_mapView setCenterCoordinate:adjustedRegion.center];
            }
            _mapInitialCenter = [[CLLocation alloc] initWithLatitude:_mapView.centerCoordinate.latitude longitude:_mapView.centerCoordinate.longitude];
        }
        _doneInitialZoom = YES;

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

- (void)updateAnnotations {

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
    
    // EXPERIMENTAL Computing max likes
    maxLikes = 0;
    for(place in _modelHolder.places) {
        if(place.likeCount+place.inUserCount>maxLikes) {
            maxLikes = place.likeCount+place.inUserCount;
        }
    }
    
    // Building annotations from places
    BOOL centralObjectProcessed = NO;
    for(place in _modelHolder.places) {
        BOOL visible = [_settingsService isVisible:place];
        if(visible && place.lat!=0 && place.lng!=0) {
            // Building annotation
            MapAnnotation *annotation = [self buildMapAnnotationFor:place];
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

    return annotation;
}

- (IBAction)showPlace:(id)sender {
    NSLog(@"showPlace");
    if(selectedAnnotation != nil) {
        if(self.splitViewController == nil) {
            [self performSegueWithIdentifier:@"mapOverview" sender:self];
        } else {
            DetailViewController *detailController = (DetailViewController*)[TogaytherService.uiService instantiateViewController:SB_ID_DETAIL_CONTROLLER];
            MapAnnotation *mapAnnotation = selectedAnnotation.annotation;
            CALObject *place = mapAnnotation.object;
            detailController.detailItem = place;
            [TogaytherService.uiService.splitMainNavController pushViewController:detailController animated:YES];
        }
    }
    
}


- (void)setCentralObject:(CALObject *)centralObject {
    _centralObject = centralObject;
    if([TogaytherService.uiService isIpad:self]) {
        [self updateMap];
    }
}
- (void)setCenter:(CLLocationCoordinate2D)center {
    _center = center;
    if([TogaytherService.uiService isIpad:self]) {
        [self updateMap];
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
            if ( placeAnnotation == nil ) {
                placeAnnotation = [[PMLPlaceAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:defaultPinID];
            } else {
                placeAnnotation.annotation = annotation;
            }
            // Assigning
            pinAnnotation = placeAnnotation;

            // Size computation
            double ratio = 0;
            if(maxLikes > 0) {
                long count = object.likeCount;
                if([object isKindOfClass:[Place class]]) {
                    count += ((Place*)object).inUserCount;
                }
                ratio = ((double)count) / (double)maxLikes;
            }
            if([object isKindOfClass:[City class] ]) {
                ratio = 2;
            }
            placeAnnotation.sizeRatio = @(ratio*0.3+0.7);
            placeAnnotation.enabled = YES;
            placeAnnotation.canShowCallout = NO;
            
            // Selecting image depending on openings
            UIImage *markerImage = [_uiService mapMarkerFor:object enabled:YES];

            placeAnnotation.alpha=1;
            // Looking for opening hours
            if([object isKindOfClass:[Place class]]) {
                Place *p = (Place*)object;
                for(Special *special in p.specials) {
                    if([special.type isEqualToString:SPECIAL_TYPE_OPENING]) {
                        switch([_conversionService specialModeFor:special]) {
                            case PAST:
                            case SOON:
                                markerImage = [_uiService mapMarkerFor:object enabled:NO];
                                break;
                            default:
                                break;
                        }
                    }
                }
                // If closed we gray the image
                if(p.closedReportsCount>0) {
                    markerImage = [_uiService mapMarkerFor:object enabled:NO];
                }
            }

            placeAnnotation.imageCenterOffset = [_uiService mapMarkerCenterOffsetFor:object];
            placeAnnotation.image = markerImage;
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
    NSLog(@"didSelect");
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
            PMLSnippetTableViewController *snippetController = (PMLSnippetTableViewController*)[TogaytherService.uiService instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
            snippetController.snippetItem = place;
            [self.parentMenuController presentControllerSnippet:snippetController];
        }
        
        if(_popupController != nil) {
            [_popupController dismiss];
        }
        _popupController = [[PMLMapPopupViewController alloc] initWithObject:mapAnnotation.object inParentView:view withController:self];
        [self.parentMenuController.view endEditing:YES];
    }
}


- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"didDeselect");
    if(!_snippetDisabledOnSelection) {
        [self.parentMenuController dismissControllerSnippet];
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
//    CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:_mapView.centerCoordinate.latitude longitude:_mapView.centerCoordinate.longitude];
    if(_zoomAnimation) {
        _zoomAnimation = NO;
        MKMapCamera *camera = [MKMapCamera camera];
        camera.centerCoordinate = _mapView.camera.centerCoordinate;
        camera.heading = _mapView.camera.heading;
        camera.altitude = _mapView.camera.altitude;
        camera.pitch=70;
        
        [_mapView setCamera:camera animated:YES];
        
    }
//    if(_doneInitialZoom) {
//        // If we moved more than 100km (our current search radius, then we display refresh
//        if([currentLocation distanceFromLocation:_mapInitialCenter]>=50000 && !_refreshVisible) {
//            _refreshVisible = YES;
//            [self.parentMenuController.menuManagerDelegate addMenuAction:_menuRefreshAction];
//        }
//    }
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
    _doneInitialZoom = NO;

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
