//
//  Imaged.h
//  nativeTest
//
//  Created by Christophe Fondacci on 01/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALImage.h"

@interface Imaged : NSObject

@property (strong) CALImage *mainImage;
@property (strong) NSMutableArray *otherImages;

@end
