//
//  User.h
//  nativeTest
//
//  Created by Christophe Fondacci on 28/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALObject.h"
#import "Place.h"

@interface User : CALObject

@property (strong) NSString *pseudo;
@property (strong) NSDate *lastLocationDate;
@property (nonatomic,assign) NSInteger heightInCm;
@property (nonatomic,assign) NSInteger weightInKg;
@property (nonatomic,strong) NSDate *birthDate;
@property (nonatomic) BOOL isOnline;
@property (nonatomic) NSInteger likedPlacesCount;
@property (readonly) NSMutableArray *likedPlaces;
@property (nonatomic) NSInteger checkedInPlacesCount;
@property (readonly) NSMutableArray *checkedInPlaces;
@property (nonatomic,strong) Place *lastLocation;
@property (strong) NSString *cityName;

@property (strong) NSMutableArray *descriptions;
-(void) addDescription:(NSString*)description language:(NSString*)language;
-(void) addDescriptionWithKey:(NSString*)key description:(NSString*)description language:(NSString*)language;
@end
