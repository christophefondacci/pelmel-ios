//
//  CALayer+XibConfiguration.m
//  PelMel
//
//  Created by Christophe Fondacci on 30/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "CALayer+XibConfiguration.h"

@implementation CALayer (XibConfiguration)

-(void)setBorderUIColor:(UIColor*)color
{
    self.borderColor = color.CGColor;
}

-(UIColor*)borderUIColor
{
    return [UIColor colorWithCGColor:self.borderColor];
}


@end
