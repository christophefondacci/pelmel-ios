//
//  MapAnnotation.m
//  nativeTest
//
//  Created by Christophe Fondacci on 25/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "MapAnnotation.h"
#import "Place.h"
#import "TogaytherService.h"

@implementation MapAnnotation


- (id)initWithCoordinates:(CLLocationCoordinate2D)coordinate object:(CALObject*)object {
    if(self = [super init]) {
//        self.title= [title copy];
//        self.subtitle = [subtitle copy];
        _coordinate=CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude);
        self.object = object;
    }
    return self;
}

-(void)setCoordinate:(CLLocationCoordinate2D)coordinate {
    _object.lat = coordinate.latitude;
    _object.lng = coordinate.longitude;
    _coordinate = coordinate;
    if([self.object isKindOfClass:[Place class]]) {
        [[TogaytherService getConversionService] geocodeAddressFor:self.object completion:^(NSString *address) {
            ((Place*)self.object).address = address;
        }];
    }
}
@end
