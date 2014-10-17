//
//  PlaceType.h
//  nativeTest
//
//  Created by Christophe Fondacci on 26/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlaceType : NSObject

@property (strong) NSString *code;
@property (strong) NSString *label;
@property (strong) NSString *sponsoredLabel;
@property (nonatomic) BOOL visible;
@property (strong) UIImage *icon;
@property (strong) UIImage *filterIcon;

-(PlaceType*)initWithCode:(NSString*)code;

@end
