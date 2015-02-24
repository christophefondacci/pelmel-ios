//
//  CALImage.h
//  nativeTest
//
//  Created by Christophe Fondacci on 01/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CALImage : NSObject

@property (strong) NSString *key;
@property (strong) NSString *thumbUrl;
@property (strong) NSString *imageUrl;

//@property (strong, getter = getThumbImage, setter = setThumbImage:) UIImage *thumbImage;
@property (strong) UIImage *fullImage;
@property (strong,nonatomic) UIImage *thumbImage;

- (id)initWithKey:(NSString*)key url:(NSString*)imageUrl thumbUrl:(NSString*)thumbUrl;
// This constructor wraps a UIImage in a CALImage as an adapter
+ (instancetype)calImageWithImage:(UIImage*)image;
+ (instancetype)calImageWithImageName:(NSString *)imageName;
- (BOOL)isDefaultImage;
- (BOOL)isDefaultThumb;
+ (UIImage *)getDefaultImage;
+ (UIImage *)getDefaultThumb;
+ (UIImage *)getDefaultThumbLandscape;
+ (UIImage *)getDefaultUserThumb;
+ (CALImage*)getDefaultUserCalImage;
+ (CALImage *)defaultCityCalImage;
+ (CALImage *)defaultCityAddCalImage;
+ (CALImage *)defaultAddPhotoCalImage;
+ (CALImage *)defaultNoPhotoCalImage;
- (UIImage *)getThumbImage;
@end
