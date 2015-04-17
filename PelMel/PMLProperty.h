//
//  PMLProperty.h
//  PelMel
//
//  Created by Christophe Fondacci on 16/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "CALObject.h"

@interface PMLProperty : CALObject

@property (nonatomic, strong) NSString *propertyCode;
@property (nonatomic, strong) NSString *propertyValue;
@property (nonatomic, strong) NSString *defaultLabel;

-(instancetype)initWithCode:(NSString*)code value:(NSString*)value defaultLabel:(NSString*)defaultLabel;
@end
