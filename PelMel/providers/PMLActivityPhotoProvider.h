//
//  PMLActivityPhotoProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 03/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLPhotosCollectionViewController.h"
#import "MessageService.h"

@interface PMLActivityPhotoProvider : NSObject<PMLPhotosProvider,ActivitiesCallback>

-(instancetype)initWithActivityType:(NSString*)activityType;
@end
