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

- (void)configure {
    if(defaultThumb == nil) {
        defaultThumb = [UIImage imageNamed:@"imgBlankAddMini"];
    }
    if(defaultImage == nil) {
        defaultImage = [UIImage imageNamed:@"imgBlankAdd"];
    }
    if(defaultUserThumb == nil) {
        defaultUserThumb = [UIImage imageNamed:@"imgBlankUser"];
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
        _key = key;
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
- (BOOL)isDefaultImage {
    return _fullImage == defaultImage;
}
- (BOOL)isDefaultThumb {
    return _thumbImage == defaultThumb;
}
+ (UIImage *)getDefaultImage {
    if(defaultImage == nil) {
        defaultImage = [UIImage imageNamed:@"imgBlankAdd"];
    }
    return defaultImage;
}

+(UIImage *)getDefaultThumb{
    if(defaultThumb == nil) {
        defaultThumb = [UIImage imageNamed:@"imgBlankAddMini"];
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
+ (UIImage *)getDefaultThumbLandscape {
    if(defaultThumbLandscape ==nil) {
        defaultThumbLandscape = [UIImage imageNamed:@"no-photo-big-landscape.png"];
    }
    return defaultThumbLandscape;
}
- (UIImage *)getThumbImage {
    return _thumbImage;
}
@end
