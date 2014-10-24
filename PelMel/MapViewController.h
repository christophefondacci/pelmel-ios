//
//  MapViewController.h
//  nativeTest
//
//  Created by Christophe Fondacci on 25/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "ModelBased.h"
#import "DataService.h"
#import "PMLMenuManagerController.h"
#import "SettingsService.h"
#import "PMLPopupActionManager.h"

@interface MapViewController : UIViewController <MKMapViewDelegate,PMLDataListener, PMLUserCallback, UITextFieldDelegate,SettingsListener,CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *warningLabel;
@property (nonatomic) CLLocationCoordinate2D center;
@property (weak, nonatomic) CALObject *centralObject;
@property (weak,nonatomic) CALObject *editedObject;
@property (strong, nonatomic) PMLPopupActionManager *popupActionManager;
@property (strong, nonatomic) PMLMapPopupViewController *popupController;
//@property (nonatomic) BOOL ignoreSelectionEvents;

-(void)updateMap;

/**
 * Selects the provided object, if currently displayed on the map
 */
-(void)selectCALObject:(CALObject*)calObject;
/**
 * Selects the provided object, if currently displayed on the map, and allows to trigger the snippet
 */
-(void)selectCALObject:(CALObject*)calObject withSnippet:(BOOL)snippetEnabled;
- (void)reselectPlace:(Place*)place;

-(void)show:(CALObject*)object;
-(void)hide:(CALObject*)object;
@end
