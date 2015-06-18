//
//  PMLManagedActivity.h
//  PelMel
//
//  Created by Christophe Fondacci on 16/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PMLManagedActivity : NSManagedObject

@property (nonatomic, retain) NSDate * activityDate;
@property (nonatomic, retain) NSString * activityItemImageUrl;
@property (nonatomic, retain) NSString * activityItemKey;
@property (nonatomic, retain) NSString * activityItemName;
@property (nonatomic, retain) NSString * activityItemThumbUrl;
@property (nonatomic, retain) NSString * activityKey;
@property (nonatomic, retain) NSString * activityType;
@property (nonatomic, retain) NSString * defaultTranslation;
@property (nonatomic, retain) NSString * userImageUrl;
@property (nonatomic, retain) NSString * userItemKey;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSString * userThumbUrl;

@end
