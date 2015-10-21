//
//  CALImage.m
//  nativeTest
//
//  Created by Christophe Fondacci on 01/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "CALImage.h"

@implementation CALImage
    
static UIImage *defaultImage;
static UIImage *defaultThumb;
static UIImage *defaultUserThumb;
static UIImage *defaultThumbLandscape;
static CALImage *defaultNoPhotoCalImage;


- (void)configure {
    if(defaultThumb == nil) {
        defaultThumb = [UIImage imageNamed:@"imgBlankMini"];
    }
    if(defaultImage == nil) {
        defaultImage = [UIImage imageNamed:@"imgBlank"];
    }
    if(defaultUserThumb == nil) {
        defaultUserThumb = [UIImage imageNamed:@"imgBlankUserMini"];
    }
    if(defaultThumbLandscape == nil) {
        defaultThumbLandscape = [UIImage imageNamed:@"no-photo-big-landscape.png"];
    }
//    _thumbImage = defaultThumb;
//    _fullImage = defaultThumb;
}
- (id)init {
    if( self = [super init]) {
        [self configure];
    }
    return self;
}
- (id)initWithKey:(NSString*)key url:(NSString *)imageUrl thumbUrl:(NSString *)thumbUrl {
    if(self = [super init]) {
        [self configure];
        self.key = key;
        _imageUrl = imageUrl;
        _thumbUrl = thumbUrl;
    }
    return self;
}
+ (instancetype)calImageWithImage:(UIImage *)image
{
    CALImage *calImage= [[CALImage alloc] init];
    calImage.fullImage = image;
    calImage.thumbImage = image;
    return calImage;
}
+ (instancetype)calImageWithImageName:(NSString *)imageName {
    return [CALImage calImageWithImage:[UIImage imageNamed:imageName]];
}
- (BOOL)isDefaultImage {
    return _fullImage == defaultImage;
}
- (BOOL)isDefaultThumb {
    return _thumbImage == defaultThumb;
}
+ (UIImage *)getDefaultImage {
    if(defaultImage == nil) {
        defaultImage = [UIImage imageNamed:@"imgBlank"];
    }
    return defaultImage;
}

+(UIImage *)getDefaultThumb{
    if(defaultThumb == nil) {
        defaultThumb = [UIImage imageNamed:@"imgBlankMini"];
    }
    return defaultThumb;
}
+(UIImage *)getDefaultUserThumb {
    if(defaultUserThumb == nil) {
        defaultUserThumb = [UIImage imageNamed:@"imgBlankUserMini"];
    }
    return defaultUserThumb;
}
+(CALImage *)getDefaultUserCalImage {
    CALImage *img = [[CALImage alloc] init];
    img.thumbImage = [self getDefaultUserThumb];
    img.fullImage = [UIImage imageNamed:@"imgBlankUser"];
    return img;
}

+(CALImage *)defaultCityCalImage {
    CALImage *img = [[CALImage alloc] init];
    img.thumbImage = [UIImage imageNamed:@"imgBlankCityMini"];
    img.fullImage = [UIImage imageNamed:@"imgBlankCity"];
    return img;
}
+(CALImage *)defaultCityAddCalImage {
    CALImage *img = [[CALImage alloc] init];
    img.thumbImage = [UIImage imageNamed:@"imgBlankAddCityMini"];
    img.fullImage = [UIImage imageNamed:@"imgBlankAddCity"];
    return img;
}
+ (CALImage *)defaultAddPhotoCalImage {
    CALImage *img = [[CALImage alloc] init];
    img.thumbImage = [UIImage imageNamed:@"imgBlankAddMini"];
    img.fullImage = [UIImage imageNamed:@"imgBlankAdd"];
    return img;
}
+ (CALImage *)defaultNoPhotoCalImage {
    if(defaultNoPhotoCalImage == nil) {
        defaultNoPhotoCalImage = [[CALImage alloc] init];
        defaultNoPhotoCalImage.thumbImage = [UIImage imageNamed:@"imgBlankMini"];
        defaultNoPhotoCalImage.fullImage = [UIImage imageNamed:@"imgBlank"];
    }
    return defaultNoPhotoCalImage;
}
+ (UIImage *)getDefaultThumbLandscape {
    if(defaultThumbLandscape ==nil) {
        defaultThumbLandscape = [UIImage imageNamed:@"imgBlank"];
    }
    return defaultThumbLandscape;
}
- (UIImage *)getThumbImage {
    return _thumbImage;
}
@end
