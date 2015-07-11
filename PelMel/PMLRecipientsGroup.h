//
//  PMLRecipientsGroup.h
//  PelMel
//
//  Created by Christophe Fondacci on 09/07/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "CALObject.h"

@interface PMLRecipientsGroup : CALObject

@property (nonatomic,retain) NSMutableArray *users;

-(instancetype)initWithUsers:(NSArray*)users;

@end
