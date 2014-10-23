//
//  PMLCityInfoProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 28/09/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLCityInfoProvider.h"
#import "City.h"
#import "ItemsThumbPreviewProvider.h"


@implementation PMLCityInfoProvider {
    City *_city;
    ItemsThumbPreviewProvider *_thumbsProvider;
}

- (instancetype)initWithCity:(id)city
{
    self = [super init];
    if (self) {
        _city = city;
    }
    return self;
}

// The element being represented
-(CALObject*) item {
    return _city;
}
- (CALImage *)snippetImage {
    if(_city.mainImage!=nil) {
        return _city.mainImage;
    } else {
        return [CALImage calImageWithImage:[UIImage imageNamed:@"logoMob"]];
    }

}
// Title of the element
-(NSString*) title {
    return _city.name;
}
// Icon representing the type of item being displayed
-(UIImage*) titleIcon {
    return [UIImage imageNamed:@"snpIconCity"];
}
// Global theme color for element
-(UIColor*) color {
    return UIColorFromRGB(0xec7700);
}
// Provider of thumb displayed in the main snippet section
-(NSObject<ThumbsPreviewProvider>*) thumbsProvider {
   _thumbsProvider = [[ItemsThumbPreviewProvider alloc] initWithParent:_city items:_city.likers forType:PMLThumbsLike];
    return _thumbsProvider;
}
// Number of reviews
-(int)reviewsCount {
    return 0;
}
// Number of likes
-(int)likesCount {
    return (int)_city.likeCount;
}
// Number of checkins (if applicable)
-(int)checkinsCount {
    return 0;
}
// Description of elements
-(NSString*)descriptionText {
    return _city.miniDesc;
}
// Short text displayed with thumb
-(NSString*)thumbSubtitleText {
    return nil;
}
// Color of the short thumb subtitle text
-(UIColor*)thumbSubtitleColor {
    return [self color];
}
- (NSArray *)addressComponents {
    return @[];
}
- (NSArray *)activities {
    return nil;
}

-(NSObject<ThumbsPreviewProvider> *)likesThumbsProvider {
#pragma mark Implement me
    return nil;
}
- (NSObject<ThumbsPreviewProvider> *)checkinsThumbsProvider {
#pragma mark Implement me
    return nil;
}
@end
