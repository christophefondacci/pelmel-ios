//
//  MapAnnotation.h
//  nativeTest
//
//  Created by Christophe Fondacci on 25/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Place.h"

@class PMLPopupEditor;

@interface MapAnnotation : NSObject <MKAnnotation>

//@property (copy,nonatomic) NSString *title;
@property (copy) NSString *address;
@property (nonatomic,assign) CLLocationCoordinate2D coordinate;
@property (strong) CALObject *object;
@property (nonatomic,weak) MKAnnotationView *annotationView;
@property (nonatomic,strong) PMLPopupEditor *popupEditor;

-(id)initWithCoordinates:(CLLocationCoordinate2D)coordinates object:(CALObject*)object;
@end
