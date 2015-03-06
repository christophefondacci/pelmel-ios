//
//  UIImage+IPImageUtils.m
//  PelMel
//
//  Created by Christophe Fondacci on 04/03/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "UIImage+IPImageUtils.h"

@implementation UIImage (IPImageUtils)

+ (UIImage *)ipMaskedImageNamed:(NSString *)name color:(UIColor *)color
{
    UIImage *image = [UIImage imageNamed:name];
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, image.scale);
    CGContextRef c = UIGraphicsGetCurrentContext();
    [image drawInRect:rect];
    CGContextSetFillColorWithColor(c, [color CGColor]);
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    CGContextFillRect(c, rect);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    return result;
}

@end