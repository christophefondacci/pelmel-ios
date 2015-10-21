//
//  Imaged.h
//  nativeTest
//
//  Created by Christophe Fondacci on 01/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CALImage;

@interface Imaged : NSObject

@property (strong) CALImage *mainImage;
@property (strong) NSMutableArray *otherImages;

- (CALImage*)imageAtIndex:(NSInteger) index;
@end
