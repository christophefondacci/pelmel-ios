//
//  JsonService.m
//  togayther
//
//  Created by Christophe Fondacci on 13/02/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import "JsonService.h"
#import "TogaytherService.h"
#import "Event.h"
#import "Description.h"
#import "NSString+HTML.h"

@implementation JsonService {

    MessageService *_messageService;
    UserService *_userService;
}

@synthesize imageService = imageService;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _objectCache = [[NSCache alloc] init];
        _messageService = [TogaytherService getMessageService];
        _userService = TogaytherService.userService;
    }
    return self;
}
-(Place*)convertJsonPlaceToPlace:(NSDictionary*)jsonPlace {
    
    NSString *name = [jsonPlace objectForKey:@"name"];
    NSString *key = [jsonPlace objectForKey:@"key"];
    NSString *timezoneId = [jsonPlace objectForKey:@"timezoneId"];
    NSDictionary *thumb = [jsonPlace objectForKey:@"thumb"];
    
    // Looking up in cache
    if(key != nil) {
        Place *place = [_objectCache objectForKey:key];
        if(place == nil) {
            place = [[Place alloc] init:name];
            [_objectCache setObject:place forKey:key];
        }
        [place setTitle:name];
        [place setKey:key];
        [place setTimezoneId:timezoneId];
        CALImage *img = [imageService convertJsonImageToImage:thumb];
        if(img != nil) {
            [place setMainImage:img];
        }
        
        return place;
    } else {
        return nil;
    }
}
-(PMLDeal*)convertJsonDealToDeal:(NSDictionary*)jsonDeal forPlace:(Place*)place {
    NSString *key               = [jsonDeal objectForKey:@"key"];
    NSString *relatedItemKey    = [jsonDeal objectForKey:@"relatedItemKey"];
    NSString *status            = [jsonDeal objectForKey:@"status"];
    NSString *type              = [jsonDeal objectForKey:@"type"];
    NSNumber *startTime         = [jsonDeal objectForKey:@"startDate"];
    NSNumber *lastUsedTime      = [jsonDeal objectForKey:@"lastUsedTime"];
    NSNumber *usedToday         = [jsonDeal objectForKey:@"usedToday"];
    NSNumber *maxPerDay         = [jsonDeal objectForKey:@"maxUses"];
    
    PMLDeal *deal = [_objectCache objectForKey:key];
    if(deal == nil) {
        deal = [[PMLDeal alloc ] init];
        [_objectCache setObject:deal forKey:key];
    }
    
    // Filling deal
    deal.key = key;
    deal.relatedObject = place;
    deal.dealStartDate = [[NSDate alloc] initWithTimeIntervalSince1970:startTime.longValue];
    if(lastUsedTime != nil && (id)lastUsedTime != [NSNull null]) {
        deal.lastUsedDate = [[NSDate alloc] initWithTimeIntervalSince1970:lastUsedTime.longValue];
    }
    deal.dealType = type;
    deal.dealStatus = status;
    deal.usedToday = usedToday.integerValue;
    deal.maxUses = maxPerDay.intValue;
    return deal;
}
-(void)fillPlace:(Place*)place fromJsonPlace:(NSDictionary*)json {
    
    // Owner management
    NSString *ownerKey          = [json objectForKey:@"ownerKey"];
    if([ownerKey length]>0) {
        place.ownerKey = ownerKey;
    } else {
        place.ownerKey = nil;
    }
    
    // Deal management
    NSArray *jsonDeals          = [json objectForKey:@"deals"];
    NSMutableArray *deals       = [NSMutableArray new];
    for(NSDictionary *jsonDeal in jsonDeals) {
        
        // Building Deal bean
        PMLDeal *deal = [self convertJsonDealToDeal:jsonDeal forPlace:place];
        
        // Augmenting deal array
        [deals addObject:deal];
    }
    // Injecting deals
    place.deals = deals;
}
-(Place*)convertFullJsonPlaceToPlace:(NSDictionary*)obj {
    // Extracting information from JSON
    NSString *itemKey       = [obj objectForKey:@"itemKey"];
    NSString *name          = [obj objectForKey:@"name"];
    NSString *distance      = [obj objectForKey:@"distance"];
    NSNumber *rawDistance   = [obj objectForKey:@"rawDistance"];
    NSString *description   = [obj objectForKey:@"description"];
    NSDictionary *thumb     = [obj objectForKey:@"thumb"];
    NSString *placeType     = [obj objectForKey:@"type"];
    NSString *cityName      = [obj objectForKey:@"city"];
    NSNumber *inUser        = [obj objectForKey:@"usersCount"];
    NSNumber *likeUser      = [obj objectForKey:@"likesCount"];
    NSNumber *adBoost       = [obj objectForKey:@"boostValue"];
    NSNumber *closedCount   = [obj objectForKey:@"closedReportsCount"];
    NSArray *otherImages    = [obj objectForKey:@"otherImages"];
    NSString *timezoneId    = [obj objectForKey:@"timezoneId"];
    NSArray *specials       = [obj objectForKey:@"specials"];

    
    // Building image array
    NSMutableArray *imagesArray = [[NSMutableArray alloc] initWithCapacity:[otherImages count]];
    for(NSDictionary *jsonOtherImage in otherImages) {
        CALImage *img = [imageService convertJsonImageToImage:jsonOtherImage];
        [imagesArray addObject:img];
    }
    
    
    // Parsing lat / lng
    NSDecimalNumber *numLat = [obj objectForKey:@"lat"];
    NSDecimalNumber *numLng = [obj objectForKey:@"lng"];
    double placeLat = [numLat doubleValue];
    double placeLng = [numLng doubleValue];
    
    NSArray *jsonTags = [obj objectForKey:@"tags"];
    NSMutableArray *tags = [[NSMutableArray alloc] initWithArray:jsonTags];
    // Building main image bean
    CALImage *mainImage = [imageService convertJsonImageToImage:thumb];
    
    // Building the place data bean
    Place *data =[_objectCache objectForKey:itemKey];
    if(data == nil) {
        data = [[Place alloc] initFull:name distance:distance miniDesc:description];
        // Caching result
        [_objectCache setObject:data forKey:itemKey];
    }
    [self fillPlace:data fromJsonPlace:obj];
    [data setRawDistance:[rawDistance doubleValue]];
    [data setOtherImages:imagesArray];
    [data setMainImage:mainImage];
    data.tags = tags;
    
    [data setLat:placeLat];
    [data setLng:placeLng];
    [data setPlaceType:placeType];
    [data setCityName:cityName];
    [data setKey:itemKey];
    [data setInUserCount:[inUser integerValue]];
    [data setLikeCount:[likeUser integerValue]];
    [data setAdBoost:[adBoost integerValue]];
    [data setClosedReportsCount:[closedCount intValue]];
    [data setTimezoneId:timezoneId];
    
    // Hashing current place hours by key
    NSMutableDictionary *placeHoursKeys = [[NSMutableDictionary alloc] init];
    for(PMLCalendar *calendar in data.hours) {
        [placeHoursKeys setObject:calendar forKey:calendar.key];
    }
    // Parsing specials
    for(NSDictionary *jsonSpecial in specials) {
        PMLCalendar *special = [self convertJsonLightCalendarToCalendar:jsonSpecial forPlace:data defaultCalendar:nil];
        
        // Adding to our list
        PMLCalendar *placeCalendar = [placeHoursKeys objectForKey:special.key];
        if(placeCalendar != nil) {
            [data.hours removeObject:placeCalendar];
        }
        [data.hours addObject:special];
    }
    // Injecting into current place
//    data.specials = placeSpecials;
    
    return data;
}
-(City*)convertJsonCityToCity:(NSDictionary*)jsonCity {
    NSString *key = [jsonCity objectForKey:@"key"];
    NSString *name = [jsonCity objectForKey:@"name"];
    NSString *loc = [jsonCity objectForKey:@"localization"];
    NSDecimalNumber *numLat = [jsonCity objectForKey:@"latitude"];
    NSDecimalNumber *numLng = [jsonCity objectForKey:@"longitude"];
    NSDictionary *jsonMedia = [jsonCity objectForKey:@"media"];
    double cityLat = [numLat doubleValue];
    double cityLng = [numLng doubleValue];
    NSNumber *placesCount = [jsonCity objectForKey:@"placesCount"];
    
    City *city = [[City alloc] init];
    [city setKey:key];
    [city setName:name];
    [city setLocalization:loc];
    [city setLat:cityLat];
    [city setLng:cityLng];
    [city setPlacesCount:[placesCount intValue]];
    if(jsonMedia != (id)[NSNull null] && jsonMedia.count>0) {
        CALImage *image = [imageService convertJsonImageToImage:jsonMedia];
        [city setMainImage:image];
    }
    return city;
}

- (Place *)convertJsonOverviewPlaceToPlace:(NSDictionary *)json defaultPlace:(Place*)defaultPlace{
    

    // Extracting data from JSON structure
    NSString *placeKey      = [json objectForKey:@"key"];
    NSString *name          = [json objectForKey:@"name"];
    NSString *cityName      = [json objectForKey:@"city"];
    NSString *address       = [json objectForKey:@"address"];
    NSNumber *likeCount     = [json objectForKey:@"likes"];
    NSNumber *inCount       = [json objectForKey:@"users"];
    NSNumber *reviewsCount  = [json objectForKey:@"commentsCount"];
    NSNumber *closedCount   = [json objectForKey:@"closedReportsCount"];
    NSString *description   = [json objectForKey:@"description"];
    NSString *descriptionKey= [json objectForKey:@"descriptionKey"];
    NSString *descriptionLng= [json objectForKey:@"descriptionLanguage"];
    NSString *placeType     = [json objectForKey:@"type"];
    NSDictionary *thumb     = [json objectForKey:@"thumb"];
    NSArray *otherImages    = [json objectForKey:@"otherImages"];
    
    NSArray *jsonInUsers    = [json objectForKey:@"inUsers"];
    NSArray *jsonLikeUsers  = [json objectForKey:@"likeUsers"];
    NSNumber *jsonLiked     = [json objectForKey:@"liked"];
    NSArray *jsonEvents     = [json objectForKey:@"events"];
    NSArray *jsonHours      = [json objectForKey:@"hours"];
    NSString *timezoneId    = [json objectForKey:@"timezoneId"];
    NSArray *jsonProperties = [json objectForKey:@"properties"];
    
    // Getting unread message count
    NSNumber *unreadMsgCount= [json objectForKey:@"unreadMsgCount"];
//    NSNumber *unreadNetworkCount=[json objectForKey:@"unreadNetworkNotificationsCount"];    
    NSNumber *maxActivityId = [json objectForKey:@"maxActivityId"];
    [_messageService setUnreadMessageCount:[unreadMsgCount intValue]];
//    [_messageService setUnreadNetworkCount:unreadNetworkCount.intValue];
    [_messageService setMaxActivityId:[maxActivityId intValue]];
    
    // Getting place
    Place *place = [_objectCache objectForKey:placeKey];
    if(place == nil) {
        if(defaultPlace != nil) {
            place = defaultPlace;
        } else {
            place = [[Place alloc] init];
        }
    } else if(place != defaultPlace && defaultPlace != nil) {
        NSLog(@"WARNING: Original place object has been replaced: %@ (cache may have been purged)",place.key );
        place = defaultPlace;
    }
    [self fillPlace:place fromJsonPlace:json];
    // Parsing lat / lng
    NSDecimalNumber *numLat = [json objectForKey:@"lat"];
    NSDecimalNumber *numLng = [json objectForKey:@"lng"];
    if(numLat!= nil && numLng!=nil) {
        double placeLat = [numLat doubleValue];
        double placeLng = [numLng doubleValue];
        [place setLat:placeLat];
        [place setLng:placeLng];
    }
    
    // Injecting data into our place bean
    [place setKey:placeKey];
    if(![name isEqualToString:place.title]) {
        [place setTitle:name];
    }
    [place setAddress:address];
    [place setCityName:cityName];
    [place setLikeCount:[likeCount integerValue]];
    [place setInUserCount:[inCount integerValue]];
    [place setMiniDesc:description];
    [place setMiniDescKey:descriptionKey];
    [place setMiniDescLang:descriptionLng];
    [place setPlaceType:placeType];
    [place setReviewsCount:[reviewsCount integerValue]];
    [place setClosedReportsCount:(int)[closedCount integerValue]];
    [place setTimezoneId:timezoneId];
    
    // Building main image bean
    if(thumb != nil) {
        CALImage *mainImage = [imageService convertJsonImageToImage:thumb];
        [place setMainImage:mainImage];
    }
    // Building image array
    if(otherImages != nil) {
        NSMutableArray *imagesArray = [[NSMutableArray alloc] initWithCapacity:[otherImages count]];
        for(NSDictionary *jsonOtherImage in otherImages) {
            CALImage *img = [imageService convertJsonImageToImage:jsonOtherImage];
            [imagesArray addObject:img];
        }
        [place setOtherImages:imagesArray];
    }
    
    // Augmenting our collections of users
    [place.inUsers removeAllObjects];
    for(NSDictionary *jsonUser in jsonInUsers) {
        // Building user bean from JSON
        User *user= [self convertJsonUserToUser:jsonUser];

        // Adding to the list of users in the place
        [place.inUsers addObject:user];
    }

    [place.likers removeAllObjects];
    for(NSDictionary *jsonUser in jsonLikeUsers) {
        // Building user bean from JSON
        User *user= [self convertJsonUserToUser:jsonUser];

        // Adding to likers list
        [place addLiker:user];
    }
    
    // Like flag
    place.isLiked = [jsonLiked boolValue];
    
    NSMutableArray *events = [[NSMutableArray alloc] init];
    
    // Processing upcoming events
    for(NSDictionary *jsonEvent in jsonEvents) {
        Event *event = [self convertJsonEventToEvent:jsonEvent defaultEvent:nil];
        
        // Adding event to place
        [events addObject:event];
    }

    place.events = events;
    
    // Processing hours
    NSMutableArray *hours = [[NSMutableArray alloc] init];
    for(NSDictionary *jsonHour in jsonHours) {
        PMLCalendar *calendar = [self convertJsonCalendarToCalendar:jsonHour forPlace:place defaultCalendar:nil];
        [hours addObject:calendar];
    }
    [place setHours:hours];
    
    // Processing properties
    NSMutableArray *properties = [[NSMutableArray alloc] init];
    for(NSDictionary *jsonProperty in jsonProperties) {
        PMLProperty *prop = [self convertJsonPropertyToProperty:jsonProperty];
        [properties addObject:prop];
    }
    place.properties = properties;
    
    // Registering that this object has data
    [place setHasOverviewData:YES];
    
    // Refreshing cache
    [_objectCache setObject:place forKey:place.key];
    return place;
}
-(PMLProperty*)convertJsonPropertyToProperty:(NSDictionary*)jsonProperty {
    NSString *key      = [jsonProperty objectForKey:@"key"];
    NSString *code      = [jsonProperty objectForKey:@"code"];
    NSString *value      = [jsonProperty objectForKey:@"value"];
    NSString *label      = [jsonProperty objectForKey:@"label"];
    
    PMLProperty *prop = [_objectCache objectForKey:key];
    if(prop == nil) {
        prop = [[PMLProperty alloc] init];
        prop.key = key;
        [_objectCache setObject:prop forKey:key];
    }
    
    prop.propertyCode = code;
    prop.propertyValue = value;
    prop.defaultLabel = label;
    return prop;
}
-(PMLCalendar*)convertJsonLightCalendarToCalendar:(NSDictionary *)jsonSpecial forPlace:(Place*)place defaultCalendar:(PMLCalendar *)defaultCalendar {
    // Extracting from JSON
    NSString *key       = [jsonSpecial objectForKey:@"key"];
    NSString *name      = [jsonSpecial objectForKey:@"name"];
    NSString *desc      = [jsonSpecial objectForKey:@"description"];
    NSNumber *nextStart = [jsonSpecial objectForKey:@"nextStart"];
    NSNumber *nextEnd   = [jsonSpecial objectForKey:@"nextEnd"];
    NSNumber *participants=[jsonSpecial objectForKey:@"participants"];
    NSString *type      = [jsonSpecial objectForKey:@"type"];
    NSDictionary  *thumb= [jsonSpecial objectForKey:@"thumb"];
    
    NSDate *startDate   = [[NSDate alloc] initWithTimeIntervalSince1970:[nextStart longValue]];
    NSDate *endDate     = [[NSDate alloc] initWithTimeIntervalSince1970:[nextEnd longValue]];
    
    // Creating and filling bean
    PMLCalendar *calendar = [_objectCache objectForKey:key];
    if(calendar == nil) {
        if(defaultCalendar == nil) {
            calendar = [[PMLCalendar alloc] initWithPlace:place];
        } else {
            calendar = defaultCalendar;
            calendar.place = place;
        }
        calendar.key= key;
        [_objectCache setObject:calendar forKey:key];
    }
    
    calendar.name        = name;
    calendar.miniDesc = desc;
    calendar.startDate   = startDate;
    calendar.endDate     = endDate;
    calendar.calendarType        = type;
    calendar.likeCount = [participants intValue];
    // Filling media
    CALImage *calThumb = [imageService convertJsonImageToImage:thumb];
    if(calThumb != nil) {
        calendar.mainImage = calThumb;
    }
    
    return calendar;
}
-(PMLCalendar*)convertJsonCalendarToCalendar:(NSDictionary*)jsonHour forPlace:(Place*)place defaultCalendar:(PMLCalendar*)defaultCalendar {
    
    NSNumber *startHour     = [jsonHour objectForKey:@"startHour"];
    NSNumber *startMinute   = [jsonHour objectForKey:@"startMinute"];
    NSNumber *endHour       = [jsonHour objectForKey:@"endHour"];
    NSNumber *endMinute     = [jsonHour objectForKey:@"endMinute"];
    
    NSNumber *isMonday      = [jsonHour objectForKey:@"monday"];
    NSNumber *isTuesday     = [jsonHour objectForKey:@"tuesday"];
    NSNumber *isWednesday   = [jsonHour objectForKey:@"wednesday"];
    NSNumber *isThursday    = [jsonHour objectForKey:@"thursday"];
    NSNumber *isFriday      = [jsonHour objectForKey:@"friday"];
    NSNumber *isSaturday    = [jsonHour objectForKey:@"saturday"];
    NSNumber *isSunday      = [jsonHour objectForKey:@"sunday"];
    
    NSNumber *recurrency    = [jsonHour objectForKey:@"recurrency"];
    NSString *description   = [jsonHour objectForKey:@"description"];
    NSString *descriptionKey= [jsonHour objectForKey:@"descriptionKey"];
    NSString *descriptionLng= [jsonHour objectForKey:@"descriptionLanguage"];
    
    PMLCalendar *calendar = [self convertJsonLightCalendarToCalendar:jsonHour forPlace:place defaultCalendar:defaultCalendar];

    [calendar setStartHour:[startHour integerValue]];
    [calendar setStartMinute:[startMinute integerValue]];
    [calendar setEndHour:[endHour integerValue]];
    [calendar setEndMinute:[endMinute integerValue]];
    
    [calendar setIsMonday:[isMonday boolValue]];
    [calendar setIsTuesday:[isTuesday boolValue]];
    [calendar setIsWednesday:[isWednesday boolValue]];
    [calendar setIsThursday:[isThursday boolValue]];
    [calendar setIsFriday:[isFriday boolValue]];
    [calendar setIsSaturday:[isSaturday boolValue]];
    [calendar setIsSunday:[isSunday boolValue]];
    [calendar setMiniDesc:description];
    [calendar setMiniDescKey:descriptionKey];
    [calendar setMiniDescLang:descriptionLng];
    
    if(recurrency != (NSNumber*)[NSNull null]){
        [calendar setRecurrency:recurrency];
    } else {
        [calendar setRecurrency:nil];
    }
    return calendar;
}
-(PMLBanner*)convertJsonBannerToBanner:(NSDictionary*)jsonBanner {
    NSString *key                   = [jsonBanner objectForKey:@"key"];
    NSNumber *displayCount          = [jsonBanner objectForKey:@"displayCount"];
    NSNumber *clickCount            = [jsonBanner objectForKey:@"clickCount"];
    NSNumber *targetDisplayCount    = [jsonBanner objectForKey:@"targetDisplayCount"];
    NSNumber *lat                   = [jsonBanner objectForKey:@"lat"];
    NSNumber *lng                   = [jsonBanner objectForKey:@"lng"];
    NSNumber *radius                = [jsonBanner objectForKey:@"radius"];
    NSDictionary *targetPlace       = [jsonBanner objectForKey:@"targetPlace"];
    NSDictionary *targetEvent       = [jsonBanner objectForKey:@"targetEvent"];
    NSString *targetUrl             = [jsonBanner objectForKey:@"targetUrl"];
    NSDictionary *jsonMedia         = [jsonBanner objectForKey:@"bannerImage"];
    NSNumber *startDate             = [jsonBanner objectForKey:@"startDate"];
    NSString *status                = [jsonBanner objectForKey:@"status"];

    PMLBanner *banner = [_objectCache objectForKey:key];
    if(banner == nil) {
        banner = [[PMLBanner alloc] init];
        [_objectCache setObject:banner forKey:key];
    }
    banner.key = key;
    banner.displayCount = displayCount.intValue;
    banner.clickCount = clickCount.intValue;
    banner.targetDisplayCount = targetDisplayCount.intValue;
    banner.lat = lat.doubleValue;
    banner.lng = lng.doubleValue;
    banner.radius = radius;
    banner.startDate = [NSDate dateWithTimeIntervalSince1970:[startDate longValue]];
    banner.status = status;
    
    if(targetPlace != nil && (id)targetPlace!=[NSNull null]) {
        Place *p = [self convertJsonPlaceToPlace:targetPlace];
        [banner setTargetObject:p];
    }
    if(targetEvent != nil && (id)targetEvent!=[NSNull null]) {
        Event *e = [self convertJsonLightEventToEvent:targetEvent defaultEvent:nil];
        [banner setTargetObject:e];
    }
    banner.targetUrl = targetUrl;
    if(jsonMedia != nil && (id)jsonMedia!=[NSNull null]) {
        CALImage *image = [imageService convertJsonImageToImage:jsonMedia];
        banner.mainImage = image;
    }
    return banner;
}
- (NSArray *)convertJsonBannersToBanners:(NSArray *)jsonBanners {
    // Preparing resulting structure
    NSMutableArray *banners = [[NSMutableArray alloc] init];
    
    // Iterating over every json structure
    for(NSDictionary *jsonBanner in jsonBanners) {
        
        // Converting each json to a PMLBanner bean
        PMLBanner *banner = [self convertJsonBannerToBanner:jsonBanner];
        
        // Filling the result array
        [banners addObject:banner];
    }
    return banners;
}
-(Activity *)convertJsonActivityToActivity:(NSDictionary *)jsonActivity {
    NSString *jsonKey               = [jsonActivity objectForKey:@"key"];
    NSDictionary *jsonUser          = [jsonActivity objectForKey:@"user"];
    NSDictionary *jsonActivityPlace = [jsonActivity objectForKey:@"activityPlace"];
    NSDictionary *jsonActivityUser  = [jsonActivity objectForKey:@"activityUser"];
    NSDictionary *jsonActivityEvent = [jsonActivity objectForKey:@"activityEvent"];
    NSNumber     *jsonDate          = [jsonActivity objectForKey:@"activityDate"];
    NSString *message               = [jsonActivity objectForKey:@"message"];
    NSString *activityType          = [jsonActivity objectForKey:@"activityType"];
    NSNumber *activityCount         = [jsonActivity objectForKey:@"count"];
    NSDictionary *extraEvent        = [jsonActivity objectForKey:@"extraEvent"];
    NSDictionary *extraMedia        = [jsonActivity objectForKey:@"extraMedia"];
    
    // Unwrapping JSON
    User *user;
    CALObject *activityObject;
    if(jsonUser != (id)[NSNull null]) {
        user = [self convertJsonUserToUser:jsonUser];
    }
    if( jsonActivityPlace != (id)[NSNull null]) {
        activityObject = [self convertJsonPlaceToPlace:jsonActivityPlace];
    } else if( jsonActivityUser != (id)[NSNull null]) {
        activityObject = [self convertJsonUserToUser:jsonActivityUser];
    } else if(jsonActivityEvent != (id)[NSNull null] && jsonActivityEvent!=nil) {
        activityObject = [self convertJsonEventToEvent:jsonActivityEvent defaultEvent:nil];
    }
    NSDate *activityDate;
    if(jsonDate != (id)[NSNull null] && jsonDate.longValue!=0) {
        activityDate = [NSDate dateWithTimeIntervalSince1970:jsonDate.longValue];
    }
    
    // Building activity bean
    Activity *activity = [[Activity alloc] init];
    activity.key = jsonKey;
    activity.user = user;
    activity.activityObject = activityObject;
    activity.message = [message gtm_stringByUnescapingFromHTML];
    activity.activityDate = activityDate;
    activity.activityType = activityType;
    activity.activitiesCount = activityCount;
    
    // Extra event
    if(extraEvent != nil && (id)extraEvent!=[NSNull null]) {
        Event *e = [self convertJsonEventToEvent:extraEvent defaultEvent:nil];
        activity.extraEvent = e;
    }
    // Extra media
    if(extraMedia != nil && (id)extraMedia!=[NSNull null]) {
        CALImage *image = [imageService convertJsonImageToImage:extraMedia];
        activity.extraImage = image;
    }
    return activity;
}
- (NSArray *)convertJsonActivitiesToActivities:(NSArray *)jsonActivities {
    NSMutableArray *activities = [[NSMutableArray alloc] initWithCapacity:jsonActivities.count];
    for(NSDictionary *jsonActivity in jsonActivities) {
        Activity *activity = [self convertJsonActivityToActivity:jsonActivity];
        [activities addObject:activity];
    }
    return activities;
}
-(NSArray*)convertJsonEventsToEvents:(NSArray*)jsonEvents {
    NSMutableArray *events = [[NSMutableArray alloc] initWithCapacity:[jsonEvents count]];

    // Iterating over every event
    for(NSDictionary *jsonEvent in jsonEvents) {
        Event *event = [self convertJsonEventToEvent:jsonEvent defaultEvent:nil];
        
        // Appending to the document list
        [events addObject:event];
    }
    return events;
}
-(Event*)convertJsonLightEventToEvent:(NSDictionary*)obj defaultEvent:(Event*)defaultEvent {
    NSString *itemKey = [obj objectForKey:@"key"];
    
    // Because we convert series (SERI) into events, the cache may return a PMLCalendar object
    NSString *cacheKey = itemKey;
    if(![cacheKey hasPrefix:@"EVNT"]) {
        cacheKey = [@"EVNT" stringByAppendingString:itemKey];
    }
    // Building JSON event
    Event *event = [_objectCache objectForKey:cacheKey];
    if(event == nil) {
        if([itemKey hasPrefix:@"EVNT"]) {
            event = defaultEvent == nil ? [[Event alloc] init] : defaultEvent;
        } else {
            event = defaultEvent == nil ? [[PMLCalendar alloc] init] : defaultEvent;
            NSString *calendarType = [obj objectForKey:@"calendarType"];
            ((PMLCalendar*)event).calendarType = calendarType;
        }
        [_objectCache setObject:event forKey:cacheKey];
    }

    // Extracting information from JSON
    NSString *name          = [obj objectForKey:@"name"];
    NSString *distance      = [obj objectForKey:@"distance"];
    NSNumber *rawDistance   = [obj objectForKey:@"rawDistance"];
    NSArray *media          = [obj objectForKey:@"media"];
    NSNumber *startTime     = [obj objectForKey:@"startTime"];
    NSNumber *endTime       = [obj objectForKey:@"endTime"];
    NSDictionary *place     = [obj objectForKey:@"place"];
    NSNumber *participants  = [obj objectForKey:@"participants"];
    [event setKey:itemKey];
    [event setName:name];
    [event setDistance:distance];
    [event setRawDistance:[rawDistance doubleValue]];
    NSDate *startDate = [[NSDate alloc] initWithTimeIntervalSince1970:[startTime longValue]];
    NSDate *endDate = [[NSDate alloc] initWithTimeIntervalSince1970:[endTime longValue]];
    [event setStartDate:startDate];
    [event setEndDate:endDate];
    [event setLikeCount:[participants intValue]];
    if(place != nil && place!=(id)[NSNull null]) {
        Place *p = [self convertJsonPlaceToPlace:place];
        if([[p.key substringToIndex:4] isEqualToString:@"CITY"]) {
            p.key = nil;
        }
        [event setPlace:p];
    }
    NSNumber *likeCount     = [obj objectForKey:@"likes"];
    [event setLikeCount:MAX([likeCount integerValue],[participants integerValue])];
    
    // Setting the main image here
    for(NSDictionary *jsonOtherImage in media) {
        CALImage *image = [imageService convertJsonImageToImage:jsonOtherImage];
        [event setMainImage:image];
        break;
    }
    
    return event;
}
-(Event*)convertJsonEventToEvent:(NSDictionary*)obj defaultEvent:(Event*)defaultEvent {

    // Building JSON event
    Event *event = [self convertJsonLightEventToEvent:obj defaultEvent:defaultEvent];

    // Extracting information from JSON
    NSArray *media          = [obj objectForKey:@"media"];
    NSNumber *reviewsCount  = [obj objectForKey:@"commentsCount"];
    
    // Building image array
    BOOL isFirst = YES;
    NSMutableArray *otherImages = [[NSMutableArray alloc] init];
    for(NSDictionary *jsonOtherImage in media) {
        CALImage *image = [imageService convertJsonImageToImage:jsonOtherImage];
        if(isFirst) {
            [event setMainImage:image];
        } else {
            [otherImages addObject:image];
        }
        isFirst = NO;
    }
    if(otherImages.count>0) {
        event.otherImages = otherImages;
    }
    
    // Building the place data bean
    [event setReviewsCount:[reviewsCount intValue]];
    
    NSString *description = [obj objectForKey:@"description"];
    [event setMiniDesc:description];
    
    // Likes management
    NSArray *jsonLikeUsers  = [obj objectForKey:@"likeUsers"];
    NSNumber *liked         = [obj objectForKey:@"liked"];
    [event setIsLiked:[liked boolValue]];
    [event.likers removeAllObjects];
    for(NSDictionary *jsonUser in jsonLikeUsers) {
        // Building User bean (liked user) from JSON
        User *likedUser = [self convertJsonUserToUser:jsonUser];
        
        // Adding this liked user
        [event.likers addObject:likedUser];
    }

    return event;
}
#pragma mark - User JSON
- (User*)convertJsonUserToUser:(NSDictionary*)jsonUser {
    // Extracting JSON info
    NSString *userKey   = [jsonUser objectForKey:@"key"];
    NSString *pseudo    = [jsonUser objectForKey:@"pseudo"];
    NSDictionary *jsonThumb  = [jsonUser objectForKey:@"thumb"];
    NSDictionary *jsonLocation=[jsonUser objectForKey:@"lastLocation"];
    NSNumber *jsonLocationTime=[jsonUser objectForKey:@"lastLocationTime"];
    
    // Online flag
    NSNumber *isOnline  = [jsonUser objectForKey:@"online"];
    
    // Looking up user in cache
    User *user = [_objectCache objectForKey:userKey];
    if(user == nil) {
        // Building User bean
        user = [[User alloc] init];
        [user setHasOverviewData:NO];
        
        //Adding to cache
        [_objectCache setObject:user forKey:user.key];
    }
    
    // Creating CAL image
    CALImage *img = [imageService convertJsonImageToImage:jsonThumb];
    [user setKey:userKey];
    [user setPseudo:pseudo];
    if(img != nil) {
        [user setMainImage:img];
    }
    [user setIsOnline:[isOnline boolValue]];
    
    // Last location information
    if(jsonLocation != nil && (id)jsonLocation!=[NSNull null]) {
        Place *lastLocation = [self convertJsonPlaceToPlace:jsonLocation];
        [user setLastLocation:lastLocation];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:jsonLocationTime.longValue];
        [user setLastLocationDate:date];
    }
    return user;
}
-(User*)convertJsonOverviewUserToUser:(NSDictionary*)json  defaultUser:(User*)defaultUser {
    NSString *key     = [json objectForKey:@"key"];
    
    // Getting user
    User *user = [_objectCache objectForKey:key];
    if(user == nil) {
        if(defaultUser != nil) {
            user = defaultUser;
        } else {
            user = [[User alloc] init];
        }
    } else if(user != defaultUser) {
        NSLog(@"WARNING: Original user object has been replaced: %@ (cache may have been purged)",user.key );
        user = defaultUser;
    }
    
    // Extracting JSON data
    NSNumber *likeCount     = [json objectForKey:@"likes"];
    NSArray *jsonLikeUsers  = [json objectForKey:@"likeUsers"];
    NSNumber *placeLikeCount= [json objectForKey:@"likedPlacesCount"];
    NSArray *jsonLikedPlaces= [json objectForKey:@"likedPlaces"];
    NSNumber *checkinPlacesCount= [json objectForKey:@"checkedInPlacesCount"];
    NSArray *jsonCheckedInPlaces= [json objectForKey:@"checkedInPlaces"];
    NSNumber *liked         = [json objectForKey:@"liked"];
    NSArray *jsonEvents     = [json objectForKey:@"events"];
    NSNumber *distance         = [json objectForKey:@"rawDistanceMeters"];
    
    // Getting unread message count
    NSNumber *unreadMsgCount = [json objectForKey:@"unreadMsgCount"];
//    NSNumber *unreadNetworkCount=[json objectForKey:@"unreadNetworkNotificationsCount"];
    [_messageService setUnreadMessageCount:[unreadMsgCount intValue]];
//    [_messageService setUnreadNetworkCount:[unreadNetworkCount intValue]];
    
    // Preparing thumbs list to download
    NSMutableArray *thumbsToDownload = [[NSMutableArray alloc] initWithCapacity:jsonLikeUsers.count+jsonLikedPlaces.count];
    
    // Injecting liked users into user
    NSLog(@"Fill user likeCount = %d, placesCount= %d",[likeCount intValue],[placeLikeCount intValue]);
    [user setLikeCount:[likeCount integerValue]];
    [user.likers removeAllObjects];
    for(NSDictionary *jsonUser in jsonLikeUsers) {
        // Building User bean (liked user) from JSON
        User *likedUser = [self convertJsonUserToUser:jsonUser];
        
        // Adding this user to our thumbs download list
        [thumbsToDownload addObject:likedUser];
        
        // Adding this liked user
        [user.likers addObject:likedUser];
    }
    
    // Injecting liked places into user
    [user setLikedPlacesCount:[placeLikeCount integerValue]];
    [user.likedPlaces removeAllObjects];
    for(NSDictionary *jsonPlace in jsonLikedPlaces) {
        // Building the place bean from JSON
        Place *place = [self convertJsonPlaceToPlace:jsonPlace];
        
        // Adding this place to our thumbs download list
        [thumbsToDownload addObject:place];
        
        // Adding this liked place
        [user.likedPlaces addObject:place];
    }
    
    // Injecting checked places into user
    [user setCheckedInPlacesCount:[checkinPlacesCount integerValue]];
    [user.checkedInPlaces removeAllObjects];
    for(NSDictionary *jsonPlace in jsonCheckedInPlaces) {
        // Building the place bean from JSON
        Place *place = [self convertJsonPlaceToPlace:jsonPlace];
        
        // Adding this place to our thumbs download list
        [thumbsToDownload addObject:place];
        
        // Adding this checkin place
        [user.checkedInPlaces addObject:place];
    }
    
    // Injecting events
    [user.events removeAllObjects];
    for(NSDictionary *jsonEvent in jsonEvents) {
        Event *event = [self convertJsonLightEventToEvent:jsonEvent defaultEvent:nil];
        [user.events addObject:event];
    }
    
    // Setting liked flag
    user.isLiked = [liked boolValue];
    
    // Flagging user as having its overview data
    [user setHasOverviewData:YES];
    
    // Setting distance
    [user setRawDistanceMeters:distance.doubleValue];
    
    return user;
}
- (NSArray *)convertJsonUsersToUsers:(NSArray *)jsonUsers {
    NSMutableArray *users = [[NSMutableArray alloc] initWithCapacity:jsonUsers.count];
    for(NSDictionary *jsonUser in jsonUsers) {
        User *user = [self convertJsonUserToUser:jsonUser];
        //        if(activity.user !=nil) {
        [users addObject:user];
        //        }
    }
    return users;
}
- (void)fillUser:(User*)user fromJson:(NSDictionary*)jsonLoginInfo {
    NSString *pseudo    =[jsonLoginInfo objectForKey:@"pseudo"];
    NSString *key       =[jsonLoginInfo objectForKey:@"key"];
    NSString *city       =[jsonLoginInfo objectForKey:@"city"];
    NSNumber *heightInCm=[jsonLoginInfo objectForKey:@"heightInCm"];
    NSNumber *weightInKg=[jsonLoginInfo objectForKey:@"weightInKg"];
    NSNumber *birthdate =[jsonLoginInfo objectForKey:@"birthDate"];
    long birthDateTime = [birthdate longValue];
    NSArray *descs      =[jsonLoginInfo objectForKey:@"descriptions"];
    NSArray *medias     =[jsonLoginInfo objectForKey:@"medias"];
    NSArray *tags       =[jsonLoginInfo objectForKey:@"tags"];
    NSNumber *isOnline  =[jsonLoginInfo objectForKey:@"online"];
    NSNumber *unreadMsgCount=[jsonLoginInfo objectForKey:@"unreadMsgCount"];
//    NSNumber *unreadNetworkCount=[jsonLoginInfo objectForKey:@"unreadNetworkNotificationsCount"];
    int unreadCount = (int)[unreadMsgCount integerValue];
    
    [[TogaytherService getMessageService] setUnreadMessageCount:unreadCount];
//    [[TogaytherService getMessageService] setUnreadNetworkCount:unreadNetworkCount.intValue];
    
    user.pseudo     = pseudo;
    user.key        = key;
    
    user.cityName   = city;
    user.heightInCm = [heightInCm integerValue];
    user.weightInKg = [weightInKg integerValue];
    user.birthDate  = [[NSDate alloc] initWithTimeIntervalSince1970:birthDateTime];
    user.isOnline   = [isOnline boolValue];
    
    // Processing descriptions
    if(![user.key isEqualToString:_userService.getCurrentUser.key] || user.descriptions.count==0) {
        [user.descriptions removeAllObjects];
        for(NSDictionary *desc in descs) {
            NSString *lang = [desc objectForKey:@"language"];
            NSString *text = [desc objectForKey:@"description"];
            NSString *key  = [desc objectForKey:@"key"];
            [user addDescriptionWithKey:key description:text language:lang];
        }
        NSString *miniDesc = [self getMiniDesc:user.descriptions];
        [user setMiniDesc:miniDesc];
    }
    // Registering current user medias
    NSMutableDictionary *mediaMap = [[NSMutableDictionary alloc] initWithCapacity:user.otherImages.count+1];
    CALImage *mainImage = user.mainImage;
    if(mainImage != nil && mainImage.key!=nil) {
        [mediaMap setObject:user.mainImage forKey:user.mainImage.key];
    }
    for(CALImage *image in user.otherImages) {
        if(image != nil) {
            [mediaMap setObject:image forKey:image.key];
        }
    }
    // Processing medias
    BOOL isFirst = YES;
    for(NSDictionary *media in medias) {
        NSString *imgUrl    = [media objectForKey:@"url"];
        NSString *thumbUrl  = [media objectForKey:@"thumbUrl"];
        NSString *key       = [media objectForKey:@"key"];
        
        CALImage *image = [mediaMap objectForKey:key];
        if(image == nil) {
            image = [[CALImage alloc]initWithKey:key url:imgUrl thumbUrl:thumbUrl];
            if(isFirst) {
                [user setMainImage:image];
            } else {
                [user.otherImages addObject:image];
            }
        }
        isFirst = NO;
    }
    
    // Processing tags
    [user.tags removeAllObjects];
    for(NSString *tag in tags)  {
        [user.tags addObject:tag];
    }
    
    // Extracting last location
    NSDictionary *lastPlace = [jsonLoginInfo objectForKey:@"lastLocation"];
    NSNumber *lastPlaceTime = [jsonLoginInfo objectForKey:@"lastLocationTime"];
    if(lastPlace != nil && lastPlace!=(id)[NSNull null]) {
        Place *lastLocation = [self convertJsonPlaceToPlace:lastPlace];
        [user setLastLocation:lastLocation];
        long pTime = [lastPlaceTime longValue];
        NSDate* lastLocDate = [[NSDate alloc] initWithTimeIntervalSince1970:pTime];
        [user setLastLocationDate:lastLocDate];
    }
    [_objectCache setObject:user forKey:user.key];
    
    
    // Extracting private network info
    CurrentUser *currentUser = [_userService getCurrentUser];
    if([user.key isEqualToString:currentUser.key]) {
        [self fillPrivateNetworkInfo:jsonLoginInfo inUser:currentUser];
    }
}
-(void)fillPrivateNetworkInfo:(NSDictionary*)privateNetworkContainer inUser:(CurrentUser*)currentUser {
    NSArray *jsonNetworkPendingApprovals = [privateNetworkContainer objectForKey:@"pendingApprovals"];
    NSArray *jsonNetworkPendingRequests = [privateNetworkContainer objectForKey:@"pendingRequests"];
    NSArray *jsonNetworkUsers = [privateNetworkContainer objectForKey:@"networkUsers"];
    
    NSArray *networkPendingApprovals = [self convertJsonUsersToUsers:jsonNetworkPendingApprovals];
    NSArray *networkPendingRequests = [self convertJsonUsersToUsers:jsonNetworkPendingRequests];
    NSArray *networkUsers = [self convertJsonUsersToUsers:jsonNetworkUsers];
    currentUser.networkPendingApprovals = networkPendingApprovals;
    currentUser.networkPendingRequests = networkPendingRequests;
    currentUser.networkUsers = networkUsers;
    
    // Counting current friend's checkins
    NSInteger checkinsCount = 0;
    for(User *networkUser in networkUsers) {
        if(networkUser.lastLocation!=nil) {
            checkinsCount++;
        }
    }
    
    [[TogaytherService getMessageService] setUnreadNetworkCount:networkPendingApprovals.count + checkinsCount];
}
-(NSString*)getMiniDesc:(NSArray*)descriptions {
    NSMutableDictionary *descLangMap = [[NSMutableDictionary alloc] init];
    for(Description *desc in descriptions) {
        // Retrieving existing entry
        NSMutableString *buffer = [descLangMap objectForKey:desc.languageCode];
        // Initializing a buffer
        if(buffer == nil) {
            buffer = [[NSMutableString alloc] init];
            [descLangMap setObject:buffer forKey:desc.languageCode];
        } else {
            [buffer appendString:@"\n"];
        }
        // Appending the description
        [buffer appendString:desc.descriptionText];
    }
    // Now selecting the description that matches our current language
    
    // Getting current language
    NSString *currentLanguage = [[[NSLocale preferredLanguages] objectAtIndex:0] substringToIndex:2];
    NSMutableString *miniDesc = [descLangMap objectForKey:currentLanguage];
    // If no entry, we try english
    if(miniDesc == nil) {
        miniDesc = [descLangMap objectForKey:@"en"];
        // If no english we take the first one
        if(miniDesc == nil && descLangMap.count>0) {
            miniDesc = [[descLangMap allValues] objectAtIndex:0];
        }
    }
    return miniDesc;
}
- (NSString*)specialCacheEventKey:(Special*)special {
    return [@"EVNT" stringByAppendingString:special.key];
}
- (CALObject *)objectForKey:(NSString *)key {
    return [_objectCache objectForKey:key];
}
@end
