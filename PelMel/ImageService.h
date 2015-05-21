//
//  ImageService.h
//  togayther
//
//  Created by Christophe Fondacci on 09/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Imaged.h"
#import "UIImageExtras.h"
#import "CALObject.h"
#import "Place.h"
#import "SizedTTLCacheService.h"
#import "CALImage.h"

@class UIService;
typedef void (^ImageLoaderBlock)(CALImage *image);
@protocol ImageLoaderCallback <NSObject>

-(void)imageLoaded:(CALImage*)calImage;

@end
@protocol PMLImagePickerCallback
-(void)imagePicked:(CALImage*)image;
@end

@protocol PMLImageUploadCallback
-(void)imageUploaded:(CALImage*)image;
-(void)imageUploadFailed:(CALImage*)image;
@end

@protocol ImageManagementCallback
-(void)imageReordered:(CALImage*)image;
-(void)imageRemoved:(CALImage*)image;
-(void)imageRemovalFailed:(CALImage*)image message:(NSString*)message;
@end



@interface ImageService : NSObject <UIActionSheetDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate>

// The cache service that needs to be injected
@property (strong,nonatomic) NSCache *imageCache;
@property (strong,nonatomic) UIService *uiService;

// Pre-loading thumbs images of the given element
-(void)prepareLoad:(Imaged*)imaged;

// New generic image loader method
-(void)load:(CALImage*)image to:(UIImageView*)imageView thumb:(BOOL)thumb;
-(void)load:(CALImage*)image to:(UIImageView*)imageView thumb:(BOOL)thumb callback:(ImageLoaderBlock)callback;

/**
 * Cancels any running image fetch process (generally because we are about to initialize a new one
 */
-(void)cancelRunningProcesses;

/**
 * Registers the specified view as tappable and assigns the provided callback to it
 */
-(void)registerTappable:(UIView*)imageView forViewController:(UIViewController*)controller callback:(id<PMLImagePickerCallback>)callback;
-(void)registerImageUploadFromLibrary:(UIView*)view forViewController:(UIViewController*)controller callback:(id<PMLImagePickerCallback>)callback;
-(void)unregisterTappable:(UIView*)imageView;
/**
 * Prompts the user to first select a photo source and then will retrieve the photo
 * and provide it back to the callback
 */
- (void)promptUserForPhoto:(UIViewController*)controller callback:(id<PMLImagePickerCallback>)callback;
/**
 * Upload the specified image to the server and assigns it to the given parent object
 */
-(void)upload:(CALImage*)image forObject:(CALObject*)parent callback:(id<PMLImageUploadCallback>)callback;
/**
 * Removes the specified image from the server
 */
-(void)remove:(CALImage*)image callback:(id<ImageManagementCallback>)callback;

/**
 * Reorders the specified image to the given index in the parent
 */
-(void)reorder:(CALImage*)image newIndex:(int)index callback:(id<ImageManagementCallback>)callback;

-(UIImage*)getTagImage:(NSString*)tagCode;

-(UIImage*)getOnlineImage:(BOOL)isOnline;

/** 
 * Builds a CALImage bean from JSON light image information
 */
- (CALImage *)convertJsonImageToImage:(NSDictionary*)jsonImage;

/**
 * Decorates the given image view with the provided image in the upper left corner
 */
-(void)decorate:(UIImageView*)parentView decorator:(UIImage*)decorator;

/**
 * Provides the most appropriate CAL Image for the object, providing 
 * a placeholder if needed
 */
-(CALImage*)imageOrPlaceholderFor:(CALObject*)object allowAdditions:(BOOL)additionsAllowed;

/**
 * Fetches the full main image of the provided element.
 */
//-(void)getOverviewMainImage:(Imaged*)imaged callback:(id<ImageRefreshCallback>)callback;

/**
 * Fetches one other image, specified by its index, of the provided element
 */
//-(void)getOverviewOtherImage:(Imaged*)imaged index:(NSInteger)index callback:(id<ImageRefreshCallback>)callback;

@end
