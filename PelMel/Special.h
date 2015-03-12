//
//  Special.h
//  PelMel
//
//  Created by Christophe Fondacci on 10/02/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Special : NSObject

@property (strong,nonatomic) NSString *key;
@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) NSDate *nextStart;
@property (strong,nonatomic) NSDate *nextEnd;
@property (strong,nonatomic) NSString *type;
@property (strong,nonatomic) NSString *descriptionText;

@end
