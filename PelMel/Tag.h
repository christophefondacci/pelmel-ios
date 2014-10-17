//
//  Tag.h
//  togayther
//
//  Created by Christophe Fondacci on 08/01/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tag : NSObject

@property (strong) NSString *code;
@property (strong) NSString *label;
@property (strong) UIImage *icon;

-(id)initWithCode:(NSString*)code label:(NSString*)label icon:(UIImage*)icon;

@end
