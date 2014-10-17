//
//  Description.h
//  nativeTest
//
//  Created by Christophe Fondacci on 07/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Description : NSObject

@property (strong) NSString *key;
@property (strong) NSString *languageCode;
@property (strong) NSString *descriptionText;

-(id)initWithDescription:(NSString*)description language:(NSString*)language;
-(id)initWithKey:(NSString*)key description:(NSString*)description language:(NSString*)language;
@end
