//
//  PMLReportData.h
//  PelMel
//
//  Created by Christophe Fondacci on 15/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PMLReportData : NSObject

@property (nonatomic,retain) NSDate *date;
@property (nonatomic,retain) NSString *type;
@property (nonatomic,retain) NSNumber *count;

- (instancetype)initWithDate:(NSDate*)date type:(NSString*)type count:(NSNumber*)count;
@end
