//
//  CALayer+XibConfiguration.h
//  PelMel
//
//  Created by Christophe Fondacci on 30/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CALayer (XibConfiguration)

// This assigns a CGColor to borderColor.
@property(nonatomic, assign) UIColor* borderUIColor;

@end
