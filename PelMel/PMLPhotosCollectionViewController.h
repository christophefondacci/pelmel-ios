//
//  PMLPhotosCollectionViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 06/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLActivityStatistic.h"
#import "MessageService.h"

@class PMLPhotosCollectionViewController;

@protocol PMLPhotosProvider <NSObject>

/**
 * The provider is expected to initialize its data, synchronously or asynchronously.
 * When the data is ready, it should call [controller updateData] to ask controller to fetch the data
 */
-(void)photoControllerStartContentLoad:(PMLPhotosCollectionViewController*)controller;
/**
 * Provides all objects that this provider wants to display in the photo grid
 */
-(NSArray*)allObjects;
/**
 * Provides the image to display for this object
 * @param controller the photo grid controller 
 * @param object the object to get the CALImage for
 * @return the CALImage to display
 */
-(CALImage*)photoController:(PMLPhotosCollectionViewController*)controller imageForObject:(NSObject*)object;
/**
 * Provides the label to display for this object
 * @param controller the photo grid controller
 * @param object the object to get the label for
 * @return the label to display below the image
 */
-(NSString*)photoController:(PMLPhotosCollectionViewController*)controller labelForObject:(NSObject*)object;
/**
 * Asks the provider to react on a user tap on the given element
 * @param controller the photo grid controller
 * @param object the object that received the tap
 */
-(void)photoController:(PMLPhotosCollectionViewController*)controller objectTapped:(NSObject*)object;
@optional
-(void)photoControllerDidTapCloseMenu:(PMLPhotosCollectionViewController*)controller;
@end

@interface PMLPhotosCollectionViewController : UICollectionViewController <UICollectionViewDelegateFlowLayout>

// Array of CALImage
//@property (nonatomic,retain) PMLActivityStatistic *activityStat;
@property (nonatomic,retain) id<PMLPhotosProvider> provider;
@property (nonatomic) BOOL loadFullImage;
-(void)updateData;
@end
