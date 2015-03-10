//
//  ItemsThumbPreviewProvider.m
//  togayther
//
//  Created by Christophe Fondacci on 23/01/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import "ItemsThumbPreviewProvider.h"
#import "TogaytherService.h"
#import "Event.h"
#import "DisplayHelper.h"

@implementation ItemsThumbPreviewProvider {
    CALObject *_parent;
    NSMutableArray *_types;             // List of all sorted types
    NSMutableDictionary *_typedItems;   // Items hashed by types
    NSMutableDictionary *_itemsTypes;   // Items icons hashed by item key
    NSMutableDictionary *_typedLabels;
    NSMutableSet *_itemKeys;
    NSString *_segueId;
    NSString *_labelKey;
    NSString *_label;
    UIImage *_icon;
    
    int lastTappedThumb;
    BOOL isMoreTapped;
    ImageService *imageService;
    UIService *_uiService;
}

- (id)initWithParent:(CALObject *)parent items:(NSArray*)items moreSegueId:(NSString*)segueId labelKey:(NSString*)labelKey icon:(UIImage*)icon
{
    self = [self initWithParent:parent items:items forType:PMLThumbsOther];
        _segueId = segueId;
        _labelKey = labelKey;
        _icon = icon;


    return self;
}

- (instancetype)initWithParent:(CALObject *)place items:(NSArray *)items forType:(PMLThumbType)type
{
    self = [super init];
    if (self) {
        imageService = [TogaytherService imageService];
        _uiService = [TogaytherService uiService];
        _parent = place;
        _types = [[NSMutableArray alloc] init];
        _typedItems = [[NSMutableDictionary alloc ] init ];
        _itemsTypes = [[NSMutableDictionary alloc] init];
        _itemKeys = [[NSMutableSet alloc] init];
        [self initLabels];
        [self addItems:items forType:type];
    }
    return self;
}

-(void)initLabels {
    _typedLabels = [[NSMutableDictionary alloc] init];
    [_typedLabels setObject: @"thumbView.section.like" forKey:[NSNumber numberWithInt:PMLThumbsLike]];
    [_typedLabels setObject: @"thumbView.section.checkin" forKey:[NSNumber numberWithInt:PMLThumbsCheckin]];
    [_typedLabels setObject: @"thumbView.section.user.likeUser" forKey:[NSNumber numberWithInt:PMLThumbsUserLike]];
    [_typedLabels setObject: @"thumbView.section.user.likeUser" forKey:[NSNumber numberWithInt:PMLThumbsUsersInEvent]];
}
-(NSMutableArray*)internalItemsForType:(PMLThumbType)type {
    NSNumber *t = [NSNumber numberWithInt:type];
    NSMutableArray *items = [_typedItems objectForKey:t];
    if(items == nil) {
        items = [[NSMutableArray alloc] init];
        [_types addObject:t];
        [_typedItems setObject:items forKey:t];
    }
    return items;
}
- (void)addItems:(NSArray *)items forType:(PMLThumbType)type {
    if(items == nil || items.count==0) {
        return;
    }
    NSMutableArray *typedItems = [self internalItemsForType:type];
    for(CALObject *item in items) {
        if(![_itemKeys containsObject:item.key]) {
            [_itemKeys addObject:item.key];
            UIImage *icon;
            switch(type) {
                case PMLThumbsCheckin:
                    icon = [UIImage imageNamed:@"snpDecoratorCheckin"];
                    break;
                case PMLThumbsLike:
                    icon = [UIImage imageNamed:@"snpDecoratorLike"];
                    break;
                default:
                    icon = nil;
            }
            if(icon != nil) {
                [_itemsTypes setObject:icon forKey:item.key];
            }
        }
        if(![typedItems containsObject:item]) {
            [typedItems addObject:item];
        }
    }
}

- (CALImage *)imageAtIndex:(NSInteger)index forType:(PMLThumbType)type {
    NSArray *typedItems = [self itemsForType:type ];
    if(typedItems.count>index) {
        CALObject *item = [typedItems objectAtIndex:index];
        CALImage *image = [[TogaytherService imageService] imageOrPlaceholderFor:item allowAdditions:NO];
        return image;
    } else {
        return nil;
    }
}
- (CALObject *)objectAtIndex:(NSInteger)index forType:(PMLThumbType)type {
    NSArray *typedItems = [self itemsForType:type ];
    if(typedItems.count>index) {
        CALObject *item = [typedItems objectAtIndex:index];
        return item;
    }
    return nil;
}
- (UIImage*)topLeftDecoratorForIndex:(NSInteger)index forType:(PMLThumbType)type{
    NSArray *typedItems = [self itemsForType:type ];
    if(typedItems.count>index) {
        CALObject *item = [typedItems objectAtIndex:index];
        if([item isKindOfClass:[User class]] ) {
            User *user = (User*)item;
            // Getting the online / offline state
            BOOL offline = user == nil || !user.isOnline;
            UIImage *imgDecorator = [imageService getOnlineImage:YES];
            return offline ? nil : imgDecorator;
        }
    }
    return nil;
}
-(UIImage *)bottomRightDecoratorForIndex:(NSInteger)index forType:(PMLThumbType)type{
    NSArray *typedItems = [self itemsForType:type ];
    CALObject *item = [typedItems objectAtIndex:index];
    UIImage *icon = [_itemsTypes objectForKey:item.key];
    return icon;
}
- (NSArray *)itemsForType:(PMLThumbType)thumbType {
    NSNumber *t = [NSNumber numberWithInt:thumbType];
    NSMutableArray *items = [_typedItems objectForKey:t];
    return items;
}
- (NSString *)titleAtIndex:(NSInteger)index forType:(PMLThumbType)type {
    NSArray *typedItems = [self itemsForType:type ];
    CALObject *obj = [typedItems objectAtIndex:index];
    NSString *label = [DisplayHelper getName:obj];
    return label;
}

- (NSString *)getPreviewSegueIdForThumb:(int)thumbIndex {
    return @"detail";
}
- (NSString *)getMoreSegueId {
    isMoreTapped = YES;
    lastTappedThumb = -1;
    return _segueId;
}

- (NSString *)getLabel {
    if(_label != nil) {
        return _label;
    } else if(_labelKey != nil) {
        return NSLocalizedString(_labelKey, @"Key of message to display");
    }
    return nil;
}
- (UIImage *)getIcon {
    return _icon;
}
-(BOOL)shouldShow {
    return _typedItems.count>0;
}
- (UIColor *)colorFor:(NSInteger)index forType:(PMLThumbType)type{
    NSArray *typedItems = [self itemsForType:type ];
    CALObject *item = [typedItems objectAtIndex:index];
    UIColor *color = [UIColor whiteColor];
    if([item isKindOfClass:[User class]]) {
        color = [_uiService colorForObject:item];
    }
    return color;
}
- (NSArray *)thumbTypes {
    return _types;
}
-(void)setIntroLabelCode:(NSString *)label forType:(PMLThumbType)thumbType {
    [_typedLabels setObject:label forKey:[NSNumber numberWithInt:thumbType]];
}

- (PMLThumbType)thumbTypeAtIndex:(NSInteger)index {
    NSNumber *number = [_types objectAtIndex:index];
    return (PMLThumbType)number.intValue;
}

- (NSString *)labelForType:(PMLThumbType)type {
    NSString *template = [_typedLabels objectForKey:[NSNumber numberWithInt:type]];
    if(template != nil) {
        return [_uiService localizedString:template forCount:[[self itemsForType:type] count]];
    } else {
        return nil;
    }
}
- (UIImage *)imageForType:(PMLThumbType)type {
    switch (type) {
        case PMLThumbsLike:
            return [UIImage imageNamed:@"snpIconLikeWhite"];
            break;
        case PMLThumbsUserLike:
            return [UIImage imageNamed:@"snpIconEvent"];
        case PMLThumbsCheckin:
            return [UIImage imageNamed:@"snpIconMarker"];
        default:
            break;
    }
    return nil;
}
@end
