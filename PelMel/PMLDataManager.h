//
//  UIDataManager.h
//  PelMel
//
//  Created by Christophe Fondacci on 14/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TogaytherService.h"

@class PMLMenuManagerController;

@interface PMLDataManager : NSObject <PMLDataListener,PMLUserCallback,PMLImagePickerCallback,PMLImageUploadCallback>

/**
 * Initializes the data manager on the given view controller
 */
- (instancetype)initWith:(PMLMenuManagerController*)controller;

/**
 * Refreshes the current list of contents for the given coordinates using the radius
 * @param coordinates lat/long of the center of the search, closest results from this point will be returned
 * @param radius max radius in miles to search from the center, a radius of 0 means default search radius
 */
-(void)refreshAt:(CLLocationCoordinate2D)coordinates radius:(double)radius;
-(void)refresh;
/**
 * Prompts the user to upload a photo
 */
-(void)promptUserForPhotoUploadOn:(CALObject*)object;

@end
