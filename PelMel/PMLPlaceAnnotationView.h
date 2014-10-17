//
//  MKPlaceAnnotationView.h
//  PelMel
//
//  Created by Christophe Fondacci on 21/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface PMLPlaceAnnotationView : MKAnnotationView

//@property (nonatomic,weak) UIView *mainView;
@property (nonatomic) NSNumber *sizeRatio;
// The center off
@property (nonatomic) CGPoint imageCenterOffset;

@end
