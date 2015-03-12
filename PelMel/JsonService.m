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
    NSCache *cacheService;

    MessageService *_messageService;
    UserService *_userService;
}

@synthesize imageService = imageService;

- (instancetype)init
{
    self = [super init];
    if (self) {
        cacheService = [[NSCache alloc] init];
        _messageService = [TogaytherService getMessageService];
        _userService = TogaytherService.userService;
    }
    return self;
}
-(Place*)convertJsonPlaceToPlace:(NSDictionary*)jsonPlace {
    
    NSString *name = [jsonPlace objectForKey:@"name"];
    NSString *key = [jsonPlace objectForKey:@"key"];
    NSDictionary *thumb = [jsonPlace objectForKey:@"thumb"];
    
    // Looking up in cache
    if(key != nil) {
        Place *place = [cacheService objectForKey:key];
        if(place == nil) {
            place = [[Place alloc] init:name];
            [place setKey:key];
            CALImage *img = [imageService convertJsonImageToImage:thumb];
            [place setMainImage:img];
            [cacheService setObject:place forKey:key];
        }
        
        return place;
    } else {
        return nil;
    }
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
    Place *data =[cacheService objectForKey:itemKey];
    if(data == nil) {
        data = [[Place alloc] initFull:name distance:distance miniDesc:description];
        // Caching result
        [cacheService setObject:data forKey:itemKey];
    }
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
    
    // Parsing specials
    NSMutableArray *placeSpecials = [[NSMutableArray alloc] initWithCapacity:specials.count];
    for(NSDictionary *jsonSpecial in specials) {
        // Extracting from JSON
        NSString *name      = [jsonSpecial objectForKey:@"name"];
        NSString *desc      = [jsonSpecial objectForKey:@"description"];
        NSNumber *nextStart = [jsonSpecial objectForKey:@"nextStart"];
        NSNumber *nextEnd   = [jsonSpecial objectForKey:@"nextEnd"];
        NSString *type      = [jsonSpecial objectForKey:@"type"];
        
        NSDate *startDate   = [[NSDate alloc] initWithTimeIntervalSince1970:[nextStart longValue]];
        NSDate *endDate     = [[NSDate alloc] initWithTimeIntervalSince1970:[nextEnd longValue]];
        
        // Creating and filling bean
        Special *special = [[Special alloc] init];
        special.name        = name;
        special.descriptionText = desc;
        special.nextStart   = startDate;
        special.nextEnd     = endDate;
        special.type        = type;
        
        // Adding to our list
        [placeSpecials addObject:special];
    }
    // Injecting into current place
    data.specials = placeSpecials;
    
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
    
    // Getting unread message count
    NSNumber *unreadMsgCount = [json objectForKey:@"unreadMsgCount"];
    [_messageService setUnreadMessageCount:[unreadMsgCount intValue]];
    
    // Getting place
    Place *place = [cacheService objectForKey:placeKey];
    if(place == nil) {
        if(defaultPlace != nil) {
            place = defaultPlace;
        } else {
            place = [[Place alloc] init];
        }
    } else if(place != defaultPlace) {
        NSLog(@"WARNING: Original place object has been replaced: %@ (cache may have been purged)",place.key );
        place = defaultPlace;
    }
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
    // TODO: Provide the total count from server
    place.inUserCount = jsonInUsers.count;
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
        PMLCalendar *calendar = [self convertJsonCalendarToCalendar:jsonHour defaultCalendar:nil];
        calendar.place = place;
        [hours addObject:calendar];
    }
    [place setHours:hours];
    
    
    // Registering that this object has data
    [place setHasOverviewData:YES];
    
    // Refreshing cache
    [cacheService setObject:place forKey:place.key];
    return place;
}

-(PMLCalendar*)convertJsonCalendarToCalendar:(NSDictionary*)jsonHour defaultCalendar:(PMLCalendar*)defaultCalendar {
    NSString *key           = [jsonHour objectForKey:@"key"];
    NSString *hoursType     = [jsonHour objectForKey:@"type"];
    NSString *hoursName     = [jsonHour objectForKey:@"name"];
    
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
    
    PMLCalendar *calendar = [cacheService objectForKey:key];
    if(calendar == nil) {
        if(defaultCalendar) {
            calendar = defaultCalendar;
        } else {
            calendar = [[PMLCalendar alloc] init];
        }
        [cacheService setObject:calendar forKey:key];
    }

    [calendar setKey:key];
    [calendar setName:hoursName];
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
    [calendar setCalendarType:hoursType];
    if(recurrency != (NSNumber*)[NSNull null]){
        [calendar setRecurrency:recurrency];
    } else {
        [calendar setRecurrency:nil];
    }
    return calendar;
}
-(Activity *)convertJsonActivityToActivity:(NSDictionary *)jsonActivity {
    NSDictionary *jsonUser = [jsonActivity objectForKey:@"user"];
    NSDictionary *jsonActivityPlace = [jsonActivity objectForKey:@"activityPlace"];
    NSDictionary *jsonActivityUser = [jsonActivity objectForKey:@"activityUser"];
    NSNumber     *jsonDate = [jsonActivity objectForKey:@"activityDate"];
    NSString *message = [jsonActivity objectForKey:@"message"];
    
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
    }
    NSDate *activityDate;
    if(jsonDate != (id)[NSNull null]) {
        activityDate = [NSDate dateWithTimeIntervalSince1970:jsonDate.longValue];
    }
//    if(jsonUser != nil) {
        // Building activity bean
        Activity *activity = [[Activity alloc] init];
        activity.user = user;
    activity.activityObject = activityObject;
        activity.message = [message gtm_stringByUnescapingFromHTML];
        activity.activityDate = activityDate;
    
//    }
    return activity;
}
- (NSArray *)convertJsonActivitiesToActivities:(NSArray *)jsonActivities {
    NSMutableArray *activities = [[NSMutableArray alloc] initWithCapacity:jsonActivities.count];
    for(NSDictionary *jsonActivity in jsonActivities) {
        Activity *activity = [self convertJsonActivityToActivity:jsonActivity];
//        if(activity.user !=nil) {
            [activities addObject:activity];
//        }
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
-(Event*)convertJsonEventToEvent:(NSDictionary*)obj defaultEvent:(Event*)defaultEvent {
    NSString *itemKey = [obj objectForKey:@"key"];
    // Building JSON event
    Event *event = [cacheService objectForKey:itemKey];
    if(event == nil) {
        event = defaultEvent == nil ? [[Event alloc] init] : defaultEvent;
        [cacheService setObject:event forKey:itemKey];
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

    
    
    // Building image array
    BOOL isFirst = YES;
    for(NSDictionary *jsonOtherImage in media) {
        CALImage *image = [imageService convertJsonImageToImage:jsonOtherImage];
        if(isFirst) {
            [event setMainImage:image];
        } else {
            [event.otherImages addObject:image];
        }
        isFirst = NO;
    }
    
    // Building the place data bean
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
    
    NSString *description = [obj objectForKey:@"description"];
    [event setMiniDesc:description];
    
    // Likes management

    NSArray *jsonLikeUsers  = [obj objectForKey:@"likeUsers"];
    NSNumber *liked         = [obj objectForKey:@"liked"];
    [event setIsLiked:[liked boolValue]];
    NSNumber *likeCount     = [obj objectForKey:@"likes"];
    [event setLikeCount:MAX([likeCount integerValue],[participants integerValue])];
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
    
    // Online flag
    NSNumber *isOnline  = [jsonUser objectForKey:@"online"];
    
    // Looking up user in cache
    User *user = [cacheService objectForKey:userKey];
    if(user == nil) {
        // Creating CAL image
        CALImage *img = [imageService convertJsonImageToImage:jsonThumb];
        
        // Building User bean
        user = [[User alloc] init];
        [user setKey:userKey];
        [user setPseudo:pseudo];
        [user setMainImage:img];
        [user setHasOverviewData:NO];
        
        //Adding to cache
        [cacheService setObject:user forKey:user.key];
    }
    [user setIsOnline:[isOnline boolValue]];
    return user;
}
-(User*)convertJsonOverviewUserToUser:(NSDictionary*)json  defaultUser:(User*)defaultUser {
    NSString *key     = [json objectForKey:@"key"];
    
    // Getting user
    User *user = [cacheService objectForKey:key];
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
    
    // Getting unread message count
    NSNumber *unreadMsgCount = [json objectForKey:@"unreadMsgCount"];
    [_messageService setUnreadMessageCount:[unreadMsgCount intValue]];
    
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
        
        // Adding this liked place
        [user.checkedInPlaces addObject:place];
    }
    
    // Setting liked flag
    user.isLiked = [liked boolValue];
    
    // Flagging user as having its overview data
    [user setHasOverviewData:YES];
    
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
    int unreadCount = (int)[unreadMsgCount integerValue];
    
    [[TogaytherService getMessageService] setUnreadMessageCount:unreadCount];
    
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
    [cacheService setObject:user forKey:user.key];
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
@end
