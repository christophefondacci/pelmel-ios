//
//  ModelHolder.h
//  nativeTest
//
//  Created by Christophe Fondacci on 25/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "CALObject.h"
#import "Special.h"
#import "City.h"
#import "PMLInfoProvider.h"

typedef enum {
    PLACES_LISTVIEW,
    EVENTS_LISTVIEW
} ListviewType;



@protocol MasterProvider

// The title of the table line
-(NSString*)getTitle:(CALObject*)obj;
// The label of the type of the table entry
-(NSString*)getTypeLabel:(CALObject*)obj;
// The distance label
-(NSString*)getDistanceLabel:(CALObject*)obj;
// Whether we show the number of men present
-(BOOL)isMenLabelVisible:(CALObject*)obj;
// Whether we show the number of likes
-(BOOL)isLikeLabelVisible:(CALObject*)obj;
// Provides the label for the men section
-(NSString*)getMenLabel:(CALObject*)obj;
// Provides the label for the like section
-(NSString*)getLikeLabel:(CALObject*)obj;
// Informs whether the specified object should be displayed or not
-(BOOL)isDisplayed:(CALObject*)obj;
// Provides the raw distance as a double
-(double)getRawDistance:(CALObject*)obj;

@optional
-(Special*)getSpecialFor:(CALObject*)obj;
-(Special*)getSpecialSubtitleFor:(CALObject*)obj currentBestSpecial:(Special*)currentBestSpecial;
-(NSString*)getSpecialIntroLabel:(Special*)special;
-(NSString*)getSpecialsMainLabel:(Special*)special;
-(UIColor*)getSpecialsColor:(Special*)special;
-(BOOL)hasSubtitle:(CALObject*)obj;
-(NSString*)getSpecialsSubtitleLabel:(Special*)obj;
@end

@interface ModelHolder : NSObject

@property (strong) NSArray *places;
@property (strong) NSArray *cities;
@property (strong) NSArray *events;
@property (strong) NSArray *activities;
@property (strong) NSArray *users;
@property (strong) NSMutableArray *allPlaces; // All places ever loaded
@property (strong) City *localizedCity;
@property (strong) CLLocation *userLocation;
@property (strong) CALObject *parentObject;
@property (strong) NSString *searchedText;
@property (strong) NSDate *dataTime;
@property (nonatomic) ListviewType currentListviewType;

-(void)updatePlaces:(NSArray *)places location:(CLLocation *)userLocation dataTime:(NSDate *)dataTime;
-(NSArray*)getCALObjects;
-(NSObject<MasterProvider>*)getMasterProvider;

@end
