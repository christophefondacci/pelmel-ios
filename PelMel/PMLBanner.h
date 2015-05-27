//
//  PMLBanner.h
//  PelMel
//
//  Created by Christophe Fondacci on 12/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "CALObject.h"

@interface PMLBanner : CALObject

@property (nonatomic,retain)    NSNumber   *radius;
@property (nonatomic,retain)    CALObject  *targetObject;
@property (nonatomic,retain)    NSString   *targetUrl;
@property (nonatomic)           NSInteger  targetDisplayCount;
@property (nonatomic)           NSInteger  displayCount;
@property (nonatomic)           NSInteger  clickCount;
@property (nonatomic,retain)    NSString   *storeProductId;
@property (nonatomic,retain)    NSDate     *startDate;
@property (nonatomic,retain)    NSString   *status;
@end
