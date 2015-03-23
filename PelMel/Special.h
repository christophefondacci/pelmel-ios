//
//  Special.h
//  PelMel
//
//  Created by Christophe Fondacci on 10/02/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALImage.h"

@interface Special : NSObject

@property (strong,nonatomic) NSString *key;
@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) NSDate *startDate;
@property (strong,nonatomic) NSDate *endDate;
@property (strong,nonatomic) NSString *calendarType;
@property (strong,nonatomic) NSString *miniDesc;
@property (strong,nonatomic) CALImage *mainImage;
@end
