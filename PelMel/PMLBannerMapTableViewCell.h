//
//  PMLBannerMapTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 22/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "PMLBanner.h"

@interface PMLBannerMapTableViewCell : UITableViewCell <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic,retain) PMLBanner *banner;
@end
