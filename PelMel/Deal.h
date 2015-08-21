//
//  Deal.h
//  PelMel
//
//  Created by Christophe Fondacci on 12/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "CALObject.h"

@interface Deal : CALObject

@property (nonatomic,retain) CALObject *relatedObject;
@property (nonatomic,retain) NSString *dealType;
@property (nonatomic,retain) NSString *dealStatus;
@property (nonatomic,retain) NSDate *dealStartDate;
@property (nonatomic) NSInteger usedToday;

@end
