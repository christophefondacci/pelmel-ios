//
//  ImageService.m
//  togayther
//
//  Created by Christophe Fondacci on 09/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageService.h"
#import "Imaged.h"
#import "CALImage.h"
#import "TogaytherService.h"
#import "UIImage+Resize.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageManager.h>
#import <AFNetworking.h>

#define kAddMediaUrl @"%@/mobileAddMedia"
#define kReorderMediaUrl @"%@/moveMedia?id=%@&parent=%@&newIndex=%d&nxtpUserToken=%@"
#define kRemoveMediaUrl @"%@/mobileDeleteMedia?id=%@&nxtpUserToken=%@&confirmed=true"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define kTopQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
#define kMaxInterval 10
#define kInitialInterval 0.2

#define kReportTypeAbuse 1
#define kReportTypeClosed 2

#define kActionCameraIndex 0
#define kActionLibraryIndex 1
#define kActionCancelIndex 2

@implementation ImageService {
    NSMutableDictionary *operationsMap;
    NSMutableDictionary *urlMap;
    
    NSMutableDictionary *tapImagesControllerMap;
    NSMutableDictionary *tapImagesCallbackMap;
    
    NSMutableDictionary *uploadConnectionImagesMap;
    NSMutableDictionary *uploadConnectionCallbacksMap;
    NSMutableDictionary *uploadDataMap;

    NSString *togaytherServer;
    
    NSMutableDictionary *tagImagesMap;

    UIImage *onlineImage;
    UIImage *offlineImage;
    
    // Image picker state handling
    id<PMLImagePickerCallback> _pickerCallback;
    UIView *_pickerView;
    UIViewController *_pickerParentController;
    
    UIService *_uiService;
    
}

@synthesize imageCache = imageCache;

- (id)init
{
    self = [super init];
    if (self) {
        operationsMap = [[NSMutableDictionary alloc] init];
        urlMap = [[NSMutableDictionary alloc] init];
        tapImagesControllerMap= [[NSMutableDictionary alloc] init];
        tapImagesCallbackMap= [[NSMutableDictionary alloc] init];
        uploadConnectionImagesMap= [[NSMutableDictionary alloc] init];
        uploadConnectionCallbacksMap= [[NSMutableDictionary alloc] init];
        uploadDataMap               = [[NSMutableDictionary alloc] init];
        tagImagesMap = [[NSMutableDictionary alloc]init];

        togaytherServer = [TogaytherService propertyFor:PML_PROP_SERVER];
        
        onlineImage = [UIImage imageNamed:@"online.png"];
        offlineImage = [UIImage imageNamed:@"offline.png"];
        
        // Initializing tags
        
    }
    return self;
}

-(NSString*)buildKey:(NSInteger)index {
    return [[NSString alloc] initWithFormat:@"%d",(int)index];
}
-(NSString*)buildKeyFromPointer:(id)pointer {
    return [[NSString alloc] initWithFormat:@"%p",pointer];
}
-(void)unregisterTappable:(UIImageView *)imageView {
    NSString *key = [self buildKeyFromPointer:imageView];
    [tapImagesControllerMap removeObjectForKey:key];
    [tapImagesCallbackMap removeObjectForKey:key];
}
- (void)registerTappable:(UIView *)imageView forViewController:(UIViewController *)controller callback:(id<PMLImagePickerCallback>)callback {
    // Creating our gesture recognizer
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    
    // Saving info and associate it to image view
    NSString *key = [self buildKeyFromPointer:imageView];
    [tapImagesControllerMap setObject:controller forKey:key];
    [tapImagesCallbackMap setObject:callback forKey:key];
    
    // Adding the gesture recognizer to the image view
    [imageView addGestureRecognizer:recognizer];
}

- (void)imageTapped:(UITapGestureRecognizer*)recognizer {

    // Prompting
    NSString *key = [self buildKeyFromPointer:recognizer.view];
    UIViewController *controller = [tapImagesControllerMap objectForKey:key];
    id<PMLImagePickerCallback> callback = [tapImagesCallbackMap objectForKey:key];
    [self promptUserForPhoto:controller callback:callback];
}

- (void)promptUserForPhoto:(UIViewController*)controller callback:(id<PMLImagePickerCallback>)callback {
    _pickerCallback = callback;
    _pickerParentController = controller;
    
    // Ask the user the photo source
    NSString *title= NSLocalizedString(@"profile.photo.title","cancel");
    NSString *cancel= NSLocalizedString(@"cancel","cancel");
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"profile.photo.take", "Choice to take a photo")];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"profile.photo.library", "Choice to pick a photo from iPhone's library")];
    [actionSheet addButtonWithTitle:cancel];
    actionSheet.cancelButtonIndex = kActionCancelIndex;

    UIView *tabBar = _pickerParentController.tabBarController.tabBar;
    if(tabBar != nil) {
        [actionSheet showFromTabBar:_pickerParentController.tabBarController.tabBar];
    } else {
        [actionSheet showInView:_pickerParentController.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex == kActionCancelIndex) {
        [self cancelActionSheet];
    }
    NSLog(@"Dismissed action sheet");
}
-(void) cancelActionSheet {
    _pickerView = nil;
    _pickerParentController = nil;
    _pickerCallback = nil;
}
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.navigationBar.tintColor = [UIColor blackColor];
    pickerController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    // We set ourselves as delegate
    pickerController.delegate = self;
    
    // Photo or library mode
    switch(buttonIndex) {
        case kActionCameraIndex:
            pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            break;
        case kActionLibraryIndex:
            [pickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            break;
        default:
            [self cancelActionSheet];
            return;
    }
    // Showing the controller asynchronously after delay to workaround "wait_fences" problem
    [self performSelector:@selector(showPicker:) withObject:pickerController afterDelay:0.1];
    
}
-(void)showPicker:(UIImagePickerController *)pickerController {
    // Here we go
    [_pickerParentController presentViewController:pickerController animated:NO completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    // Dismissing picker
    [_pickerParentController dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    // Getting resulting image
//    UIImage *pickedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
//    UIImage *resized = [pickedImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:pickedImage.size interpolationQuality:kCGInterpolationHigh];
    
    UIImage *fullImage = (UIImage*) [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImage *resized = [self scaleAndRotateImage:fullImage];
    UIImage *thumbImage = [resized imageByScalingAndCroppingForSize:CGSizeMake(111, 111)];

    CALImage *image = [[CALImage alloc] init];
    image.fullImage = resized;
    image.thumbImage = thumbImage;
    // Dismissing picker
    [_pickerParentController dismissViewControllerAnimated:YES completion:^{
        // Invoking callback
        [_pickerCallback imagePicked:image];
        _pickerCallback = nil;
        _pickerParentController = nil;
        _pickerView = nil;
    }];
}

- (UIImage *)scaleAndRotateImage:(UIImage *)image {
    int kMaxResolution = 1000; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = roundf(bounds.size.width / ratio);
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = roundf(bounds.size.height * ratio);
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}
- (void)upload:(CALImage *)image forObject:(CALObject*)parent callback:(id<PMLImageUploadCallback>)callback {
    CurrentUser *user = [[TogaytherService userService] getCurrentUser];
    
    // Building URL
    NSString *url = [[NSString alloc] initWithFormat:kAddMediaUrl,togaytherServer];
    
    // AFNetworking version
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [_uiService reportProgress:(float)0.05f];
    AFHTTPRequestOperation *operation = [manager POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSData *imageData = UIImageJPEGRepresentation(image.fullImage, 1.0);
        NSString *fileParam = @"media";
        [formData appendPartWithFileData:imageData
                                    name:fileParam
                                fileName:@"userPhoto" mimeType:@"image/jpeg"];
        
        [formData appendPartWithFormData:[parent.key dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"parentKey"];
        
        [formData appendPartWithFormData:[user.token dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"nxtpUserToken"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Response: %@", responseObject);
        NSDictionary *json = (NSDictionary*)responseObject;
        NSString *key       = [json valueForKey:@"key"];
        NSString *thumbUrl  = [json valueForKey:@"thumbUrl"];
        NSString *url       = [json valueForKey:@"url"];
        
        // Injecting data back into image
        [image setKey:key];
        [image setThumbUrl:thumbUrl];
        [image setImageUrl:url];
        
        // Invoking callback
        if(callback != nil) {
            [callback imageUploaded:image];
        }
        [_uiService progressDone];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [callback imageUploadFailed:image];
        [_uiService progressDone];
    }];
    [_uiService reportProgress:(float)0.1f];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        double progressPct = (double)totalBytesWritten/(double)totalBytesExpectedToWrite;
        [_uiService reportProgress:0.1f+0.5f*(float)progressPct];
    }];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        double progressPct = (double)totalBytesRead/(double)totalBytesExpectedToRead;
        [_uiService reportProgress:0.6f+0.4f*(float)progressPct];
    }];
    
    
}

- (void)reorder:(CALImage *)image newIndex:(int)index callback:(id<ImageManagementCallback>)callback {
    CurrentUser *user = [[TogaytherService userService] getCurrentUser];
    NSString *key = image.key;
    dispatch_async(kTopQueue, ^{
        NSString *url = [NSString stringWithFormat:kReorderMediaUrl,togaytherServer,key,user.key,index,user.token];
        // Calling reorder on server
        [NSData dataWithContentsOfURL:[NSURL URLWithString: url]];
        // Ok, we notify
        dispatch_async(dispatch_get_main_queue(), ^{
            [callback imageReordered:image];
        });
    });

}

- (void)remove:(CALImage *)image callback:(id<ImageManagementCallback>)callback{
    CurrentUser *user = [[TogaytherService userService] getCurrentUser];
    NSString *url = [NSString stringWithFormat:kRemoveMediaUrl,togaytherServer,image.key,user.token];
    dispatch_async(kTopQueue, ^{
        NSData *response = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        if(response != nil) {
            NSError *error;
            NSDictionary *jsonInfo = [NSJSONSerialization
                                           JSONObjectWithData:response //1
                                           options:kNilOptions
                                           error:&error];
            NSNumber *isError  = [jsonInfo objectForKey:@"error"];
            BOOL hasError = [isError boolValue];
            NSString *errorMsg = [jsonInfo objectForKey:@"message"];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(!hasError) {
                    [callback imageRemoved:image];
                } else {
                    [callback imageRemovalFailed:image message:errorMsg];
                }
            });
        }

    });
}
-(UIImage *)getTagImage:(NSString *)tagCode {
    // Lookup in our cache
    UIImage *image = [tagImagesMap objectForKey:tagCode];
    // Initializing image if not found
    if(image == nil) {
        image = [UIImage imageNamed:[[NSString alloc] initWithFormat:@"%@.png",tagCode]];
        if(image!=nil) {
            [tagImagesMap setObject:image forKey:tagCode];
        }
    }
    return image;
}
- (void)cancelRunningProcesses {

}
- (CALImage *)convertJsonImageToImage:(NSDictionary*)jsonImage {
    if(jsonImage != nil && jsonImage != (id)[NSNull null]) {
        NSString *key       = [jsonImage objectForKey:@"key"];
        NSString *thumbUrl  = [jsonImage objectForKey:@"thumbUrl"];
        NSString *url       = [jsonImage objectForKey:@"url"];
        
        CALImage *img = [[CALImage alloc] initWithKey:key url:url thumbUrl:thumbUrl];
        return img;
    } else {
        return nil;
    }
}

- (UIImage *)getOnlineImage:(BOOL)isOnline {
    return isOnline ? onlineImage : offlineImage;
}

- (void)decorate:(UIImageView *)parentView decorator:(UIImage *)imgDecorator {
    if(parentView != nil && imgDecorator != nil) {
        CGSize decoFrame = imgDecorator.size;
        
        // Selecting any already existing decorator
        UIImageView *onlineDecorator = nil;
        for(UIView *subview in parentView.subviews) {
            if([subview isKindOfClass:[UIImageView class]]) {
                onlineDecorator = (UIImageView*)subview;
                break;
            }
        }
        // Initializing
        if(onlineDecorator == nil) {
            // Initializing the child image view with the decorating image
            UIImageView *onlineDecorator = [[UIImageView alloc] initWithImage:imgDecorator];
            // Adding to parent
            [parentView addSubview:onlineDecorator];
            // Positioning upper left
            onlineDecorator.frame = CGRectMake(0, 0, decoFrame.width, decoFrame.height);
        }
    }
}
-(void)prepareLoad:(Imaged*)imaged {
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    if(imaged.mainImage !=nil) {
        // Collecting all images to download
        NSMutableArray *images = [NSMutableArray arrayWithObject:imaged.mainImage];
        if(imaged.otherImages.count>0) {
            [images addObjectsFromArray:imaged.otherImages];
        }

        // Downloading everything
        for(CALImage *img in images) {
            [manager downloadImageWithURL:[NSURL URLWithString:img.thumbUrl] options:SDWebImageRetryFailed progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                if(image) {
                    img.thumbImage = image;
                }

            }];
             
        }
    }
}
-(void)load:(CALImage *)calImage to:(UIImageView *)imageView thumb:(BOOL)thumb {
    [self load:calImage to:imageView thumb:thumb callback:nil];
}
- (void)load:(CALImage *)calImage to:(UIImageView *)imageView thumb:(BOOL)thumb callback:(ImageLoaderBlock)callback {
    // Getting requested URL for thumb or main image
    NSString *url = thumb ? calImage.thumbUrl : calImage.imageUrl;
    
    // Setting appropriate default image
    UIImage *defaultImage;
    if(imageView.image == nil) {
        if(thumb) {
            defaultImage = [CALImage getDefaultThumb];
        } else {
            // Selecting ladnscape / portrait
            CGRect frame = imageView.frame;
            if(frame.size.width>frame.size.height) {
                defaultImage = [CALImage getDefaultThumbLandscape];
            } else {
                defaultImage = [CALImage getDefaultImage];
            }
        }
        if(calImage.thumbImage!=nil) {
            defaultImage = calImage.thumbImage;
        }
        
        // If no URL
        //    if(url == nil) {
        // Then setting default image and that's it
        imageView.image = defaultImage;
        //    } else {
    }

    if(calImage.fullImage && !thumb) {
        imageView.image = calImage.fullImage;
        if(callback) {
            callback(calImage);
        }
        [self checkCurrentImageViewTask:imageView url:url];
        return ;
    } else if(calImage.thumbImage) {
        imageView.image = calImage.thumbImage;
        if(thumb) {
            if(callback) {
                callback(calImage);
            }
            [self checkCurrentImageViewTask:imageView url:url];
            return ;
        }
    }
    
    if(url!=nil) {
        __block ImageLoaderBlock localCallback = callback;
        
        // If a task is already running for same URL we return,
        // Any pre-existing task for a different URL will be cancelled here
        if([self checkCurrentImageViewTask:imageView url:url]) {
            return;
        }

        // Async load
        __block NSString *imageViewId = [self buildKeyFromPointer:imageView];
        id<SDWebImageOperation> operation = [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:url] options:SDWebImageRetryFailed progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            // If everything is fine, we store thumb as we may need it for first preview
            if(image != nil) {
                if(thumb) {
                    calImage.thumbImage = image;
                } else {
                    calImage.fullImage = image;
                }
                imageView.image=image;
                if(imageView.alpha>0) {
                    imageView.alpha=0;
                    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                        imageView.alpha=1;
                    } completion:nil];
                }
                
            } else {
                if(error != nil) {
                    NSLog(@"ERROR Image download: %@",error.localizedDescription);
                }
            }
            // Notifying callback if specified
            if(localCallback != nil) {
                localCallback(calImage);
            }
            
            // Clearing operation
            [operationsMap removeObjectForKey:imageViewId];
            [urlMap removeObjectForKey:imageViewId];
        }];
                     
        [operationsMap setObject:operation forKey:imageViewId];
        [urlMap setObject:url forKey:imageViewId];
    }
}
/**
 * This method checks if any operation is already associated with this image view.
 * If there is one for the same URL, then it returns YES to indicate no further action
 * should be made. If one is found for a different URL it cancels it.
 */
-(BOOL)checkCurrentImageViewTask:(UIImageView*)imageView url:(NSString*)url{
    // Checking if any other operation is running for this image view
    __block NSString *imageViewId = [self buildKeyFromPointer:imageView];
    id<SDWebImageOperation> operation = [operationsMap objectForKey:imageViewId];
    if(operation != nil) {
        // If old operation is for same url then we have nothing to do (same image view + same url)
        NSString *oldUrl = [urlMap objectForKey:imageViewId];
        if([url isEqualToString:oldUrl]) {
            NSLog(@"Process already running for imageView %p",imageView);
            return YES;
        } else {
            NSLog(@"Cancelled task for imageView %p",imageView);
            [operation cancel];
        }
    }
    return NO;
}
- (CALImage *)imageOrPlaceholderFor:(CALObject *)object allowAdditions:(BOOL)additionsAllowed{
    if(object.mainImage!=nil) {
        return object.mainImage;
    } else {
        if([object isKindOfClass:[User class]]) {
            return [CALImage getDefaultUserCalImage];
        } else if([object isKindOfClass:[Event class]]) {
            return [CALImage calImageWithImageName:@"imgBlankEvent"];
        } else if([object isKindOfClass:[City class]]) {
            if(additionsAllowed) {
                return [CALImage defaultCityAddCalImage];
            } else {
                return [CALImage defaultCityCalImage];
            }
        } else {
            if(additionsAllowed) {
                return [CALImage defaultAddPhotoCalImage];
            } else {
                return [CALImage defaultNoPhotoCalImage];
            }
        }
    }
}
@end
